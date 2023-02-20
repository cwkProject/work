## [4.0.0] - 2023/1/13

* BREAKING: 升级dio到5.0.0
* BREAKING: `onSuccessful`,`onFailed`,`onCanceled`,`onFinished`增加布尔返回值，默认返回false，当它返回true时将阻止本次执行结果返回并重新启动任务
* 增加`onMaxRestart`生命周期方法，表示上述重启任务的最大次数
* BREAKING: 移除`WorkRequestOptions`中的部分参数，转移到`WorkRequestOptions.dioOptions`中

## [3.3.3] - 2023/1/13

* `UploadFileInfo.bytes`和`UploadFileInfo.stream`默认会依赖传入的`fileName`参数读取`mimeType`;
* `WorkFuture.resultOrThrow`和`WorkFuture.resultOrThrowMessage`增加可选参数`onDo`;

## [3.3.2] - 2022/12/14

* 降级`path`依赖库到1.8.2

## [3.3.1] - 2022/12/14

* 在`WorkFuture`中增加`resultOrThrow`，`resultOrThrowMessage`，`result`，`success`，`message`等实用方法

## [3.3.0] - 2022/8/23

* 增加`onQueryParams`生命周期方法，用于在`POST`,`PUT`,`PATCH`,`DELETE`请求中为url追加查询参数

## [3.2.2] - 2022/6/6

* 格式化代码，补充文档

## [3.2.1] - 2022/6/6

* 优化错误输出，现在关键的解析错误可以输出错误堆栈信息

## [3.2.0] - 2022/5/19

* 在`WorkFuture`中增加若干实用方法

## [3.1.1] - 2022/5/18

* 修复`onParseFailed`生命周期在`onRequestFailed`情况下也触发的bug

## [3.1.0] - 2021/8/4

* 在任务失败时打印原始异常信息

## [3.0.0] - 2021/5/10

* BREAKING: 彻底重构执行流程和依赖关系，与2.0以下不兼容
* 重构并简化内核执行流程
* 生命周期和部分参数依赖dio库，不再使用分离http实现库的模式
* 变更部分生命周期名称

## [2.0.3] - 2021/5/7

* 修复bug

## [2.0.2] - 2021/4/12

* 简化流程
* BREAKING: 移除`onCheckResponse`生命周期
* BREAKING: 变更部分生命周期签名，返回移除`FeatureOr`支持
* BREAKING: `WorkData`移除`work`属性
* BREAKING: 从库中移除`SimpleWork`示例，移动到`example`中

## [2.0.1] - 2021/4/7

* BREAKING: `work_config.dart`重构，将`dio`与`workRequest`封装到`WorkConfig`中
* BREAKING: 移除`dio`与`workRequest`，请使用`workConfig`
* BREAKING: 移除`dioMap`，请使用`workConfigs`
* BREAKING: 移除`mergeBaseOptions`方法，请直接对`Dio`对象修改赋值
* BREAKING: 移除`formDataContentType`，请使用`formData`
* BREAKING: `Work.onClientKey`重命名为`Work.onConfigKey`
* BREAKING: `Work.onWorkRequest`增加请求参数`Options`
* BREAKING: 移除`Response.receiveByteCount`字段支持
* 增加`HttpMethod.patch`请求类型
* 修改`HttpMethod.download`请求类型时参数传递由查询参数赋值

## [2.0.0] - 2021/3/29

* 升级到稳定版
* 优化代码结构

## [2.0.0-beta2] - 2021/3/24

* 移除原`Communication`类，变更为方法模板，现在允许在`work_config.dart`中覆盖全局请求实现，即`workRequest`。
* 修改`Work`流程模型，允许同一个实例发起多次并发请求。
* 修改`Work`取消模型，现在调用`Work.start`后将返回`WorkFuture`类，可用于取消本次请求。

## [2.0.0-beta] - 2021/3/4

