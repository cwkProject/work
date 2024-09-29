// Created by 超悟空 on 2024/9/27.

part of 'work_config.dart';

/// [Work]中生命周期的全局实现委托
///
/// 作用类似于给[Work]增加了一个超类实现
@immutable
abstract class WorkDelegate {
  const WorkDelegate();

  /// {@macro work.work_core.Work.onRequestResult}
  bool onRequestResult(WorkData data) => true;

  /// {@macro work.work_core.Work.onHttpMethod}
  HttpMethod onHttpMethod(WorkData data) => HttpMethod.get;

  /// {@macro work.work_core.Work.onContentType}
  String? onContentType(WorkData data) => null;

  /// {@macro work.work_core.Work.onHeaders}
  FutureOr<Map<String, dynamic>?> onHeaders(WorkData data) => null;

  /// {@macro work.work_core.Work.onQueryParams}
  FutureOr<Map<String, dynamic>?> onQueryParams(WorkData data) => null;

  /// {@macro work.work_core.Work.onResponseType}
  ResponseType? onResponseType(WorkData data) => null;

  /// {@macro work.work_core.Work.onPostOptions}
  FutureOr<void> onPostOptions(WorkData data) {}

  /// {@macro work.work_core.Work.onCheckParams}
  FutureOr<bool> onCheckParams(WorkData data) => true;

  /// {@macro work.work_core.Work.onParamsError}
  String? onParamsError(WorkData data) => null;

  /// {@macro work.work_core.Work.onRequestSuccessfulMessage}
  String? onRequestSuccessfulMessage(WorkData data) => null;

  /// {@macro work.work_core.Work.onNetworkError}
  String? onNetworkError(WorkData data) => null;

  /// {@macro work.work_core.Work.onNetworkRequestFailed}
  String? onNetworkRequestFailed(WorkData data) => null;

  /// {@macro work.work_core.Work.onRequestFailedMessage}
  String? onRequestFailedMessage(WorkData data) => null;

  /// {@macro work.work_core.Work.onParseFailed}
  String? onParseFailed(WorkData data) => null;

  /// {@macro work.work_core.Work.onMaxRestart}
  int onMaxRestart(WorkData data) => 3;

  /// {@macro work.work_core.Work.onStarted}
  FutureOr<void> onStarted(WorkData data) => null;

  /// {@macro work.work_core.Work.onSuccessful}
  FutureOr<bool> onSuccessful(WorkData data) => false;

  /// {@macro work.work_core.Work.onFailed}
  FutureOr<bool> onFailed(WorkData data) => false;

  /// {@macro work.work_core.Work.onCanceled}
  FutureOr<bool> onCanceled(WorkData data) => false;

  /// {@macro work.work_core.Work.onFinished}
  FutureOr<bool> onFinished(WorkData data) => false;
}

class _WorkDelegateImp extends WorkDelegate {
  const _WorkDelegateImp();
}
