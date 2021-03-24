// Created by 超悟空 on 2018/9/20.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import '_print.dart';
import 'work_config.dart' show workRequest;
import 'work_model.dart';

/// [Work]返回的数据包装类
///
/// 包含响应的全部数据，[T]类型的业务数据实例，[success]表示成功失败，
/// [message]服务响应的消息，http响应码[code]，请求传入的参数[params],
/// 服务正真有用的数据对象[result]。
class WorkData<T> {
  /// 本次服务成功失败标志
  bool _success = false;

  /// 服务响应消息
  String _message;

  /// 任务结果数据
  T _result;

  /// 用于网络请求使用的参数
  Options _options;

  /// http响应数据
  ///
  /// 在[Work._onParseResponse]生命周期阶段开始出现
  Response _response;

  /// 生成本任务数据的原始任务实例
  Work<T, WorkData<T>> _work;

  /// 判断本次服务请求是否成功(用户接口协议约定的请求结果，并非http的请求结果，但是http请求失败时该值总是返回false)
  bool get success => _success;

  /// 获取本次请求返回的结果消息(用户接口协议中约定的消息或者根据规则生成的本地信息，并非http响应消息）
  String get message => _message;

  /// 获取处理完成的最终结果数据(用户接口协议中定义的有效数据转化成的本地类)
  T get result => _result;

  /// 用于网络请求使用的参数
  Options get options => _options;

  /// http响应数据
  ///
  /// 在[Work._onParseResponse]生命周期阶段开始出现
  Response get response => _response;

  /// 生成本任务数据的原始任务实例
  Work<T, WorkData<T>> get work => _work;
}

/// 任务执行专用[Future]，提供了取消功能
class WorkFuture<D, T extends WorkData<D>> implements Future<T> {
  WorkFuture._(this._tag);

  /// 任务标识
  final String _tag;

  /// 真正的完成器
  final _completer = Completer<T>();

  /// 是否被取消
  bool _isCanceled = false;

  /// 执行完成
  void _complete(T data) {
    if (_isCanceled) {
      return;
    }
    _completer.complete(data);
  }

  /// 取消正在进行的任务
  void cancel() {
    log(_tag, 'cancel');
    if (_isCanceled) {
      log(_tag, 'work has been canceled');
      return;
    }
    if (_completer.isCompleted) {
      log(_tag, 'work finished');
      return;
    }
    _isCanceled = true;
    _completer.completeError(WorkCanceled._(_tag));
  }

  @override
  Stream<T> asStream() => _completer.future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error) test}) =>
      _completer.future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
          {Function onError}) =>
      _completer.future.then<R>(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function() onTimeout}) =>
      _completer.future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _completer.future.whenComplete(action);

  @override
  String toString() =>
      '$_tag(${_isCanceled ? "canceled" : _completer.isCompleted ? "complete" : "active"})';
}

/// 任务取消异常
class WorkCanceled implements Exception {
  WorkCanceled._(this._tag);

  /// 任务标识
  final String _tag;

  @override
  String toString() => 'This ticker was canceled:$_tag';
}

/// 任务流程的基本模型
///
/// [D]为关联的接口结果数据类型，[T]为接口响应包装类型[WorkData]
abstract class Work<D, T extends WorkData<D>> {
  /// 日志标签
  String _logTag;

  /// 日志标签
  String get _tag => _logTag ?? _createTag();

  /// 创建日志标签
  String _createTag() {
    _logTag = '$runtimeType@${hashCode.toRadixString(16)}';
    return _logTag;
  }

