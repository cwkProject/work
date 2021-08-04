// Created by 超悟空 on 2021/5/7.

part of 'work_core.dart';

/// [Work]返回的数据包装类
///
/// 包含响应的全部数据，[T]类型的业务数据实例，[success]表示成功失败，
/// [message]服务响应的消息，http响应[response]，任务正真有用的数据对象[result]。
class WorkData<T> {
  /// 本次任务成功失败标志
  bool _success = false;

  /// 服务响应消息
  String? _message;

  /// 任务结果数据
  T? _result;

  /// 用于网络请求使用的参数
  WorkRequestOptions? _options;

  /// http响应数据
  ///
  /// 在[Work._onParseResponse]生命周期阶段开始出现
  HttpResponse? _response;

  /// 异常类型
  ///
  /// null表示无异常
  WorkErrorType? _errorType;

  /// 标记本次任务的结果是否是从本地缓存加载
  bool _fromCache = false;

  /// 本次任务请求是否成功
  ///
  ///
  /// 用户接口协议约定的请求结果，
  /// 即[Work.onRequestResult]返回的结果，
  /// 并非http的请求结果，但是http请求失败时该值总是返回false
  bool get success => _success;

  /// 获取本次请求返回的结果消息(用户接口协议中约定的消息或者根据规则生成的本地信息，并非http响应消息）
  String? get message => _message;

  /// 获取处理完成的最终结果数据(用户接口协议中定义的有效数据转化成的本地类)
  T? get result => _result;

  /// 本次任务请求的全部参数
  ///
  /// 如果[fromCache]为true，则此值为空
  WorkRequestOptions? get options => _options;

  /// http响应数据
  HttpResponse? get response => _response;

  /// 异常类型
  ///
  /// null表示无异常
  WorkErrorType? get errorType => _errorType;

  /// 标记本次任务的结果是否是从本地缓存加载
  ///
  /// 如果在[Work.onStarted]中提前返回了[result]，则此属性返回true
  bool get fromCache => _fromCache;
}

/// 任务执行专用[Future]，提供了取消功能
///
/// [T]为[WorkData]子类
class WorkFuture<T> implements Future<T> {
  WorkFuture._(this._tag, this.onCanceled);

  /// 任务标识
  final String _tag;

  /// 真正的完成器
  final _completer = Completer<T>();

  /// 用户执行取消事件
  final void Function() onCanceled;

  /// 是否被取消
  bool _isCanceled = false;

  /// 执行完成
  void _complete(T data) {
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
    onCanceled();
  }

  @override
  Stream<T> asStream() => _completer.future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _completer.future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
          {Function? onError}) =>
      _completer.future.then<R>(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _completer.future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _completer.future.whenComplete(action);

  @override
  String toString() =>
      '$_tag(${_isCanceled ? "canceled" : _completer.isCompleted ? "complete" : "active"})';
}

/// 任务的异常类型
class WorkError implements Exception {
  WorkError._(this._tag, this.type, [this.message, this.origin]);

  /// 任务标识
  final String _tag;

  /// 异常类型
  final WorkErrorType type;

  /// 错误信息
  final String? message;

  /// 原始错误信息
  final dynamic origin;

  @override
  String toString() {
    return 'WorkError $_tag - $type :$message $origin';
  }
}

/// dio最终请求选项的包装类
///
/// 主要用于打印日志
class _FinalRequestOptions {
  _FinalRequestOptions(this.requestOptions);

  /// dio的最终请求选项
  final RequestOptions requestOptions;

  @override
  String toString() {
    return '${requestOptions.uri}';
  }
}
