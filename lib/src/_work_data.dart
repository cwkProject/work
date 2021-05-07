// Created by 超悟空 on 2021/5/7.

part of 'work_core.dart';

/// [Work]返回的数据包装类
///
/// 包含响应的全部数据，[T]类型的业务数据实例，[success]表示成功失败，
/// [message]服务响应的消息，http响应码[code]，请求传入的参数[params],
/// 服务正真有用的数据对象[result]。
class WorkData<T> {
  /// 本次服务成功失败标志
  bool _success = false;

  /// 服务响应消息
  String? _message;

  /// 任务结果数据
  T? _result;

  /// 用于网络请求使用的参数
  HttpOptions? _options;

  /// http响应数据
  ///
  /// 在[Work._onParseResponse]生命周期阶段开始出现
  HttpResponse? _response;

  /// 异常类型
  ///
  /// null表示无异常
  WorkErrorType? _errorType;

  /// 判断本次服务请求是否成功(用户接口协议约定的请求结果，并非http的请求结果，但是http请求失败时该值总是返回false)
  bool get success => _success;

  /// 获取本次请求返回的结果消息(用户接口协议中约定的消息或者根据规则生成的本地信息，并非http响应消息）
  String? get message => _message;

  /// 获取处理完成的最终结果数据(用户接口协议中定义的有效数据转化成的本地类)
  T? get result => _result;

  /// 用于网络请求使用的参数
  HttpOptions? get options => _options;

  /// http响应数据
  ///
  /// 在[Work._onParseResponse]生命周期阶段开始出现
  HttpResponse? get response => _response;

  /// 异常类型
  ///
  /// null表示无异常
  WorkErrorType? get errorType => _errorType;
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

/// 任务取消异常
class WorkCanceled implements Exception {
  WorkCanceled._(this._tag);

  /// 任务标识
  final String _tag;

  @override
  String toString() => 'This work was canceled:$_tag';
}