  /// 启动任务
  ///
  /// 返回包含执行结果[T]的[WorkFuture]。
  /// * [retry]为请求失败重试次数，0表示不重试，实际请求1次，1表示重试1次，实际最多请求两次，以此类推
  /// * [onSendProgress]为数据发送进度监听器，[onReceiveProgress]为数据接收进度监听器，
  /// 在[HttpMethod.download]请求中为下载进度，在其他类型请求中为上传/发送进度。
  /// * 多次调用会启动多次请求
  WorkFuture<D, T> start({
    int retry = 0,
    OnProgress onSendProgress,
    OnProgress onReceiveProgress,
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
    WorkFuture<D, T> future,
    int retry = 0,
    OnProgress onSendProgress,
    OnProgress onReceiveProgress,
  }) async {
    assert(retry != null && retry >= 0);

    log(_tag, 'work start');

    // 创建数据模型
    final data = onCreateWorkData();

    data._work = this;

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

    if (!future._isCanceled) {
      // 最后执行
      log(_tag, 'onFinish invoke');
      try {
        final finish = onFinish(data);
        if (finish is Future<void>) {
          await finish;
        }
      } catch (e) {
        log(_tag, 'onFinish failed', e);
      }
    }

    if (future._isCanceled) {
      // 任务被取消
      log(_tag, 'onCanceled invoked');
      try {
        final canceled = onCanceled(data);
        if (canceled is Future<void>) {
          await canceled;
        }
      } catch (e) {
        log(_tag, 'onCanceled failed', e);
      }
    }

    log(_tag, 'work end');

    return data;
  }

  /// 创建数据模型对象的实例
  @protected
  T onCreateWorkData();

  /// 任务启动前置方法
  ///
  /// [data]为任务将要返回的数据模型，返回true表示继续执行
  @protected
  @mustCallSuper
  Future<bool> _onStartWork(T data) async {
    // 校验参数
    final check = onCheckParams();
    final checkResult = (check is Future<bool>) ? await check : check;
    if (!checkResult) {
      // 数据异常
      log(_tag, 'onStartWork params error');
      // 执行异常回调
      final message = onParamsError();
      if (message is Future<String>) {
        data._message = await message;
      } else {
        data._message = message;
      }
      return false;
    }

    return true;
  }

  /// 构建请求选项参数
  Future<Options> _onCreateOptions(
    int retry,
    OnProgress onSendProgress,
    OnProgress onReceiveProgress,
  ) async {
    log(_tag, '_onCreateOptions');

    final data = <String, dynamic>{};

    final preFillParams = onPreFillParams();
    if (preFillParams is Future<Map<String, dynamic>>) {
      data.addAll(await preFillParams);
    } else if (preFillParams != null) {
      data.addAll(preFillParams);
    }

    final fillParams = onFillParams();
    if (fillParams is Future<Map<String, dynamic>>) {
      data.addAll(await fillParams);
    } else if (fillParams != null) {
      data.addAll(fillParams);
    }

    final options = Options()
      ..retry = retry
      ..onSendProgress = onSendProgress
      ..onReceiveProgress = onReceiveProgress
      ..method = onHttpMethod()
      ..clientKey = onClientKey()
      ..url = onUrl();

    final headers = onHeaders();
    if (headers is Future<Map<String, dynamic>>) {
      options.headers = await headers;
    } else {
      options.headers = headers;
    }

    final postFillParams = onPostFillParams(data);
    if (postFillParams is Future) {
      options.params = await postFillParams ?? data;
    } else {
      options.params = postFillParams ?? data;
    }

    final configOptions = onConfigOptions(options);

    if (configOptions is Future<void>) {
      await configOptions;
    }

    options.cancelToken = CancelToken();

    return options;
  }

  /// 核心任务执行
  ///
  /// 此处为真正启动http请求的方法
  Future<void> _onDoWork(WorkFuture<D, T> future, T data) async {
    final willRequest = onWillRequest(data);
    if (willRequest is Future<void>) {
      await willRequest;
    }

    if (future._isCanceled) {
      return;
    }

    unawaited(future.catchError(
      (_) => data.options.cancelToken?.cancel(),
      test: (error) => error is WorkCanceled,
    ));

    // 创建网络请求工具
    final request = onWorkRequest() ?? workRequest;

    data._response = await request(_tag, data.options);

    if (future._isCanceled) {
      return;
    }

    await _onParseResponse(data);
  }

