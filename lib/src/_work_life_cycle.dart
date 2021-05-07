// Created by 超悟空 on 2021/5/7.

part of 'work_core.dart';

/// 任务流程的生命周期接口
///
/// [D]为关联的接口结果数据类型，[T]为接口响应包装类型[WorkData]
abstract class WorkLifeCycle<D, T extends WorkData<D>> {
  /// 启动任务
  ///
  /// 返回包含执行结果[T]的[WorkFuture]。
  /// * [retry]为请求失败重试次数，0表示不重试，实际请求1次，1表示重试1次，实际最多请求两次，以此类推
  /// * [onSendProgress]为数据发送进度监听器，[onReceiveProgress]为数据接收进度监听器，
  /// 在[HttpMethod.download]请求中为下载进度，在其他类型请求中为上传/发送进度。
  /// * 多次调用会启动多次请求
  WorkFuture<D, T> start({
    int retry = 0,
    OnProgress? onSendProgress,
    OnProgress? onReceiveProgress,
  });

  /// 创建数据模型对象的实例
  @protected
  T onCreateWorkData();

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
  String? onParamsError() => null;

  /// 返回请求实现方法
  ///
  /// 默认实现为[workRequest]
  /// 如果要覆盖全局实现，请覆盖[workRequest]
  /// 如果仅覆盖本任务请重写此方法
  @protected
  WorkRequest onWorkRequest(Options options) =>
      (workConfigs[options.configKey] ?? workConfig).workRequest;

  /// 网络请求方法
  @protected
  HttpMethod onHttpMethod() => HttpMethod.get;

  /// 网络请求的Content-Type
  ///
  /// 默认使用[WorkConfig]中的配置
  @protected
  String? onContentType() => null;

  /// 网络请求地址
  ///
  /// 可以是完整地址，也可以是相对地址（需要设置baseUrl，关联性请查看[work_config.dart]）
  @protected
  String onUrl();

  /// 用于指定全局网络客户端配置的key
  ///
  /// 返回null或key不存在则表示使用默认客户端配置
  /// 关联性请查看[workConfigs]
  @protected
  String? onConfigKey() => null;

  /// 创建并填充请求头
  @protected
  FutureOr<Map<String, dynamic>?> onHeaders() => null;

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
  FutureOr<Map<String, dynamic>?> onPreFillParams() => null;

  /// 填充请求所需的参数
  ///
  /// * 返回填充的参数对，没有返回null或空对象
  /// * 返回的参数最终会和[onPreFillParams]中返回的参数合并，且可以覆盖[onPreFillParams]中的同名参数
  @protected
  FutureOr<Map<String, dynamic>?> onFillParams();

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
  String? onParseFailed(T data) => null;

  /// 网络连接建立成功，但是请求失败时调用
  ///
  /// 即响应码不是200，如4xx，5xx，返回网络请求失败时的消息，即[WorkData.message]字段
  @protected
  String? onNetworkRequestFailed(T data) => null;

  /// 网络连接建立失败时调用，即网络不可用
  ///
  /// 返回设置网络无效时的消息，即[WorkData.message]字段
  @protected
  String? onNetworkError(T data) => null;

  /// 提取服务执行结果
  ///
  /// * http响应成功，从接口响应的数据中提取本次业务请求真正的成功或失败结果。
  /// * 通常[data.response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[data.response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[data.response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[data.response]为字符串。
  @protected
  bool onRequestResult(T data);

  /// 提取服务执行成功时返回的真正有用结果数据
  ///
  /// * 在服务请求成功后调用，即[onRequestResult]返回值为true时被调用，
  /// 用于生成请求成功后的任务返回真正结果数据对象[D]。
  /// * 通常[data.response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[data.response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[data.response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[data.response]为字符串。
  @protected
  FutureOr<D?> onRequestSuccess(T data);

  /// 提取或设置服务返回的成功结果消息
  ///
  /// 在服务请求成功后调用，即[onRequestResult]返回值为true时被调用。
  @protected
  String? onRequestSuccessMessage(T data) => null;

  /// 提取或设置服务执行失败时的返回结果数据
  ///
  /// 在服务请求失败后调用，即[onRequestResult]返回值为false时被调用，
  /// 用于生成请求失败后的任务返回真正结果数据对象[D]，可能是一个默认值。
  @protected
  FutureOr<D?> onRequestFailed(T data) => null;

  /// 提取或设置服务返回的失败结果消息
  ///
  /// 在服务请求失败后调用，即[onRequestResult]返回值为false时被调用。
  String? onRequestFailedMessage(T data) => null;

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