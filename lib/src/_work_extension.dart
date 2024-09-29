// Created by 超悟空 on 2021/5/7.

part of 'work_core.dart';

/// [Work]执行流程扩展，提供了任务执行能力
extension WorkExecuteExtension<D> on Work<D> {
  /// [Work.start]的内部实现
  WorkFuture<D> _start({
    int retry = 0,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) {
    /// 日志标签
    final tag = '$runtimeType@${hashCode.toRadixString(16)}';

    log(tag, 'work start');

    void Function()? onCancel;

    final future = WorkFuture<D>._(tag, () => onCancel?.call());

    Future<void> onDo() async {
      int restart = 0;
      dynamic extra;
      WorkData<D> data;
      do {
        data = WorkData<D>(onWorkConfig());
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
      } while (restart++ < onMaxRestart(data));

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
    required WorkData<D> data,
    required int retry,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) async {
    bool restart = false;

    try {
      await _onStartWork(tag, data);

      if (!data.fromCache) {
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
      if (e is WorkException) {
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
  Future<void> _onStartWork(String tag, WorkData<D> data) async {
    final check = onCheckParams(data);
    final checkResult = (check is Future<bool>) ? await check : check;
    if (!checkResult) {
      log(tag, 'onParamsError');
      throw WorkException._(tag, WorkErrorType.params, onParamsError(data));
    }

    log(tag, 'onStarted');
    final willStarted = onStarted(data);
    if (willStarted is Future<void>) {
      await willStarted;
    }

    log(tag, 'onHitCache');
    final willHitCache = onHitCache(data);
    if (willHitCache is Future<bool>) {
      if (!await willHitCache) {
        return;
      }
    } else if (!willHitCache) {
      return;
    }

    log(tag, 'hitCache success');

    data._success = true;
    data._fromCache = true;

    log(tag, 'onFromCache');
    final willCache = onFromCache(data);
    if (willCache is Future<D?>) {
      data._result = await willCache;
    } else {
      data._result = willCache;
    }

    log(tag, 'onFromCacheMessage');
    data._message = onFromCacheMessage(data);
  }

  /// 构建请求选项参数
  Future<void> _onCreateOptions(WorkData<D> data, OnProgress? onSendProgress,
      OnProgress? onReceiveProgress) async {
    final options = data._options = WorkRequestOptions()
      ..onSendProgress = onSendProgress
      ..onReceiveProgress = onReceiveProgress
      ..url = onUrl(data)
      ..dioOptions.method = onHttpMethod(data).name
      ..dioOptions.contentType = onContentType(data)
      ..dioOptions.responseType = onResponseType(data);

    final headers = onHeaders(data);
    if (headers is Future<Map<String, dynamic>?>) {
      options.dioOptions.headers = await headers;
    } else {
      options.dioOptions.headers = headers;
    }

    final fillParams = onFillParams(data);
    if (fillParams is Future<dynamic>) {
      options.params = await fillParams;
    } else {
      options.params = fillParams;
    }

    final queryParams = onQueryParams(data);
    if (queryParams is Future<Map<String, dynamic>?>) {
      options.queryParams = await queryParams;
    } else {
      options.queryParams = queryParams;
    }

    final configOptions = onPostOptions(data);
    if (configOptions is Future<void>) {
      await configOptions;
    }
  }

  /// 核心任务执行
  ///
  /// 此处为真正启动http请求的方法
  Future<void> _onDoWork(String tag, int retry, WorkData<D> data) async {
    data._response = await _onCall(
      tag,
      retry,
      data,
      workRequest(tag, data.workConfig.dio, data.options!),
    );

    await _onParseResponse(tag, data);
  }

  /// 执行网络请求
  Future<HttpResponse> _onCall(
      String tag, int retry, WorkData<D> data, HttpCall call) async {
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
        log(tag, 'http', httpResponse);
        break;
      } on DioException catch (e) {
        log(tag, 'request use ${Timeline.now - startTime}μs');
        log(tag, 'http error', e.type);

        if (e.type == DioExceptionType.cancel) {
          throw WorkException._(tag, WorkErrorType.cancel);
        }

        if (i < retry) {
          i++;
          continue;
        }

        final errorType = e.type.toWorkErrorType();
        data
          .._response = e.response?.toHttpResponse()
          .._errorType = errorType;

        log(tag, 'http', _FinalRequestOptions(e.requestOptions, data.response));

        if (e.type == DioExceptionType.badResponse) {
          // 网络请求失败
          log(tag, 'onNetworkRequestFailed');
          throw WorkException._(
              tag, errorType, onNetworkRequestFailed(data), e);
        } else {
          // 网络连接失败
          log(tag, 'onNetworkError');
          throw WorkException._(tag, errorType, onNetworkError(data), e);
        }
      } on WorkException catch (_) {
        rethrow;
      } catch (e, stack) {
        log(tag, 'http other error');
        log(tag, 'onParamsError');
        throw WorkException._(
            tag, WorkErrorType.params, onParamsError(data), e, stack);
      }
    } while (true);

    return httpResponse;
  }

  /// 解析响应数据
  Future<void> _onParseResponse(String tag, WorkData<D> data) async {
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
        throw WorkException._(
            tag, WorkErrorType.task, onRequestFailedMessage(data));
      }
    } on WorkException catch (_) {
      rethrow;
    } catch (e, stack) {
      // 解析失败
      log(tag, 'onParseFailed');
      throw WorkException._(
          tag, WorkErrorType.parse, onParseFailed(data), e, stack);
    }
  }
}