  /// 解析响应数据
  Future<void> _onParseResponse(T data) async {
    log(_tag, '_onParse response parse start');

    if (data.response.success) {
      // 解析数据
      if (await _onParse(data)) {
        // 解析成功
        log(_tag,
            '_onParseResponse result parse success onParseSuccess invoke');
        // 解析成功回调
        final parseSuccess = onParseSuccess(data);
        if (parseSuccess is Future<void>) {
          await parseSuccess;
        }
        if (data.success) {
          log(_tag, 'work success');
        } else {
          log(_tag, 'work failed');
        }
      } else {
        // 解析失败
        log(_tag, '_onParseResponse result parse failed onParseFailed invoke');
        // 解析失败回调
        data._success = false;
        data.response.errorType = HttpErrorType.parse;
        final parseFailed = onParseFailed(data);
        if (parseFailed is Future<String>) {
          data._message = await parseFailed;
        } else {
          data._message = parseFailed;
        }
      }
    } else if (data.response.errorType == HttpErrorType.response) {
      // 网络请求失败
      log(_tag,
          '_onParseResponse network request false onNetworkRequestFailed invoke');

      // 网络请求失败回调
      final networkRequestFailed = onNetworkRequestFailed(data);
      if (networkRequestFailed is Future<String>) {
        data._message = await networkRequestFailed;
      } else {
        data._message = networkRequestFailed;
      }
    } else {
      // 网络连接失败
      log(_tag, '_onParseResponse network error onNetworkError invoke');

      // 网络错误回调
      final networkError = onNetworkError(data);
      if (networkError is Future<String>) {
        data._message = await networkError;
      } else {
        data._message = networkError;
      }
    }
  }

  /// 解析响应体，返回解析结果
  Future<bool> _onParse(T data) async {
    log(_tag, '_onParse start');
    final checkResponse = onCheckResponse(data);
    final checkResponseResult =
        (checkResponse is Future<bool>) ? await checkResponse : checkResponse;
    if (!checkResponseResult) {
      // 通信异常
      log(_tag, '_onParse response body error');
      return false;
    }

    try {
      // 提取服务执行结果
      final responseResult = onResponseResult(data);
      if (responseResult is Future<bool>) {
        data._success = await responseResult;
      } else {
        data._success = responseResult;
      }

      log(_tag, '_onParse request result:${data.success}');

      if (data.success) {
        // 服务请求成功回调
        log(_tag, '_onParse onRequestSuccess invoked');
        final responseSuccess = onResponseSuccess(data);
        if (responseSuccess is Future<D>) {
          data._result = await responseSuccess;
        } else {
          data._result = responseSuccess;
        }

        // 提取服务返回的消息
        final requestSuccessMessage = onRequestSuccessMessage(data);
        if (requestSuccessMessage is Future<String>) {
          data._message = await requestSuccessMessage;
        } else {
          data._message = requestSuccessMessage;
        }
      } else {
        // 服务请求失败回调
        log(_tag, '_onParse onRequestFailed invoked');
        final requestFailed = onRequestFailed(data);
        if (requestFailed is Future<D>) {
          data._result = await requestFailed;
        } else {
          data._result = requestFailed;
        }

        // 提取服务返回的消息
        final requestFailedMessage = onRequestFailedMessage(data);
        if (requestFailedMessage is Future<String>) {
          data._message = await requestFailedMessage;
        } else {
          data._message = requestFailedMessage;
        }
        data.response.errorType = HttpErrorType.task;
      }
      log(_tag, '_onParse request message:', data.message);

      return true;
    } catch (e) {
      log(_tag, '_onParse error:', e);
      return false;
    } finally {
      log(_tag, '_onParse end');
    }
  }

