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

part '_work_data.dart';
part '_work_extension.dart';

/// 任务流程的基本模型
///
/// [D]为关联的接口结果数据类型，最终在[WorkData.result]中获取
@immutable
abstract class Work<D> {
  const Work();

  /// 启动任务
  ///
  /// * [retry]为内部网络请求失败时的最大重试次数，0表示不重试，实际请求1次，1表示重试1次，实际最多请求两次，以此类推，
  /// * [onSendProgress]为数据发送/上传进度监听器，在[HttpMethod.get]和[HttpMethod.head]中无效，
  /// 以及设置了[WorkRequestOptions.downloadPath]的下载任务中无效，
  /// * [onReceiveProgress]为数据接收/下载进度监听器，
  /// * 多次调用会启动多次请求
  @nonVirtual
  WorkFuture<D> start({
    int retry = 0,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  }) =>
      _start(
        retry: retry,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

  /// 生成请求所需的参数
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 返回类型通常是[Map]，也可以是[String]，[List]，[Stream]等，需要与Content-Type匹配，
  /// 同样可以使用自行拼装的[FormData]数据
  @protected
  FutureOr<dynamic> onFillParams(WorkData<D> data);

  /// 提取任务执行成功时返回的真正有用结果数据
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 其中包含Http响应结果[WorkData.response]。
  ///
  /// * 在任务执行成功后调用，即[onRequestResult]返回值为true时被调用，
  /// 用于生成执行成功后的任务返回真正结果数据[D]的实例。
  /// * 通常[WorkData.response]中的[HttpResponse.data]的类型是[onResponseType]设置或其全局默认值决定的。
  /// 如果为[ResponseType.json]则为[Map]类型数据，
  /// 如果为[ResponseType.stream]则为[Stream]类型数据，
  /// 如果为[ResponseType.plain]则为[String]类型数据，
  /// 如果为[ResponseType.bytes]则为[List<int>]类型数据。
  @protected
  FutureOr<D?> onRequestSuccessful(WorkData<D> data);

  /// 网络请求地址
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 可以是完整地址，也可以是相对地址（需要在[BaseOptions]中设置，关联性请查看[WorkConfig.dio]）
  @protected
  String onUrl(WorkData<D> data);

  /// 获取任务所用的配置
  @protected
  WorkConfig onWorkConfig() => workConfig;

  /// 提取或设置任务执行失败时的返回结果数据
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 其中包含Http响应结果[WorkData.response]。
  ///
  /// 在任务执行失败后调用，即[onRequestResult]返回值为false时被调用，
  /// 用于生成请求失败后的任务返回真正结果数据[D]的实例，通常是一个默认值。
  @protected
  FutureOr<D?> onRequestFailed(WorkData<D> data) => null;

  /// {@template work.work_core.Work.onRequestResult}
  /// http响应成功时提取任务执行结果
  ///
  /// 用于业务成功状态和http响应成功状态不一致的接口设计，
  /// 此处需要从接口响应的数据中提取本次业务请求真正的成功或失败结果。
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 其中包含Http响应结果[WorkData.response]。
  ///
  /// 返回true表示任务执行成功。
  /// 返回false表示失败，并进入异常流[onFailed]。
  ///
  /// * 此时http响应是成功的
  /// * 通常[WorkData.response]中的[HttpResponse.data]的类型是[onResponseType]设置或其全局默认值决定的。
  /// 如果为[ResponseType.json]则为[Map]类型数据，
  /// 如果为[ResponseType.stream]则为[Stream]类型数据，
  /// 如果为[ResponseType.plain]则为[String]类型数据，
  /// 如果为[ResponseType.bytes]则为[List<int>]类型数据。
  /// {@endtemplate}
  @protected
  bool onRequestResult(WorkData<D> data) =>
      data.workConfig.delegate.onRequestResult(data);

  /// {@template work.work_core.Work.onCheckParams}
  /// 参数合法性检测
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// * 用于检测任务启动所需的参数是否合法，需要子类重写检测规则。
  /// * 检测成功任务才会被正常执行，如果检测失败则[onParamsError]会被调用，
  /// 且后续网络请求任务不再执行，并进入异常流[onFailed]。
  /// * 参数合法返回true，非法返回false。
  /// {@endtemplate}
  @protected
  FutureOr<bool> onCheckParams(WorkData<D> data) =>
      data.workConfig.delegate.onCheckParams(data);

  /// {@template work.work_core.Work.onParamsError}
  /// 参数检测不合法时调用
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// * [onCheckParams]返回false时或者url不合法时被调用，且后续网络请求任务不再执行，并进入异常流[onFailed]。
  /// * 返回错误消息内容，将会设置给[WorkData.message]
  /// {@endtemplate}
  @protected
  String? onParamsError(WorkData<D> data) =>
      data.workConfig.delegate.onParamsError(data);

  /// {@template work.work_core.Work.onHttpMethod}
  /// 网络请求方法
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  /// {@endtemplate}
  @protected
  HttpMethod onHttpMethod(WorkData<D> data) =>
      data.workConfig.delegate.onHttpMethod(data);

  /// {@template work.work_core.Work.onContentType}
  /// 网络请求body的Content-Type
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 默认使用[WorkConfig]中的配置，
  /// 此值必须与[onFillParams]或[onPostFillParams]返回的参数类型兼容。
  /// {@endtemplate}
  @protected
  String? onContentType(WorkData<D> data) =>
      data.workConfig.delegate.onContentType(data);

  /// {@template work.work_core.Work.onHeaders}
  /// 创建并填充请求头
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  /// {@endtemplate}
  @protected
  FutureOr<Map<String, dynamic>?> onHeaders(WorkData<D> data) =>
      data.workConfig.delegate.onHeaders(data);

  /// {@template work.work_core.Work.onResponseType}
  /// 表示期望以哪种格式(方式)接受响应数据
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 默认值在[WorkConfig.dio]中设置，dio默认[ResponseType.json]。
  /// {@endtemplate}
  @protected
  ResponseType? onResponseType(WorkData<D> data) =>
      data.workConfig.delegate.onResponseType(data);

  /// {@template work.work_core.Work.onQueryParams}
  /// 生成请求所需的查询参数
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 通常参数应该在[onFillParams]中填充，
  /// 但是对于"POST","PUT","PATCH","DELETE"请求而言，
  /// 除了请求体"body"中可以传参外也支持在url中传递参数，
  /// 此生命周期方法就是用来辅助上述4类请求传递url中的查询参数所准备的。
  ///
  /// * 由于"GET","HEAD"请求本身并不支持请求体，所以对于这两类请求无需使用此方法。
  /// * 但是如果在"GET","HEAD"请求中通过此方法返回了集合实例，则会覆盖由[onFillParams]生成的参数。
  /// {@endtemplate}
  @protected
  FutureOr<Map<String, dynamic>?> onQueryParams(WorkData<D> data) =>
      data.workConfig.delegate.onQueryParams(data);

  /// {@template work.work_core.Work.onPostOptions}
  /// 后处理自定义配置http请求选择项
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  /// 内部[WorkData.options]已经准备就绪可以继续修改
  ///
  /// [WorkData.options]为请求将要使用的配置选项，修改[WorkData.options]的属性以定制http行为。
  /// 比如添加一些[onFillParams]以外的公共参数，或者对[onFillParams]的参数执行签名等。
  ///
  /// 包含：
  /// * [onHttpMethod]返回的请求方法，
  /// * [onContentType]填充的Content-Type
  /// * [onFillParams]填充的参数，
  /// * [onQueryParams]填充的查询参数，
  /// * [onUrl]返回的请求地址，
  /// * [onHeaders]中创建的请求头，
  /// * [onResponseType]中返回的响应格式，
  /// * [Work.start]传入的[onSendProgress]和[onReceiveProgress]，
  /// 以上属性都可以在这里被覆盖。
  /// {@endtemplate}
  @protected
  FutureOr<void> onPostOptions(WorkData<D> data) =>
      data.workConfig.delegate.onPostOptions(data);

  /// {@template work.work_core.Work.onRequestSuccessfulMessage}
  /// 提取或设置任务成功消息
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 其中包含Http响应结果[WorkData.response]，同时有[onRequestSuccessful]返回的结果数据[WorkData.result]。
  ///
  /// 在任务执行成功后调用，即[onRequestResult]返回值为true时被调用。
  /// 返回的消息会被设置给[WorkData.message]。
  /// {@endtemplate}
  @protected
  String? onRequestSuccessfulMessage(WorkData<D> data) =>
      data.workConfig.delegate.onRequestSuccessfulMessage(data);

  /// {@template work.work_core.Work.onNetworkError}
  /// 网络连接建立失败时调用，即网络不可用或域名不可达，如dns错误等
  ///
  /// [data]为本次任务执行周期中的数据包装类
  ///
  /// 返回网络无效时的消息，将会设置给[WorkData.message]，并进入异常流[onFailed]。
  /// {@endtemplate}
  @protected
  String? onNetworkError(WorkData<D> data) =>
      data.workConfig.delegate.onNetworkError(data);

  /// {@template work.work_core.Work.onNetworkRequestFailed}
  /// 网络连接建立成功，但是响应失败时调用
  ///
  /// [data]为本次任务执行周期中的数据包装类
  ///
  /// 即响应码不是200，如4xx，5xx，
  /// 返回网络请求失败时的消息，将会设置给[WorkData.message]，并进入异常流[onFailed]。
  ///
  /// [WorkData.errorType]将会为[WorkErrorType.response]。
  /// {@endtemplate}
  @protected
  String? onNetworkRequestFailed(WorkData<D> data) =>
      data.workConfig.delegate.onNetworkRequestFailed(data);

  /// {@template work.work_core.Work.onRequestFailedMessage}
  /// 提取或设置任务失败消息
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 其中包含Http响应结果[WorkData.response]，同时有[onRequestFailed]返回的结果数据[WorkData.result]。
  ///
  /// 在任务执行失败后调用，即[onRequestResult]返回值为false时被调用。
  /// 返回任务执行失败时的消息，将会设置给[WorkData.message]。
  /// {@endtemplate}
  String? onRequestFailedMessage(WorkData<D> data) =>
      data.workConfig.delegate.onRequestFailedMessage(data);

  /// {@template work.work_core.Work.onParseFailed}
  /// 服务器响应数据解析失败后调用
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 其中包含Http响应结果[WorkData.response]，可能有[WorkData.result]（由执行到的生命周期决定）。
  ///
  /// * 通常是在处理或读取[WorkData.response]时抛出异常导致的。
  /// 即在[onRequestResult]，[onRequestSuccessful]，[onRequestSuccessfulMessage]，
  /// [onRequestFailed]，[onRequestFailedMessage]等生命周期中抛出了异常。
  ///
  /// 返回响应数据解析失败时的消息，将会设置给[WorkData.message]，并进入异常流[onFailed]。
  /// {@endtemplate}
  @protected
  String? onParseFailed(WorkData<D> data) =>
      data.workConfig.delegate.onParseFailed(data);

  /// {@template work.work_core.Work.onMaxRestart}
  /// 最大重启次数
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 当[onSuccessful],[onFailed],[onCanceled],[onFinished]中有返回true时将丢弃本次结果重新执行[start]，
  /// 但是通常重启不能无限执行，除了逻辑中断外还可以在这里设置最大重启次数，本次数不包含首次执行。
  ///
  /// * 此处的重启不同于[start]中的`retry`参数，两者互不干扰同时生效。
  /// * `retry`参数仅表示最终网络请求的重试次数，重试期间不会执行其它work的生命周期函数。
  /// * 此处的重启表示work本身的重新启动，每次重启与首次执行[start]方法的参数和流程相同。
  /// {@endtemplate}
  @protected
  int onMaxRestart(WorkData<D> data) =>
      data.workConfig.delegate.onMaxRestart(data);

  /// {@template work.work_core.Work.onStarted}
  /// 网络请求执行前调用
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 可以用于做一些前置操作，比如初始化资源，操作记录，统计等。
  /// {@endtemplate}
  @protected
  FutureOr<void> onStarted(WorkData<D> data) =>
      data.workConfig.delegate.onStarted(data);

  /// 是否命中了缓存
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 此生命周期紧跟在[onStarted]之后执行
  ///
  /// 如果在此处返回true，则会认为本任务需要从缓存读加载结果，
  /// 后续的网络请求将不会被执行，而是进入[onFromCache]和[onFromCacheMessage]生命周期。
  /// 任务将会返回成功即[WorkData.success]为true，
  /// 并跳过生命周期[onSuccessful]直接进入[onFinished]。
  ///
  /// 如果不需要加载缓存，返回false即可（默认值）
  @protected
  FutureOr<bool> onHitCache(WorkData<D> data) => false;

  /// 从缓存加载结果数据
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 当[onHitCache]返回true时会进入该生命周期进行缓存数据加载。
  @protected
  FutureOr<D?> onFromCache(WorkData<D> data) => null;

  /// 从本地缓存加载数据时的结果消息
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 在[onHitCache]返回true时，设置给[WorkData.message]的值
  @protected
  String? onFromCacheMessage(WorkData<D> data) => null;

  /// {@template work.work_core.Work.onSuccessful}
  /// 本次任务执行成功后调用
  ///
  /// [data]为本次任务执行周期中的数据包装类
  /// 其中包含Http响应结果[WorkData.response]，同时有[onRequestSuccessful]返回的结果数据[WorkData.result]，
  /// [onRequestSuccessfulMessage]设置的[WorkData.message]。
  ///
  /// * 在任务成功即[onRequestResult]返回true，[onRequestSuccessful]和[onRequestSuccessfulMessage]正常执行后执行。
  /// * 该方法在[onFinished]之前被调用。
  /// * 如果任务被[onStarted]拦截，则此方法不会被调用。
  /// * 此方法一定是从服务器获取了正确的数据后才执行，是个保存缓存的好地方。
  /// * 此方法不允许抛出异常，如果存在危险操作，请自行处理异常。
  ///
  /// * 返回值为是否重新执行本次请求，如果为true，则本次请求结果将不会从[start]调用点处返回，而是丢弃本次结果然后重新执行[start]方法后在调用点处返回。
  /// * 当返回true时要注意避免进入无限重请求循环，[onMaxRestart]可以限制最大重试次数。
  ///
  /// * 此处的重启不同于[start]中的`retry`参数，两者互不干扰同时生效。
  /// * `retry`参数仅表示最终网络请求的重试次数，重试期间不会执行其它work的生命周期函数。
  /// * 此处的重启表示work本身的重新启动，每次重启与首次执行[start]方法的参数和流程相同。
  /// {@endtemplate}
  @protected
  FutureOr<bool> onSuccessful(WorkData<D> data) =>
      data.workConfig.delegate.onSuccessful(data);

  /// {@template work.work_core.Work.onFailed}
  /// 本次任务执行失败后调用
  ///
  /// [data]为本次任务执行周期中的数据包装类
  ///
  /// * 在任务执行中遇到异常或请求及处理失败时会进入异常流并执行此方法。
  /// * 该方法在[onFinished]之前被调用。
  /// * 该方法与[onCanceled]互斥，即如果任务因为用户主动取消而中断则不会进入该方法。
  ///
  /// * 返回值为是否重新执行本次请求，如果为true，则本次请求结果将不会从[start]调用点处返回，而是丢弃本次结果然后重新执行[start]方法后在调用点处返回。
  /// * 当返回true时要注意避免进入无限重请求循环，[onMaxRestart]可以限制最大重试次数。
  ///
  /// * 此处的重启不同于[start]中的`retry`参数，两者互不干扰同时生效。
  /// * `retry`参数仅表示最终网络请求的重试次数，重试期间不会执行其它work的生命周期函数。
  /// * 此处的重启表示work本身的重新启动，每次重启与首次执行[start]方法的参数和流程相同。
  /// {@endtemplate}
  @protected
  FutureOr<bool> onFailed(WorkData<D> data) =>
      data.workConfig.delegate.onFailed(data);

  /// {@template work.work_core.Work.onCanceled}
  /// 任务被取消时调用
  ///
  /// [data]为本次任务执行周期中的数据包装类
  ///
  /// * 在任务被取消后执行，即用户调用了[WorkFuture.cancel]。
  /// * 该方法在[onFinished]之前被调用。
  /// * 该方法与[onFailed]互斥。
  ///
  /// * 返回值为是否重新执行本次请求，如果为true，则本次请求结果将不会从[start]调用点处返回，而是丢弃本次结果然后重新执行[start]方法后在调用点处返回。
  /// * 当返回true时要注意避免进入无限重请求循环，[onMaxRestart]可以限制最大重试次数。
  ///
  /// * 此处的重启不同于[start]中的`retry`参数，两者互不干扰同时生效。
  /// * `retry`参数仅表示最终网络请求的重试次数，重试期间不会执行其它work的生命周期函数。
  /// * 此处的重启表示work本身的重新启动，每次重启与首次执行[start]方法的参数和流程相同。
  /// {@endtemplate}
  @protected
  FutureOr<bool> onCanceled(WorkData<D> data) =>
      data.workConfig.delegate.onCanceled(data);

  /// {@template work.work_core.Work.onFinished}
  /// 最后执行的一个方法
  ///
  /// [data]为本次任务执行周期中的数据包装类
  ///
  /// 总是会执行
  ///
  /// * 返回值为是否重新执行本次请求，如果为true，则本次请求结果将不会从[start]调用点处返回，而是丢弃本次结果然后重新执行[start]方法后在调用点处返回。
  /// * 当返回true时要注意避免进入无限重请求循环，[onMaxRestart]可以限制最大重试次数。
  ///
  /// * 此处的重启不同于[start]中的`retry`参数，两者互不干扰同时生效。
  /// * `retry`参数仅表示最终网络请求的重试次数，重试期间不会执行其它work的生命周期函数。
  /// * 此处的重启表示work本身的重新启动，每次重启与首次执行[start]方法的参数和流程相同。
  /// {@endtemplate}
  @protected
  FutureOr<bool> onFinished(WorkData<D> data) =>
      data.workConfig.delegate.onFinished(data);
}
