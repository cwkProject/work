// Created by 超悟空 on 2018/9/20.

import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '_print.dart';
import '_work_request.dart';
import 'work_config.dart';
import 'work_model.dart';

export 'dart:async';

part 'work_data.dart';
part 'work_life_cycle.dart';

/// 任务流程的基本模型
///
/// [D]为关联的接口结果数据类型，[T]为接口响应包装类型[WorkData]
@optionalTypeArgs
abstract class Work<D, T extends WorkData<D>> with WorkLifeCycle<D, T> {
  const Work();

  @override
  WorkFuture<D, T> start({
    int retry = 0,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) {
    /// 日志标签
    final tag = '$runtimeType@${hashCode.toRadixString(16)}';

    log(tag, 'work start');

    void Function()? onCancel;

    final future = WorkFuture<D, T>._(tag, () => onCancel?.call());

    Future<void> onDo() async {
      int restart = 0;
      dynamic extra;
      T data;
      do {
        data = onCreateWorkData();
        data._restartCount = restart;
        data.extra = extra;
        onCancel = () => data.options?.cancelToken.cancel();
        if (!await _onDo(
          tag: tag,
          data: data,
          retry: retry,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        )) {
          break;
        }
        extra = data.extra;
      } while (restart++ < onMaxRestart());

      future._complete(data);
    }

    onDo();

    return future;
  }

  /// 实际执行任务
  ///
  /// [future]任务完成器
  ///
  /// 返回值表示是否重新执行本次请求
  Future<bool> _onDo({
    required String tag,
    required T data,
    required int retry,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) async {
    bool restart = false;

    try {
      await _onStartWork(tag, data);

      if (!data.fromCache) {
        data._options =
            await _onCreateOptions(data, onSendProgress, onReceiveProgress);
        await _onDoWork(tag, retry, data);

        log(tag, 'onSuccessful');
        final successful = onSuccessful(data);
        if (successful is Future<void>) {
          await successful;
        }
      }
    } catch (e, stack) {
      data._success = false;

      dynamic error;
      if (e is WorkError) {
        data
          .._errorType = e.type
          .._message = e.message;
        error = e;
      } else {
        data._errorType = WorkErrorType.other;
        error = stack;
      }

      if (data.errorType == WorkErrorType.cancel) {
        log(tag, 'onCanceled');
        FutureOr<bool> canceled = onCanceled(data);
        if (canceled is Future<bool>) {
          canceled = await canceled;
        }

        if (canceled as bool) {
          restart = canceled;
        }
      } else {
        log(tag, 'onFailed', error);
        FutureOr<bool> failed = onFailed(data);
        if (failed is Future<void>) {
          failed = await failed;
        }
        if (failed as bool) {
          restart = failed;
        }
      }
    } finally {
      log(tag, 'onFinished');
      FutureOr<bool> finished = onFinished(data);
      if (finished is Future<void>) {
        finished = await finished;
      }
      if (finished as bool) {
        restart = finished;
      }
    }

    log(tag, 'work end');

    return restart;
  }

  /// 任务启动前置方法
  Future<void> _onStartWork(String tag, T data) async {
    final check = onCheckParams(data);
    final checkResult = (check is Future<bool>) ? await check : check;
    if (!checkResult) {
      log(tag, 'onParamsError');
      throw WorkError._(tag, WorkErrorType.params, onParamsError(data));
    }

    log(tag, 'onStarted');
    final willRequest = onStarted(data);
    if (willRequest is Future<D?>) {
      data._result = await willRequest;
    } else {
      data._result = willRequest;
    }

    if (data._result != null) {
      data._success = true;
      data._fromCache = true;
      log(tag, 'onFromCacheMessage');
      data._message = onFromCacheMessage(data);
    }
  }

  /// 构建请求选项参数
  Future<WorkRequestOptions> _onCreateOptions(
      T data, OnProgress? onSendProgress, OnProgress? onReceiveProgress) async {
    final options = WorkRequestOptions();
    Map<String, dynamic>? params;

    var futureParams = onPreFillParams();
    if (futureParams is Future<Map<String, dynamic>?>) {
      params = await futureParams;
    } else {
      params = futureParams;
    }

    futureParams = onFillParams();
    Map<String, dynamic>? fillParams;
    if (futureParams is Future<Map<String, dynamic>?>) {
      fillParams = await futureParams;
    } else {
      fillParams = futureParams;
    }

    if (fillParams != null) {
      params = (params?..addAll(fillParams)) ?? fillParams;
    }

    final postFillParams = onPostFillParams(data, params);

    if (postFillParams is Future<dynamic>) {
      options.params = await postFillParams ?? params;
    } else {
      options.params = postFillParams ?? params;
    }

    futureParams = onQueryParams();

    if (futureParams is Future<Map<String, dynamic>?>) {
      options.queryParams = await futureParams;
    } else {
      options.queryParams = futureParams;
    }

    futureParams = onPostQueryParams(data, options.queryParams);

    if (futureParams is Future<Map<String, dynamic>?>) {
      options.queryParams = await futureParams;
    } else {
      options.queryParams = futureParams;
    }

    options
      ..onSendProgress = onSendProgress
      ..onReceiveProgress = onReceiveProgress
      ..dioOptions.method = onHttpMethod().name
      ..configKey = onConfigKey()
      ..dioOptions.contentType = onContentType()
      ..dioOptions.responseType = onResponseType()
      ..url = onUrl();

    final headers = onHeaders();
    if (headers is Future<Map<String, dynamic>?>) {
      options.dioOptions.headers = await headers;
    } else {
      options.dioOptions.headers = headers;
    }

    final configOptions = onConfigOptions(data, options);

    if (configOptions is Future<void>) {
      await configOptions;
    }

    return options;
  }

  /// 核心任务执行
  ///
  /// 此处为真正启动http请求的方法
  Future<void> _onDoWork(String tag, int retry, T data) async {
    final request = onWorkRequest(data.options!);

    data._response =
        await _onCall(tag, retry, data, await request(tag, data.options!));

    await _onParseResponse(tag, data);
  }

  /// 执行网络请求
  Future<HttpResponse> _onCall(
      String tag, int retry, T data, HttpCall call) async {
    if (retry < 0) {
      retry = 0;
    }

    log(tag, 'original', data.options);

    HttpResponse httpResponse;
    var i = 0;

    do {
      if (i > 0) {
        log(tag, 'retry $i');
      }

      final startTime = Timeline.now;

      try {
        final response = await call();
        httpResponse = response.toHttpResponse();
        log(tag, 'request use ${Timeline.now - startTime}μs');
        log(tag, 'final url:', _FinalRequestOptions(response.requestOptions));
        log(tag, 'http', httpResponse);
        break;
      } on DioError catch (e) {
        log(tag, 'request use ${Timeline.now - startTime}μs');
        log(tag, 'http error', e.type);

        if (e.type == DioErrorType.cancel) {
          throw WorkError._(tag, WorkErrorType.cancel);
        }

        if (i < retry) {
          i++;
          continue;
        }

        final errorType = e.type.toWorkErrorType();
        data
          .._response = e.response?.toHttpResponse()
          .._errorType = errorType;

        log(tag, 'final url:', _FinalRequestOptions(e.requestOptions));
        log(tag, 'http', data.response);

        if (e.type == DioErrorType.badResponse ||
            e.type == DioErrorType.unknown) {
          // 网络请求失败
          log(tag, 'onNetworkRequestFailed');
          throw WorkError._(tag, errorType, onNetworkRequestFailed(data), e);
        } else {
          // 网络连接失败
          log(tag, 'onNetworkError');
          throw WorkError._(tag, errorType, onNetworkError(data), e);
        }
      } on WorkError catch (_) {
        rethrow;
      } catch (e, stack) {
        log(tag, 'http other error');
        log(tag, 'onParamsError');
        throw WorkError._(
            tag, WorkErrorType.params, onParamsError(data), e, stack);
      }
    } while (true);

    return httpResponse;
  }

  /// 解析响应数据
  Future<void> _onParseResponse(String tag, T data) async {
    try {
      // 提取服务执行结果
      log(tag, 'onRequestResult');
      data._success = onRequestResult(data);

      if (data.success) {
        // 服务请求成功回调
        log(tag, 'onRequestSuccessful');
        final responseSuccessful = onRequestSuccessful(data);
        if (responseSuccessful is Future<D?>) {
          data._result = await responseSuccessful;
        } else {
          data._result = responseSuccessful;
        }

        // 提取服务返回的消息
        log(tag, 'onRequestSuccessMessage');
        data._message = onRequestSuccessfulMessage(data);
      } else {
        // 服务请求失败回调
        log(tag, 'onRequestFailed');
        final requestFailed = onRequestFailed(data);
        if (requestFailed is Future<D?>) {
          data._result = await requestFailed;
        } else {
          data._result = requestFailed;
        }

        // 提取服务返回的消息
        log(tag, 'onRequestFailedMessage');
        throw WorkError._(
            tag, WorkErrorType.task, onRequestFailedMessage(data));
      }
    } on WorkError catch (_) {
      rethrow;
    } catch (e, stack) {
      // 解析失败
      log(tag, 'onParseFailed');
      throw WorkError._(
          tag, WorkErrorType.parse, onParseFailed(data), e, stack);
    }
  }
}