  /// 任务完成后置方法
  Future<void> _onStopWork(T data) async {
    log(_tag, 'onStopWork invoked');

    try {
      // 不同结果的后继执行
      if (data.success) {
        log(_tag, 'onSuccess invoke');
        final success = onSuccess(data);
        if (success is Future<void>) {
          await success;
        }
      } else {
        log(_tag, 'onFailed invoke');
        final failed = onFailed(data);
        if (failed is Future<void>) {
          await failed;
        }
      }
    } catch (e) {
      log(_tag, 'onStopWork failed', e);
    }
  }

  /// 参数合法性检测
  ///
  /// * 用于检测任务启动所需的参数是否合法，需要子类重写检测规则。
  /// * 检测成功任务才会被正常执行，如果检测失败则[onParamsError]会被调用，
  /// 且后续网络请求任务不再执行，任务任然可以正常返回并执行生命周期[onFailed]，[onFinish]。
  /// * 参数合法返回true，非法返回false。
  @protected
  FutureOr<bool> onCheckParams() => true;

  /// 参数检测不合法时调用
  ///
  /// * [onCheckParams]返回false时被调用，且后续网络请求任务不再执行，
  /// 但是任务任然可以正常返回并执行生命周期[onFailed]，[onFinish]。
  /// * 返回错误消息内容，将会设置给[WorkData.message]
  @protected
  FutureOr<String> onParamsError() => null;

  /// 返回请求实现方法
  ///
  /// 默认实现为[workRequest]
  /// 如果要覆盖全局实现，请覆盖[workRequest]
  /// 如果仅覆盖本任务请重写此方法
  @protected
  WorkRequest onWorkRequest() => workRequest;

  /// 用于指定使用的网络全局网络访问器的key
  ///
  /// 返回null或key不存在则表示使用默认访问器
  /// 关联性请查看[work_config.dart]
  @protected
  String onClientKey() => null;

  /// 网络请求方法
  @protected
  HttpMethod onHttpMethod() => HttpMethod.get;

  /// 网络请求地址
  ///
  /// 可以是完整地址，也可以是相对地址（需要设置baseUrl，关联性请查看[work_config.dart]）
  @protected
  String onUrl();

  /// 创建并填充请求头
  @protected
  FutureOr<Map<String, dynamic>> onHeaders() => null;

  /// 自定义配置http请求选择项
  ///
  /// * [options]为请求将要使用的配置选项，修改[options]的属性以定制http行为。
  /// * [options]包含[httpMethod]返回的请求方法，
  /// [onFillParams]填充的参数，
  /// [onUrl]返回的请求地址，
  /// [start]中传传递的[retry]和[onProgress]，
  /// [onHeaders]中创建的请求头，
  /// 以上属性都可以在这里被覆盖可以被覆盖。
  @protected
  FutureOr<void> onConfigOptions(Options options) {}

  /// 填充请求所需的前置参数
  ///
  /// * 适合填充项目中所有接口必须传递的固定参数（通过项目中实现的定制[Work]基类完成）
  /// * 返回预填充的参数对，没有返回null或空对象
  /// * 返回的参数最终会和[onFillParams]中返回的参数合并，且可能会被[onFillParams]中的同名参数覆盖
  @protected
  FutureOr<Map<String, dynamic>> onPreFillParams() => null;

  /// 填充请求所需的参数
  ///
  /// * 返回填充的参数对，没有返回null或空对象
  /// * 返回的参数最终会和[onPreFillParams]中返回的参数合并，且可以覆盖[onPreFillParams]中的同名参数
  @protected
  FutureOr<Map<String, dynamic>> onFillParams();

  /// 填充请求所需的后置参数
  ///
  /// * 适合对参数进行签名（通过项目中实现的定制[Work]基类完成）
  /// * [data]为请求参数集（http请求要发送的参数），由[onPreFillParams]和[onFillParams]生成
  /// * 如果需要使用其他数据类型作为请求参数，请返回新的数据集合对象，支持[Map]，[List]，[String]([ResponseType.plain])
  /// * 可以直接在data中增加新参数，也可以返回新集合
  /// * 可以直接返回[data]，不返回参数或返回null则继续使用[data]作为请求参数
  @protected
  FutureOr<dynamic> onPostFillParams(Map<String, dynamic> data) => null;

