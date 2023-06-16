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

  /// 当前任务是第几次重启
  int _restartCount = 0;

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
  /// 在[Work.onConfigOptions]生命周期执行后出现
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
  /// 当[Work.onHitCache]返回true时此属性也为true
  bool get fromCache => _fromCache;

  /// 当前任务是第几次重启
  ///
  /// 0表示首次用户调用[Work.start]的正常启动执行，大于0表示当前是第几次重新启动任务。
  ///
  /// 当[Work.onSuccessful],[Work.onFailed],[Work.onCanceled],[Work.onFinished]中有返回true时将会重新执行[Work.start]，
  /// 并且重新执行的[Work]生命周期中的`data`句柄中此变量会加1。
  int get restartCount => _restartCount;

  /// 任务执行生命周期中可以由用户自由赋值并传递的自定义数据
  ///
  /// 此数据可以贯穿全生命周期，包括[restartCount]描述的重试流程。
  /// 比如在第一次访问失败时进入[Work.onFailed]并返回true，同时给[extra]赋值则会在第二次重试流程的生命周期中读取该值，
  /// 即便第二次重试中[WorkData]是个全新实例。
  dynamic extra;
}

/// 任务执行专用[Future]，提供了取消功能
///
/// [D]为关联的接口结果数据类型，[T]为接口响应包装类型[WorkData]
class WorkFuture<D, T extends WorkData<D>> implements Future<T> {
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

  /// 仅当[Work]成功时，即[WorkData.success]为true时才执行[onValue]
  ///
  /// [WorkData.success]为false时返回null
  Future<R?> thenSuccessful<R>(FutureOr<R> Function(T value) onValue) =>
      _completer.future
          .then((value) => value.success ? onValue(value) : Future.value());

  /// 仅当[Work]失败时，即[WorkData.success]为false时才执行[onValue]
  ///
  /// [WorkData.success]为true时返回null
  Future<R?> thenFailed<R>(FutureOr<R> Function(T value) onValue) =>
      _completer.future
          .then((value) => !value.success ? onValue(value) : Future.value());

  /// `Work.start().then((data) => data.result)`的快捷方式
  /// 它会等待[Work.start]完成后执行[onValue]参数为[WorkData.result]。
  ///
  /// 无论[Work]成功或失败都会执行[onValue]
  Future<R?> thenResult<R>(FutureOr<R> Function(D? value) onValue) =>
      _completer.future.then((value) => onValue(value.result));

  /// 获取结果或抛出异常
  ///
  /// 如果任务执行成功即[WorkData.success]为true时，返回[WorkData.result]的未来。
  /// 如果任务执行失败即[WorkData.success]为false时，则抛出异常[WorkError]。
  ///
  /// [onDo]为任务执行成功即[WorkData.success]为true时，可选的执行函数，
  /// 参数为[WorkData.result]此函数的执行不会修改方法最终返回的值。
  Future<D?> resultOrThrow([FutureOr<void> Function(D? value)? onDo]) =>
      _completer.future.then((value) {
        if (!value.success) {
          return Future.error(WorkError._(
              _tag, value.errorType ?? WorkErrorType.other, value.message));
        }

        if (onDo != null) {
          final done = onDo(value.result);

          if (done is Future<void>) {
            return done.then((_) => value.result);
          }
        }

        return Future.value(value.result);
      });

  /// 获取结果或抛出纯字符串异常
  ///
  /// 如果任务执行成功即[WorkData.success]为true时，返回[WorkData.result]的未来。
  /// 如果任务执行失败即[WorkData.success]为false时，则抛出异常[WorkData.message]。
  ///
  /// [onDo]为任务执行成功即[WorkData.success]为true时，可选的执行函数，
  /// 参数为[WorkData.result]此函数的执行不会修改方法最终返回的值。
  Future<D?> resultOrThrowMessage([FutureOr<void> Function(D? value)? onDo]) =>
      _completer.future.then((value) {
        if (!value.success) {
          return Future.error(value.message ?? '');
        }

        if (onDo != null) {
          final done = onDo(value.result);

          if (done is Future<void>) {
            return done.then((_) => value.result);
          }
        }

        return Future.value(value.result);
      });

  /// 获取非空结果或抛出异常
  ///
  /// 如果任务执行成功即[WorkData.success]为true时，返回[WorkData.result]的非空未来。
  /// 如果任务执行失败即[WorkData.success]为false时，则抛出异常[WorkError]。
  ///
  /// [onDo]为任务执行成功即[WorkData.success]为true时，可选的执行函数，
  /// 参数为[WorkData.result]此函数的执行不会修改方法最终返回的值。
  ///
  /// 如果[WorkData.result]为null则会抛出异常[WorkError]
  Future<D> requiredResultOrThrow([FutureOr<void> Function(D value)? onDo]) =>
      _completer.future.then((value) {
        if (!value.success) {
          return Future.error(WorkError._(
              _tag, value.errorType ?? WorkErrorType.other, value.message));
        }

        final result = value.result;

        if (result == null) {
          return Future.error(
              WorkError._(_tag, WorkErrorType.noResult, 'empty result'));
        }

        if (onDo != null) {
          final done = onDo(result);

          if (done is Future<void>) {
            return done.then((_) => result);
          }
        }

        return Future.value(result);
      });

  /// 获取非空结果或抛出纯字符串异常
  ///
  /// 如果任务执行成功即[WorkData.success]为true时，返回[WorkData.result]的非空未来。
  /// 如果任务执行失败即[WorkData.success]为false时，则抛出异常[WorkData.message]。
  ///
  /// [onDo]为任务执行成功即[WorkData.success]为true时，可选的执行函数，
  /// 参数为[WorkData.result]此函数的执行不会修改方法最终返回的值。
  ///
  /// 如果[WorkData.result]为null则会抛出异常[WorkError]
  Future<D> requiredResultOrThrowMessage(
          [FutureOr<void> Function(D value)? onDo]) =>
      _completer.future.then((value) {
        if (!value.success) {
          return Future.error(value.message ?? '');
        }

        final result = value.result;

        if (result == null) {
          return Future.error(
              WorkError._(_tag, WorkErrorType.noResult, 'empty result'));
        }

        if (onDo != null) {
          final done = onDo(result);

          if (done is Future<void>) {
            return done.then((_) => result);
          }
        }

        return Future.value(result);
      });

  /// 返回任务执行结果[WorkData.result]，无论任务成功或失败
  Future<D?> result() => _completer.future.then((value) => value.result);

  /// 返回任务执行结果的未来
  Future<bool> success() => _completer.future.then((value) => value.success);

  /// 返回[WorkData.message]无论任务成功或失败
  Future<String?> message() => _completer.future.then((value) => value.message);

  @override
  String toString() =>
      '$_tag(${_isCanceled ? "canceled" : _completer.isCompleted ? "complete" : "active"})';
}

/// 任务的异常类型
class WorkError implements Exception {
  WorkError._(this._tag, this.type, [this.message, this.origin, this.stack]);

  /// 任务标识
  final String _tag;

  /// 异常类型
  final WorkErrorType type;

  /// 错误信息
  final String? message;

  /// 原始错误信息
  final dynamic origin;

  /// 错误栈
  final StackTrace? stack;

  @override
  String toString() {
    final msg = StringBuffer('WorkError [$_tag - $type] :$message');
    if (origin != null) {
      msg.writeln();
      msg.writeln('$origin');
    }

    if (stack != null) {
      msg.writeln();
      msg.writeln('$stack');
    }

    return msg.toString();
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
