// Created by 超悟空 on 2021/5/10.

import 'dart:async';

void main() async {
  try {
    final completer = CancelableFuture()
      ..catchError((e) {
        print('catchError $e');
      });

    delayed().then(completer.complete).whenComplete(() {
      print('whenComplete');
    }).then((v){
      print('whenComplete then');
    });

    await Future.delayed(Duration(milliseconds: 200));

    completer.cancel();

    await Future.delayed(Duration(seconds: 2)).then((value) => '1');

    print('delayed 1');
  } catch (e) {
    print('catch $e');
  }

  await Future.delayed(Duration(seconds: 3));

  print('finish');
}

Future<void> delayed() async {
  print('delayed begin');
  try {
    await Future.delayed(Duration(milliseconds: 100));
    print('delayed 100');
    await Future.delayed(Duration(milliseconds: 200));
    print('delayed 200');
    await Future.delayed(Duration(milliseconds: 300));
    print('delayed 300');
  } catch (e) {
    print('delayed $e');
  }

  print('delayed end');
}

/// 任务执行专用[Future]，提供了取消功能
class CancelableFuture<T> implements Future<T> {
  /// 真正的完成器
  final _completer = Completer<T>();

  /// 是否被取消
  bool _isCanceled = false;

  /// 执行完成
  void complete(T data) {
    if (_isCanceled) {
      return;
    }
    _completer.complete(data);
  }

  /// 取消正在进行的任务
  void cancel() {
    if (_isCanceled) {
      return;
    }
    if (_completer.isCompleted) {
      return;
    }
    _isCanceled = true;
    _completer.completeError(CancelableCanceled());
  }

  @override
  Stream<T> asStream() => _completer.future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _completer.future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) =>
      _completer.future.then<R>(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _completer.future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) => _completer.future.whenComplete(action);

  @override
  String toString() => '(${_isCanceled ? "canceled" : _completer.isCompleted ? "complete" : "active"})';
}

/// 任务取消异常
class CancelableCanceled implements Exception {
  @override
  String toString() => 'This work was canceled';
}
