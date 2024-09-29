# work

[![pub package](https://img.shields.io/pub/v/work.svg)](https://pub.dartlang.org/packages/work)

* 封装http业务接口协议，基于[dio](https://pub.dartlang.org/packages/dio) 实现。
* 提供标准且一致的接口编写与执行流程，与公司http规范紧密结合，规范团队成员接口编写和使用方式。
* 核心设计理念为封装http接口的请求数据和响应数据的序列化和反序列化，接口调用处不能出现任何解析http数据的代码。
* 装配和解析代码应该全部由`Work`类完成，接口调用处使用一致的调用方式，无需关心http的实现方式和接口参数拼装细节，
* 此设计隐藏了一些不常用的[dio](https://pub.dartlang.org/packages/dio) 功能，如需使用需要单独实现装配器
* 此设计的优点是规范团队接口编写方式，统一项目http接口代码风格。

## Install

```yaml
work: ^7.0.0
```

## 简单的Get请求实现

```dart
class GetWork extends Work<String> {
  const GetWork(this.name, this.age);

  final String name;

  final int age;

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl(WorkData<String> data) => '/get';
}
```

## 简单的Post请求

```dart
class PostJsonWork extends Work<String> {
  const PostJsonWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod(WorkData<String> data) => HttpMethod.post;

  // 此处用于覆盖提交数据的类型，当接口类型与[WorkConfig.dio.options.contentType]不一致时需要实现此覆盖
  @override
  String? onContentType(WorkData<String> data) => 'application/json';

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
    'name': name,
    'age': age,
  };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['json'].toString();

  @override
  String onUrl(WorkData<String> data) => '/post';
}
```

## 调用接口

```dart
final work = await const GetWork('超悟空', 32).start();

print('work result ${work.result} message ${work.message}');
```

## 全局设置和通用处理逻辑实现

`workConfig`是默认的全局配置，可以在此处设置全局的`dio`配置，也可以在此处设置全局的请求处理逻辑`WorkDelegate`。

## 处理公司专用响应协议

所有请求和响应数据都在`WorkData`中，可以扩展`WorkData`以添加自定义只读属性方便使用。也可以利用`WorkData.extra`实现写属性扩展。

假设公司的所有接口响应数据格式如下：

```
{
  "errorCode": 0, // 错误码
  "message": null, // 业务消息字符串，可以是成功时用于显示的信息，也可以是失败时的提示信息
  "result": any  // 真正响应的有效业务数据，任意类型
}
```

我们可以实现一个扩展方便读取响应参数

```dart
extension WorkDataExtension<T> on WorkData<T> {
  /// 协议错误码
  int get errorCode => response?.data['errorCode'] ?? 0;

  /// 原始响应结果数据
  dynamic get resultData => response?.data['result'];
  
  // WorkData中本来就有message字段
}
```

实现一个`WorkDelegate`用于统一处理公司专用协议

```dart
class WorkDelegateImp extends WorkDelegate {
  @override
  bool onRequestResult(WorkData data) => data.errorCode == 0;

  @override
  String? onParamsError(WorkData data) => '参数不合法';

  @override
  String onNetworkError(data) => '网络连接失败，当前网络不可用';

  @override
  String onNetworkRequestFailed(data) => '请求失败，服务器异常';

  @override
  String onParseFailed(data) => '请求失败，服务器异常';

  @override
  String onRequestFailedMessage(data) =>
      data.response!.data['message'] ?? '操作失败';

  @override
  String onRequestSuccessfulMessage(data) =>
      data.response!.data['message'] ?? '操作成功';
}

void main() {
  workConfig = WorkConfig(
    dio: Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/x-www-form-urlencoded',
        baseUrl: 'http://httpbin.org/',
      ),
    ),
    delegate: WorkDelegateImp(),
  );
}
```

## 支持请求类型

* `HttpMethod`中的类型，`get`、`post`、`put`、`delete`、`head`、`patch`。
* 上传文件时请实现`Work.onContentType`并设置为`multipart/form-data`，参数中的文件需要用`File`或`UploadFileInfo`类型包装，支持文件列表
* 下载文件时可以自己处理字节流，需要实现`Work.onResponseType`并指定自己需要的响应格式，也可以参考`DownloadWork`实现一个快捷下载类，此方式使用`dio.download`下载。

## 其他

* `Work`中还有很多生命周期方法，用于做有限的接口扩展和定制
* 原则是接口数据处理由接口自己(即`Work`)处理
* 更多具体用法如上传下载等可以参考[测试用例](https://github.com/cwkProject/work/blob/master/example/test/test_works.dart)