* 支持空安全
* 等待[dio](https://pub.dev/packages/dio) 4.0就绪

## [1.0.0] - 2021/2/26

* BREAKING: 与1.0.0以下版本不兼容
* BREAKING: 重构了`work`核心流程，`Work`实例改为由用户定义构造函数参数的方式来传入请求参数，`start`函数不再需要传递参数
* BREAKING: 同一个`work`实例不再支持重复发送请求，多次请求请创建新的`Work`实例
* BREAKING: 参数填充生命周期方法`onFillParams`和`onPreFillParams`
  签名变更，方便支持与[json_serializable](https://pub.dev/packages/json_serializable) 库协作填充参数
* BREAKING: 为了兼容[json_serializable](https://pub.dev/packages/json_serializable) 库，原`httpMethod`
  方法更名为`onHttpMethod`
* BREAKING: 全生命周期函数移除`params`传入参数，新版中`Work`的请求参数请在具体的接口实现类中声明类属性的方式实现
* 支持复数的自定义全局`dio`网络客户端实例，通过`Work`复写`onClientKey`来指定

## [0.6.0] - 2021/2/26

* 修复`CancelToken`导致的`Stream`未关闭问题

## [0.5.9] - 2021/1/12

* code format

## [0.5.8] - 2021/1/12

* 修复日志类型转换中的错误

## [0.5.7] - 2021/1/12

* 优化结果log打印逻辑，二进制类型的body不再全部打印，仅打印字节流长度

## [0.5.6] - 2021/1/11

* 增加flutter环境依赖，将日志输出从`print`重定向到`debugPrint`

## [0.5.5] - 2020/8/28

* 修复`Work`子类中重设`Options.connectTimeout`没有生效的bug

## [0.5.4] - 2020/8/11

* 标准格式化代码
* 增加版权声明

## [0.5.3] - 2020/8/11

* 使用`pedantic`进行静态分析以符合dart语法规范

## [0.5.2] - 2020/8/3

* 个别变量声明方式改为字面量，核心类处理`FutureOr`性能优化

## [0.5.1] - 2020/7/10

* 增加对`multipart/form-data`请求的自动装配

## [0.5.0] - 2020/7/4

* 修改`UploadFileInfo`增加直接上传字节流的能力，修改`_dio_request.dart`实现，分离convert以支持web

## [0.4.8] - 2020/7/3

* 调整请求和响应数据log输出缩进

## [0.4.7] - 2020/7/2

* 修复log输出遗漏错误

## [0.4.6] - 2020/6/29

* 修复批量文件上传转换错误，打印输出遗漏错误

## [0.4.5] - 2020/6/16

* 增加英文描述，增加example

## [0.4.4] - 2020/6/16

* 修复网址合法性检查中对`baseUrl`的判断错误

## [0.4.3] - 2020/6/15

* 开放对`baseUrl`的支持，需要调用`work_config.dart`中的`mergeBaseOptions`设置

## [0.4.2] - 2020/2/28

* 细化响应错误类型，增加响应数据解析错误和任务执行错误(应用业务逻辑失败)

## [0.4.1] - 2019/11/18

* 设置默认发送超时30秒，默认连接超时为10秒

## [0.4.0] - 2019/11/1

* 大幅度修改work的核心生命周期函数的参数，`WorkData`作为生命周期核心的传递句柄
* 将`Options`和`Response`存入`WorkData`传递
* 在`WorkData`中增加`extra`字段
* 在`Response`中增加请求错误类型`errorType`和接收数据总量`receiveByteCount`

## [0.3.3] - 2019/10/21

* 修复数据解析失败任然返回请求成功的bug

## [0.3.2] - 2019/10/18

* 修复上传文件的bug

## [0.3.1] - 2019/10/10

* 增加`ResponseType.bytes`支持，以接收原始字节流的响应数据

## [0.3.0] - 2019/10/9

* 更新dio库到3.0.0版本

## [0.2.9] - 2019/9/18

* 移除`sendTimeout`默认值

## [0.2.8] - 2019/9/18

* 修复headers赋值方式导致的bug

## [0.2.7] - 2019/9/18

* 修复headers赋值顺序导致的参数覆盖bug
* `Options`增加`sendTimeout`属性

## [0.2.6] - 2019/9/18

* 调整实现细节以支持dio v2.2.1 的api变更，`Options.contentType`替换为String类型

## [0.2.5] - 2019/9/2

* 将work中的生命周期函数返回值变更为`FutureOr`以支持异步操作
* 将`onStartWork`和`onStopWork`生命周期变为私有函数，禁止重写
* 替换部分`Null`泛型为`void`

## [0.2.4] - 2019/6/14

* 修复get请求参数转换错误

## [0.2.3] - 2019/5/31

* 将底层请求参数类型改为`dynamic`类型以便支持更加多请求参数格式 默认继续以`Map`为主要参数类型集合，如需使用其他数据结构，请实现`onPostFillParams`方法

## [0.2.2] - 2019/2/14

* 修复dio 2.0.4 接口变化导致的bug

## [0.2.1] - 2019/2/1

* 修复dio 2.0.0 接口变化导致的bug

## [0.2.0] - 2019/2/1

* 修复dio 2.0.0 接口变化导致的bug

## [0.1.9] - 2019/2/1

* 升级dio到2.0.0

## [0.1.8] - 2019/1/31

* 回滚meta库依赖到1.1.6

## [0.1.7] - 2019/1/30

* 升级dio到1.0.14，增加上传/发送进度监听支持

## [0.1.6] - 2018/11/12

* 延长请求超时时间

## [0.1.5] - 2018/11/7

* 修改log输出位置

## [0.1.4] - 2018/11/7

* 增加请求参数忽略null值的处理

## [0.1.3] - 2018/10/18

* 修复`SimpleWork`中`onExtractResult`，`onDefaultResult`丢失`data`参数的问题

## [0.1.2] - 2018/10/8

* 增加输出日志的tag

## [0.1.1] - 2018/9/28

* 增加上传请求对`File`类型的支持

## [0.1.0] - 2018/9/26

* 首次完成提交
