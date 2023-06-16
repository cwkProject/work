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
work: ^5.1.0
```

## 实现公司http规范基类

模仿`simple_work.dart`中的样板来实现一个`Work`基类，用于关联自己公司的固定接口规范。

`SimpleWork`类为一个样例实现。

假设公司的所有接口响应数据格式如下：

```协议
{
  "state":true, // 业务的成功失败标志
  "errorCode":0, // 错误码
  "message":null, // 业务消息字符串，可以是成功时用于显示的信息，也可以是失败时的提示信息
  "result": {}  // 真正响应的有效业务数据，任意类型
}
```

首先实现一个带有`errorCode`的`WorkData`子类以匹配上述协议（`WorkData`中已包含另外三个）。

```SimpleWorkData

class SimpleWorkData<T> extends WorkData<T> {
  /// 协议错误码
  int _errorCode = 0;

  /// 协议错误码
  int get errorCode => _errorCode;
}

```

最后实现一个解析此协议的`Work`基类，可以更具自身需要添加如`onExtractResult`和`onDefaultResult`的扩展生命周期。

```SimpleWork

abstract class SimpleWork<D> extends Work<D, SimpleWorkData<D>> {
  /// 用于获取响应json数据协议中"result"字段
  static const String result = 'result';

  @override
  SimpleWorkData<D> onCreateWorkData() => SimpleWorkData<D>();

  @override
  FutureOr<D?> onRequestSuccessful(SimpleWorkData<D> data) {
    if (data.response!.data[result] == null) {
      return onDefaultResult(data);
    } else {
      return onExtractResult(data.response!.data[result], data);
    }
  }

  @override
  bool onRequestResult(SimpleWorkData<D> data) => data.response!.data['state'];

  @mustCallSuper
  @override
  FutureOr<D?> onRequestFailed(SimpleWorkData<D> data) {
    if (data.response!.data['errorCode'] != null) {
      data._errorCode = data.response!.data['errorCode']!;
    }

    return super.onRequestFailed(data);
  }

  @override
  String? onRequestSuccessfulMessage(SimpleWorkData<D> data) =>
      data.response!.data['message'];

  @override
  String? onRequestFailedMessage(SimpleWorkData<D> data) =>
      data.response!.data['message'];

  /// 生成响应成功的结果数据
  ///
  /// * [resultData]为协议中的[result]标签下的数据
  /// * 当请求成功且返回结果中存在[result]标签且不为null时被调用
  /// * 返回装配后的本地数据对象
  /// * [data]为将要返回的数据包装类
  @protected
  FutureOr<D?> onExtractResult(resultData, SimpleWorkData<D> data);

  /// 生成响应成功的默认结果数据
  ///
  /// * 当请求成功且返回结果不存在[result]标签或值为null时被调用，默认实现为null
  /// * [data]为将要返回的数据包装类
  @protected
  FutureOr<D?> onDefaultResult(SimpleWorkData<D> data) => null;
}

```

## 增加接口

继承公司http规范基类，比如`SimpleWork<T>`。

`<T>`为真正需要返回的数据模型类

子类可以方便的与[json_serializable](https://pub.dev/packages/json_serializable) 库结合使用

示例

```

@JsonSerializable()
class LoginWork extends SimpleWork<User> {
  LoginWork({this.username, this.password});
  
  final String username;
  
  final String password;

  String get device => Platform.isIOS ? "Ios" : "Android";
  
  /// 解析响应数据
  @override
  User onExtractResult(resultData,SimpleWorkData<User> data) => User.fromJson(resultData);

  /// 装配请求参数
  /// 
  /// 返回发送的参数集合，可以和[json_serializable]库配合使用，也可以简单的直接拼装
  @override
  Map<String, dynamic> onFillParams() => _$LoginWorkToJson(this);

  // 不使用序列化库，直接拼接
  // @override
  // Map<String, dynamic> onFillParams() => {
  //  'username': username,
  //  'password': password,
  //  'device': device,
  // };
  //

  /// 可以是完整地址，也可以是相对地址（需要在[BaseOptions]中设置，关联性请查看[WorkConfig.dio]）
  @override
  String onUrl() => "https://xxx/user/login";

  /// 使用post请求
  @override
  HttpMethod onHttpMethod() => HttpMethod.post;
}

```

## 调用接口

```

// 创建work实例并执行start发起请求，多次调用start会发起多次请求，
LoginWork(username: 'user1', password: '123456').start().then((data){
   // start方法返回WorkFuture<T> ，T为[SimpleWorkData]类，此WorkFuture可以取消本次work请求

   if (data.success){
      // 登录成功
      final user = data.result;
   }else{
      // 登录失败
   }
});

```

## 支持请求类型

* `HttpMethod`中的类型，`get`、`post`、`put`、`delete`、`head`、`patch`。
* 上传文件时请实现`Work.onContentType`并设置为`multipart/form-data`，参数中的文件需要用`File`或`UploadFileInfo`类型包装，支持文件列表
* 下载文件时可以自己处理字节流，需要实现`Work.onResponseType`并指定自己需要的响应格式，也可以参考`SimpleDownloadWork`实现一个快捷下载类，此方式使用`dio.download`下载。

## 其他Work生命周期函数

* `Work`中还有很多生命周期方法，用于做有限的接口扩展和定制，请参考`work_life_cycle.dart`
* 原则是接口数据处理由接口自己(即`Work`)处理
* `Work`设计的流程能满足绝大多数使用场景，如需深度定制Http请求，可以查看`WorkConfig`用于全局配置，`Work.onWorkRequest`用于定制单一任务