  /// 即将执行网络请求前的回调
  ///
  /// 此处可以用于做数据统计，特殊变量创建等，如果调用[cancel]则会拦截接下来的网络请求
  @protected
  FutureOr<void> onWillRequest(T data) {}

  /// 服务器响应数据解析成功后调用
  ///
  /// 即在[_onParse]返回true时调用
  @protected
  FutureOr<void> onParseSuccess(T data) {}

  /// 网络请求成功，服务器响应数据解析失败后调用
  ///
  /// 即在[_onParse]返回false时调用，
  /// 返回响应数据解析失败时的消息，即[WorkData.message]字段
  @protected
  FutureOr<String> onParseFailed(T data) => null;

  /// 网络连接建立成功，但是请求失败时调用
  ///
  /// 即响应码不是200，如4xx，5xx，返回网络请求失败时的消息，即[WorkData.message]字段
  @protected
  FutureOr<String> onNetworkRequestFailed(T data) => null;

  /// 网络连接建立失败时调用，即网络不可用
  ///
  /// 返回设置网络无效时的消息，即[WorkData.message]字段
  @protected
  FutureOr<String> onNetworkError(T data) => null;

  /// 检测响应结果是否符合预期（数据类型或是否包含特定字段），也可以做验签
  ///
  /// * 通常[data.response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[data.response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[data.response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[data.response]为字符串。
  @protected
  FutureOr<bool> onCheckResponse(T data) => true;

  /// 提取服务执行结果
  ///
  /// * http响应成功，从接口响应的数据中提取本次业务请求真正的成功或失败结果。
  /// * 通常[data.response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[data.response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[data.response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[data.response]为字符串。
  @protected
  FutureOr<bool> onResponseResult(T data);

  /// 提取服务执行成功时返回的真正有用结果数据
  ///
  /// * 在服务请求成功后调用，即[onResponseResult]返回值为true时被调用，
  /// 用于生成请求成功后的任务返回真正结果数据对象[D]。
  /// * 通常[data.response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[data.response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[data.response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[data.response]为字符串。
  @protected
  FutureOr<D> onResponseSuccess(T data);

  /// 提取或设置服务返回的成功结果消息
  ///
  /// 在服务请求成功后调用，即[onResponseResult]返回值为true时被调用。
  @protected
  FutureOr<String> onRequestSuccessMessage(T data) => null;

  /// 提取或设置服务执行失败时的返回结果数据
  ///
  /// 在服务请求失败后调用，即[onResponseResult]返回值为false时被调用，
  /// 用于生成请求失败后的任务返回真正结果数据对象[D]，可能是一个默认值。
  @protected
  FutureOr<D> onRequestFailed(T data) => null;

  /// 提取或设置服务返回的失败结果消息
  ///
  /// 在服务请求失败后调用，即[onResponseResult]返回值为false时被调用。
  FutureOr<String> onRequestFailedMessage(T data) => null;

  /// 本次任务执行成功后执行
  ///
  /// 即设置请求结果和返回数据之后，并且在回调接口之前执行此函数，
  /// 该方法在[onFinish]之前被调用
  @protected
  FutureOr<void> onSuccess(T data) {}

  /// 本次任务执行失败后执行
  ///
  /// 即设置请求结果和返回数据之后，并且在回调接口之前执行此函数，
  /// 该方法在[onFinish]之前被调用
  @protected
  FutureOr<void> onFailed(T data) {}

  /// 最后执行的一个方法
  ///
  /// 即设置请求结果和返回数据之后，并且在回调任务发送后才执行此函数
  @protected
  FutureOr<void> onFinish(T data) {}

  /// 任务被取消时调用
  @protected
  FutureOr<void> onCanceled(T data) {}
}
