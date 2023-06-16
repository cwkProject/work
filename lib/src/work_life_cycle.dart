// Created by 超悟空 on 2021/5/7.

part of 'work_core.dart';

/// 任务流程的生命周期接口
///
/// [D]为关联的接口结果数据类型，[T]为接口响应包装类型[WorkData]
@immutable
mixin WorkLifeCycle<D, T extends WorkData<D>> {
  /// 启动任务
  ///
  /// 返回包含执行结果[T]的[WorkFuture]。
  /// * [retry]为内部网络请求失败时的最大重试次数，0表示不重试，实际请求1次，1表示重试1次，实际最多请求两次，以此类推，
  /// * [onSendProgress]为数据发送/上传进度监听器，在[HttpMethod.get]和[HttpMethod.head]中无效，
  /// 以及设置了[WorkRequestOptions.downloadPath]的下载任务中无效，
  /// * [onReceiveProgress]为数据接收/下载进度监听器，
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
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// * 用于检测任务启动所需的参数是否合法，需要子类重写检测规则。
  /// * 检测成功任务才会被正常执行，如果检测失败则[onParamsError]会被调用，
  /// 且后续网络请求任务不再执行，并进入异常流[onFailed]。
  /// * 参数合法返回true，非法返回false。
  @protected
  FutureOr<bool> onCheckParams(T data) => true;

  /// 参数检测不合法时调用
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// * [onCheckParams]返回false时或者url不合法时被调用，且后续网络请求任务不再执行，并进入异常流[onFailed]。
  /// * 返回错误消息内容，将会设置给[WorkData.message]
  @protected
  String? onParamsError(T data) => null;

  /// 返回请求实现方法
  ///
  /// 默认实现为[workRequest]
  /// 如果要覆盖全局实现，请覆盖[WorkConfig.workRequest]
  /// 如果仅覆盖本任务请重写此方法
  @protected
  WorkRequest onWorkRequest(WorkRequestOptions options) =>
      (workConfigs[options.configKey] ?? workConfig).workRequest;

  /// 网络请求方法
  @protected
  HttpMethod onHttpMethod() => HttpMethod.get;

  /// 网络请求body的Content-Type
  ///
  /// 默认使用[WorkConfig]中的配置，
  /// 此值必须与[onFillParams]或[onPostFillParams]返回的参数类型兼容。
  @protected
  String? onContentType() => null;

  /// 网络请求地址
  ///
  /// 可以是完整地址，也可以是相对地址（需要在[BaseOptions]中设置，关联性请查看[WorkConfig.dio]）
  @protected
  String onUrl();

  /// 用于指定全局网络客户端配置的key
  ///
  /// 返回null或key不存在则表示使用默认客户端配置[workConfig]
  /// 关联性请查看[workConfigs]
  @protected
  String? onConfigKey() => null;

  /// 创建并填充请求头
  @protected
  FutureOr<Map<String, dynamic>?> onHeaders() => null;

  /// 表示期望以哪种格式(方式)接受响应数据
  ///
  /// 默认值在[WorkConfig.dio]中设置，dio默认[ResponseType.json]。
  @protected
  ResponseType? onResponseType() => null;

  /// 自定义配置http请求选择项
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// * [options]为请求将要使用的配置选项，修改[options]的属性以定制http行为。
  /// * [options]包含[onHttpMethod]返回的请求方法，
  /// [onContentType]填充的Content-Type
  /// [onPreFillParams]，[onFillParams]以及[onPostFillParams]填充的参数，
  /// [onUrl]返回的请求地址，
  /// [onHeaders]中创建的请求头，
  /// [onResponseType]中返回的响应格式，
  /// [start]传入的[onSendProgress]和[onReceiveProgress]，
  /// [onConfigKey]返回的客户端配置key
  /// 以上属性都可以在这里被覆盖。
  @protected
  FutureOr<void> onConfigOptions(T data, WorkRequestOptions options) {}

  /// 填充请求所需的参数
  ///
  /// * 返回填充的参数对，没有参数时返回null或空对象
  @protected
  FutureOr<Map<String, dynamic>?> onFillParams();

  /// 填充请求所需的后置参数
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// * 适合对参数进行签名（通过项目中实现的定制[Work]基类完成）
  /// * [params]为请求参数集，由[onFillParams]生成
  /// * 可以直接在[params]中增加新参数（比如签名参数），也可以返回新集合
  /// * 不返回参数或返回null则继续使用[params]作为请求参数，也可以直接返回[params]
  /// * 如果需要使用其他数据类型作为请求参数，请返回新的数据集合对象，
  /// 通常有[Map]，[String]，[Stream]等，需要与Content-Type匹配，
  /// 同样可以使用自行拼装的[FormData]数据
  @protected
  FutureOr<dynamic> onPostFillParams(T data, Map<String, dynamic>? params) =>
      null;

  /// 填充请求所需的查询参数
  ///
  /// 通常参数应该在[onFillParams],[onPostFillParams]中填充，
  /// 但是对于"POST","PUT","PATCH","DELETE"请求而言，
  /// 除了请求体"body"中可以传参外也支持在url中传递参数，
  /// 此生命周期方法就是用来辅助上述4类请求传递url中的查询参数所准备的。
  ///
  /// * 由于"GET","HEAD"请求本身并不支持请求体，所以对于这两类请求无需使用此方法。
  /// * 但是如果在"GET","HEAD"请求中通过此方法返回了集合实例，则会覆盖由[onFillParams],[onPostFillParams]生成的参数。
  @protected
  FutureOr<Map<String, dynamic>?> onQueryParams() => null;

  /// 后置填充请求所需的查询参数
  ///
  /// 返回结果为新的参数集合，默认返回[onQueryParams]的返回值
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 在[onQueryParams]填充之后执行的填充方法，[params]为[onQueryParams]的返回值。
  /// 此函数通常用于做参数签名或者追加填充[WorkData.extra]中传递的值。
  @protected
  FutureOr<Map<String, dynamic>?> onPostQueryParams(
          T data, Map<String, dynamic>? params) =>
      params;

  /// 网络请求执行前调用
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 可以用于做一些前置操作，比如初始化资源，操作记录，统计等。
  @protected
  FutureOr<void> onStarted(T data) => null;

  /// 是否命中了缓存
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 此生命周期紧跟在[onStarted]之后执行
  ///
  /// 如果在此处返回true，则会认为本任务需要从缓存读加载结果，
  /// 后续的网络请求将不会被执行，而是进入[onFromCache]和[onFromCacheMessage]生命周期。
  /// 任务将会返回成功即[WorkData.success]为true，
  /// 并跳过生命周期[onSuccessful]直接进入[onFinished]。
  ///
  /// 如果不需要加载缓存，返回false即可（默认值），
  @protected
  FutureOr<bool> onHitCache(T data) => false;

  /// 从缓存加载结果数据
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 当[onHitCache]返回true时会进入该生命周期进行缓存数据加载。
  @protected
  FutureOr<D?> onFromCache(T data) => null;

  /// 从本地缓存加载数据时的结果消息
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 可以获取用户传递的自定义[WorkData.extra]值
  ///
  /// 在[onHitCache]返回true时，设置给[WorkData.message]的值
  @protected
  String? onFromCacheMessage(T data) => null;

  /// 提取任务执行结果
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 其中包含Http响应结果[WorkData.response]。
  ///
  /// 返回true表示任务执行成功。
  /// 返回false表示失败，并进入异常流[onFailed]。
  ///
  /// * http响应成功，从接口响应的数据中提取本次业务请求真正的成功或失败结果。
  /// * 通常[WorkData.response]中的[HttpResponse.data]的类型是[onResponseType]设置或其全局默认值决定的。
  /// 如果为[ResponseType.json]则为[Map]类型数据，
  /// 如果为[ResponseType.stream]则为[Stream]类型数据，
  /// 如果为[ResponseType.plain]则为[String]类型数据，
  /// 如果为[ResponseType.bytes]则为[List<int>]类型数据。
  @protected
  bool onRequestResult(T data);

  /// 提取任务执行成功时返回的真正有用结果数据
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
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
  FutureOr<D?> onRequestSuccessful(T data);

  /// 提取或设置任务成功消息
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 其中包含Http响应结果[WorkData.response]，同时有[onRequestSuccessful]返回的结果数据[WorkData.result]。
  ///
  /// 在任务执行成功后调用，即[onRequestResult]返回值为true时被调用。
  /// 返回的消息会被设置给[WorkData.message]。
  @protected
  String? onRequestSuccessfulMessage(T data) => null;

  /// 网络连接建立失败时调用，即网络不可用或域名不可达，如dns错误等
  ///
  /// 返回网络无效时的消息，将会设置给[WorkData.message]，并进入异常流[onFailed]。
  @protected
  String? onNetworkError(T data) => null;

  /// 网络连接建立成功，但是响应失败时调用
  ///
  /// 即响应码不是200，如4xx，5xx，
  /// 返回网络请求失败时的消息，将会设置给[WorkData.message]，并进入异常流[onFailed]。
  ///
  /// [WorkData.errorType]将会为[WorkErrorType.response]。
  @protected
  String? onNetworkRequestFailed(T data) => null;

  /// 提取或设置任务执行失败时的返回结果数据
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 其中包含Http响应结果[WorkData.response]。
  ///
  /// 在任务执行失败后调用，即[onRequestResult]返回值为false时被调用，
  /// 用于生成请求失败后的任务返回真正结果数据[D]的实例，通常是一个默认值。
  @protected
  FutureOr<D?> onRequestFailed(T data) => null;

  /// 提取或设置任务失败消息
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 其中包含Http响应结果[WorkData.response]，同时有[onRequestFailed]返回的结果数据[WorkData.result]。
  ///
  /// 在任务执行失败后调用，即[onRequestResult]返回值为false时被调用。
  /// 返回任务执行失败时的消息，将会设置给[WorkData.message]。
  String? onRequestFailedMessage(T data) => null;

  /// 服务器响应数据解析失败后调用
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
  /// 其中包含Http响应结果[WorkData.response]，可能有[WorkData.result]（由执行到的生命周期决定）。
  ///
  /// * 通常是在处理或读取[WorkData.response]时抛出异常导致的。
  /// 即在[onRequestResult]，[onRequestSuccessful]，[onRequestSuccessfulMessage]，
  /// [onRequestFailed]，[onRequestFailedMessage]等生命周期中抛出了异常。
  ///
  /// 返回响应数据解析失败时的消息，将会设置给[WorkData.message]，并进入异常流[onFailed]。
  @protected
  String? onParseFailed(T data) => null;

  /// 最大重启次数
  ///
  /// 当[onSuccessful],[onFailed],[onCanceled],[onFinished]中有返回true时将丢弃本次结果重新执行[start]，
  /// 但是通常重启不能无限执行，除了逻辑中断外还可以在这里设置最大重启次数，本次数不包含首次执行。
  ///
  /// * 此处的重启不同于[start]中的`retry`参数，两者互不干扰同时生效。
  /// * `retry`参数仅表示最终网络请求的重试次数，重试期间不会执行其它work的生命周期函数。
  /// * 此处的重启表示work本身的重新启动，每次重启与首次执行[start]方法的参数和流程相同。
  @protected
  int onMaxRestart() => 3;

  /// 本次任务执行成功后调用
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建，
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
  @protected
  FutureOr<bool> onSuccessful(T data) => false;

  /// 本次任务执行失败后调用
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建。
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
  @protected
  FutureOr<bool> onFailed(T data) => false;

  /// 任务被取消时调用
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建。
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
  @protected
  FutureOr<bool> onCanceled(T data) => false;

  /// 最后执行的一个方法
  ///
  /// [data]为本次任务执行周期中的数据包装类，由[onCreateWorkData]创建。
  ///
  /// 总是会执行
  ///
  /// * 返回值为是否重新执行本次请求，如果为true，则本次请求结果将不会从[start]调用点处返回，而是丢弃本次结果然后重新执行[start]方法后在调用点处返回。
  /// * 当返回true时要注意避免进入无限重请求循环，[onMaxRestart]可以限制最大重试次数。
  ///
  /// * 此处的重启不同于[start]中的`retry`参数，两者互不干扰同时生效。
  /// * `retry`参数仅表示最终网络请求的重试次数，重试期间不会执行其它work的生命周期函数。
  /// * 此处的重启表示work本身的重新启动，每次重启与首次执行[start]方法的参数和流程相同。
  @protected
  FutureOr<bool> onFinished(T data) => false;
}
