# work

[![pub package](https://img.shields.io/pub/v/work.svg)](https://pub.dartlang.org/packages/work)

* 封装http业务接口协议，提供有限的扩展功能，隔离http底层实现方法(当前基于dio)，与公司http规范紧密结合，规范团队成员接口编写和使用方式。
* 核心设计理念为封装http接口的请求数据和响应数据的序列化和反序列化，接口调用处不能出现任何解析http数据的代码。
装配和解析代码应该全部由`Work`类完成，接口调用处使用一致的调用方式，无需关心http的实现方式和接口参数拼装细节，
* 此设计的缺点是丢弃了一些不常用的http底层实现工具的灵活扩展功能，
优点是规范团队接口编写方式，统一项目http接口代码风格。

## 与1.0.0以下版本不兼容

## Usage
* [添加 `work` 到 pubspec.yaml 文件](https://flutter.io/platform-plugins/).
* `import 'package:work/work.dart';`

## 实现公司http规范基类

模仿`simple_work.dart`中的样板来实现一个`Work`基类，用于关联自己公司的固定接口规范。

`SimpleWork`类为一个样例实现，所使用的公司接口规范如下

所有接口响应数据格式
```
{
  "state":true, // 业务的成功失败标志
  "errorCode":0, // 错误码
  "message":null, // 业务消息字符串，可以是成功时用于显示的信息，也可以是失败时的提示信息
  "result": {}  // 真正响应的有效业务数据，任意类型
}
```

## 增加接口

继承公司http规范基类，比如`SimpleWork<T>`。

`<T>`为真正需要返回的数据模型类

1.0.0版开始数据填充接口`onFillParams`签名变更，使用更加友好，同时更方便与[json_serializable](https://pub.dev/packages/json_serializable) 库结合使用

示例

```

@JsonSerializable()
class LoginWork extends SimpleWork<User> {
  LoginWork({this.username, this.password});
  
  final String username;
  
  final String password;

  String get device => Platform.isIOS ? "Ios" : "Android";
  
  @override
  User onExtractResult(resultData,SimpleWorkData<User> data) => User.fromJson(resultData);
  // 解析响应数据

  /// 装配请求参数
  /// 
  /// 返回发送的参数集合，可以和[json_serializable]库配合使用，也可以简单的直接拼装
  @override
  Map<String, dynamic> onFillParams() => _$LoginWorkToJson(this);

  // 简单的参数直接拼接
  // @override
  // Map<String, dynamic> onFillParams() => {
  //  'username': username,
  //  'password': password,
  //  'device': device,
  // };
  //

  @override
  String onUrl() => "https://xxx/user/login";
  // 地址可以是完整地址，支持baseUrl，需在[workConfig]中设置dio属性

  @override
  HttpMethod onHttpMethod() => HttpMethod.post; // 使用post请求
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

* `HttpMethod`中的类型，`get`、`post`、`put`、`delete`、`head`、`patch`、`upload`、`download`。
* 其中`upload` 基于`post` 的 `multipart/form-data`实现，参数中的文件需要用`File`或`UploadFileInfo`类型包装，支持文件列表
* `download`默认使用`get`请求，且由于`download`特殊性，需要使用独立于其他`Work`的实现方式，参考`SimpleDownloadWork`。

## 其他Work生命周期函数

`Work`中还有很多生命周期方法，用于做有限的接口扩展和定制，原则是接口数据处理由接口自己(即`Work`)处理。
