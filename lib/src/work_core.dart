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
abstract class Work<D, T extends WorkData<D>> extends WorkLifeCycle<D, T> {
  /// 日志标签
  String? _logTag;

  /// 日志标签
  String get _tag => _logTag ?? _createTag();

  /// 创建日志标签
  String _createTag() {
    return _logTag = '$runtimeType@${hashCode.toRadixString(16)}';
  }

  @override
  WorkFuture<T> start({
    int retry = 0,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) {
    log(_tag, 'work start');

    final data = onCreateWorkData();

    final future =
        WorkFuture<T>._(_tag, () => data.options?.cancelToken.cancel());

    _onDo(
      data: data,
      retry: retry,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    ).then(future._complete);

    return future;
  }

  /// 实际执行任务
  ///
  /// [future]任务完成器
  Future<T> _onDo({
    required T data,
    required int retry,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) async {
    try {
      await _onStartWork(data);

      if (!data.fromCache) {
        data._options =
            await _onCreateOptions(onSendProgress, onReceiveProgress);
        await _onDoWork(retry, data);

        log(_tag, 'onSuccessful');
        final successful = onSuccessful(data);
        if (successful is Future<void>) {
          await successful;
        }
      }
    } catch (e) {
      data._success = false;
      if (e is WorkError) {
        data
          .._errorType = e.type
          .._message = e.message;
      } else {
        data._errorType = WorkErrorType.other;
      }

      if (data.errorType == WorkErrorType.cancel) {
        log(_tag, 'onCanceled');
        final canceled = onCanceled(data);
        if (canceled is Future<void>) {
          await canceled;
        }
      } else {
        log(_tag, 'onFailed');
        final failed = onFailed(data);
        if (failed is Future<void>) {
          await failed;
        }
      }
    } finally {
      log(_tag, 'onFinished');
      final finished = onFinished(data);
      if (finished is Future<void>) {
        await finished;
      }
    }

    log(_tag, 'work end');

    return data;
  }

  /// 任务启动前置方法
  Future<void> _onStartWork(T data) async {
    final check = onCheckParams();
    final checkResult = (check is Future<bool>) ? await check : check;
    if (!checkResult) {
      log(_tag, 'onParamsError');
      throw WorkError._(_tag, WorkErrorType.params, onParamsError());
    }

    log(_tag, 'onStarted');
    final willRequest = onStarted();
    if (willRequest is Future<D?>) {
      data._result = await willRequest;
    } else {
      data._result = willRequest;
    }

    if (data._result != null) {
      data._success = true;
      data._fromCache = true;
      log(_tag, 'onFromCacheMessage');
      data._message = onFromCacheMessage();
    }
  }

  /// 构建请求选项参数
  Future<WorkRequestOptions> _onCreateOptions(
      OnProgress? onSendProgress, OnProgress? onReceiveProgress) async {
    Map<String, dynamic>? data;
    Map<String, dynamic>? params;

    var fillParams = onPreFillParams();
    if (fillParams is Future<Map<String, dynamic>?>) {
      data = await fillParams;
    } else {
      data = fillParams;
    }

    fillParams = onFillParams();
    if (fillParams is Future<Map<String, dynamic>?>) {
      params = await fillParams;
    } else {
      params = fillParams;
    }

    if (params != null) {
      data = (data?..addAll(params)) ?? params;
    }

    final postFillParams = onPostFillParams(data);

    final options = WorkRequestOptions()
      ..onSendProgress = onSendProgress
      ..onReceiveProgress = onReceiveProgress
      ..method = onHttpMethod()
      ..configKey = onConfigKey()
      ..contentType = onContentType()
      ..responseType = onResponseType()
      ..url = onUrl();

    if (postFillParams is Future<dynamic>) {
      options.params = await postFillParams ?? data;
    } else {
      options.params = postFillParams ?? data;
    }

    final headers = onHeaders();
    if (headers is Future<Map<String, dynamic>?>) {
      options.headers = await headers;
    } else {
      options.headers = headers;
    }

    final configOptions = onConfigOptions(options);

    if (configOptions is Future<void>) {
      await configOptions;
    }

    return options;
  }

  /// 核心任务执行
  ///
  /// 此处为真正启动http请求的方法
  Future<void> _onDoWork(int retry, T data) async {
    final request = onWorkRequest(data.options!);

    data._response =
        await _onCall(retry, data, await request(_tag, data.options!));

    await _onParseResponse(data);
  }

  /// 执行网络请求
  Future<HttpResponse> _onCall(int retry, T data, HttpCall call) async {
    if (retry < 0) {
      retry = 0;
    }

    log(_tag, 'original', data.options);

    HttpResponse httpResponse;
    var i = 0;

    do {
      if (i > 0) {
        log(_tag, 'retry $i');
      }

      try {
        final startTime = Timeline.now;
        final response = await call();
        httpResponse = response.toHttpResponse();
        log(_tag, 'request use ${Timeline.now - startTime}μs');
        log(_tag, 'final url:', _FinalRequestOptions(response.requestOptions));
        log(_tag, 'http', httpResponse);
        break;
      } on DioError catch (e) {
        log(_tag, 'http error', e.type);

        if (e.type == DioErrorType.cancel) {
          throw WorkError._(_tag, WorkErrorType.cancel);
        }

        if (i < retry) {
          i++;
          continue;
        }

        final errorType = e.type.toWorkErrorType();
        data
          .._response = e.response?.toHttpResponse()
          .._errorType = errorType;

        log(_tag, 'final url:', _FinalRequestOptions(e.requestOptions));
        log(_tag, 'http', data.response);

        if (e.type == DioErrorType.response) {
          // 网络请求失败
          log(_tag, 'onNetworkRequestFailed');
          throw WorkError._(_tag, errorType, onNetworkRequestFailed(data));
        } else {
          // 网络连接失败
          log(_tag, 'onNetworkError');
          throw WorkError._(_tag, errorType, onNetworkError(data));
        }
      } catch (e) {
        if (e is WorkError) {
          rethrow;
        }

        log(_tag, 'http other error', e);
        log(_tag, 'onParamsError');
        throw WorkError._(_tag, WorkErrorType.params, onParamsError());
      }
    } while (true);

    return httpResponse;
  }

  /// 解析响应数据
  Future<void> _onParseResponse(T data) async {
    try {
      // 提取服务执行结果
      log(_tag, 'onRequestResult');
      data._success = onRequestResult(data);

      if (data.success) {
        // 服务请求成功回调
        log(_tag, 'onRequestSuccessful');
        final responseSuccessful = onRequestSuccessful(data);
        if (responseSuccessful is Future<D?>) {
          data._result = await responseSuccessful;
        } else {
          data._result = responseSuccessful;
        }

        // 提取服务返回的消息
        log(_tag, 'onRequestSuccessMessage');
        data._message = onRequestSuccessfulMessage(data);
      } else {
        // 服务请求失败回调
        log(_tag, 'onRequestFailed');
        final requestFailed = onRequestFailed(data);
        if (requestFailed is Future<D?>) {
          data._result = await requestFailed;
        } else {
          data._result = requestFailed;
        }

        // 提取服务返回的消息
        log(_tag, 'onRequestFailedMessage');
        throw WorkError._(
            _tag, WorkErrorType.task, onRequestFailedMessage(data));
      }
    } catch (e) {
      // 解析失败
      log(_tag, 'onParseFailed');
      throw WorkError._(_tag, WorkErrorType.parse, onParseFailed(data));
    }
  }
}
