// Created by 超悟空 on 2018/9/20.

import 'dart:async';

import 'package:meta/meta.dart';

import '_print.dart';
import 'work_model.dart';
import 'work_config.dart' show workConfigs, workConfig;
import 'package:pedantic/pedantic.dart';

part '_work_life_cycle.dart';
part '_work_data.dart';

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

  /// 启动任务
  ///
  /// 返回包含执行结果[T]的[WorkFuture]。
  /// * [retry]为请求失败重试次数，0表示不重试，实际请求1次，1表示重试1次，实际最多请求两次，以此类推
  /// * [onSendProgress]为数据上传/发送进度监听器，[onReceiveProgress]为数据接收/下载进度监听器，
  /// * 多次调用会启动多次请求
  @override
  WorkFuture<D, T> start({
    int retry = 0,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) {
    final future = WorkFuture<D, T>._(_tag);

    _onDo(
      future: future,
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
    required WorkFuture<D, T> future,
    required int retry,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) async {
    assert(retry >= 0);

    log(_tag, 'work start');

    // 创建数据模型
    final data = onCreateWorkData();

    // 是否继续执行
    var next = true;

    if (!future._isCanceled) {
      // 执行前导任务
      next = await _onStartWork(data);
    }

    if (!future._isCanceled && next) {
      // 构建http请求选项
      data._options = await _onCreateOptions(
        retry,
        onSendProgress,
        onReceiveProgress,
      );
    }

    if (!future._isCanceled && next) {
      // 执行核心任务
      await _onDoWork(future, data);
    }

    if (!future._isCanceled) {
      // 执行后继任务
      await _onStopWork(data);
    }

    if (future._isCanceled) {
      // 任务被取消
      log(_tag, 'onCanceled');
      try {
        final canceled = onCanceled(data);
        if (canceled is Future<void>) {
          await canceled;
        }
        // ignore: empty_catches
      } catch (e) {}
    }

    if (!future._isCanceled) {
      // 最后执行
      log(_tag, 'onFinish');
      try {
        final finish = onFinish(data);
        if (finish is Future<void>) {
          await finish;
        }
        // ignore: empty_catches
      } catch (e) {}
    }

    log(_tag, 'work end');

    return data;
  }

  /// 任务启动前置方法
  ///
  /// [data]为任务将要返回的数据模型，返回true表示继续执行
  Future<bool> _onStartWork(T data) async {
    // 校验参数
    final check = onCheckParams();
    final checkResult = (check is Future<bool>) ? await check : check;
    if (checkResult) {
      return true;
    }

    // 数据异常
    log(_tag, 'onParamsError');
    data._message = onParamsError();
    return false;
  }

  /// 构建请求选项参数
  Future<HttpOptions> _onCreateOptions(
    int retry,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  ) async {
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

    final options = HttpOptions()
      ..retry = retry
      ..onSendProgress = onSendProgress
      ..onReceiveProgress = onReceiveProgress
      ..method = onHttpMethod()
      ..configKey = onConfigKey()
      ..contentType = onContentType()
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
  Future<void> _onDoWork(WorkFuture<D, T> future, T data) async {
    log(_tag, 'onWillRequest');
    final willRequest = onWillRequest(data);
    if (willRequest is Future<void>) {
      await willRequest;
    }

    if (future._isCanceled) {
      return;
    }

    unawaited(future.catchError(
      (_) => data.options?.cancelToken.cancel(),
      test: (error) => error is WorkCanceled,
    ));

    // 创建网络请求工具
    final request = onWorkRequest(data.options!);

    data._response = await request(_tag, data.options!);

    if (future._isCanceled) {
      return;
    }

    await _onParseResponse(data);
  }

  /// 解析响应数据
  Future<void> _onParseResponse(T data) async {
    if (data.response!.success) {
      // 解析数据
      if (await _onParse(data)) {
        // 解析成功
        log(_tag, 'onParseSuccess');
        final parseSuccess = onParseSuccess(data);
        if (parseSuccess is Future<void>) {
          await parseSuccess;
        }
      } else {
        // 解析失败
        data._success = false;
        data.response!.errorType = WorkErrorType.parse;
        log(_tag, 'onParseFailed');
        data._message = onParseFailed(data);
      }
    } else if (data.response!.errorType == WorkErrorType.response) {
      // 网络请求失败
      log(_tag, 'onNetworkRequestFailed');
      data._message = onNetworkRequestFailed(data);
    } else {
      // 网络连接失败
      log(_tag, 'onNetworkError');
      data._message = onNetworkError(data);
    }
  }

  /// 解析响应体，返回解析结果
  Future<bool> _onParse(T data) async {
    try {
      // 提取服务执行结果
      log(_tag, 'onRequestResult');
      data._success = onRequestResult(data);

      if (data.success) {
        // 服务请求成功回调
        log(_tag, 'onRequestSuccess');
        final responseSuccess = onRequestSuccess(data);
        if (responseSuccess is Future<D?>) {
          data._result = await responseSuccess;
        } else {
          data._result = responseSuccess;
        }

        // 提取服务返回的消息
        log(_tag, 'onRequestSuccessMessage');
        data._message = onRequestSuccessMessage(data);
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
        data._message = onRequestFailedMessage(data);
        data.response!.errorType = WorkErrorType.task;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 任务完成后置方法
  Future<void> _onStopWork(T data) async {
    try {
      // 不同结果的后继执行
      if (data.success) {
        log(_tag, 'onSuccess');
        final success = onSuccess(data);
        if (success is Future<void>) {
          await success;
        }
      } else {
        log(_tag, 'onFailed message:${data.message}');
        final failed = onFailed(data);
        if (failed is Future<void>) {
          await failed;
        }
      }
      // ignore: empty_catches
    } catch (e) {}
  }
}
