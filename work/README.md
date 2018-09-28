# work

[![pub package](https://img.shields.io/pub/v/work.svg)](https://pub.dartlang.org/packages/work)

* 封装http业务接口协议，提供有限的扩展功能，隔离http底层实现方法，与公司http规范紧密结合，规范团队成员接口编写和使用方式。
* 核心设计理念为封装http接口的请求数据和响应数据的序列化和反序列化，接口调用处不能出现任何解析http数据的代码。
装配和解析代码应该全部由`Work`类完成，接口调用处使用一致的调用方式，无需关心http的实现方式和接口参数名称和类型，
仅仅需要注意参数顺序和实现的`Work`类保持一致。
* 此设计的缺点是丢弃了一些不常用的http底层实现工具的灵活扩展功能，
优点是规范团队接口编写方式，统一项目http接口代码风格。

## Usage
* 添加 `work` 到 [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).
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

示例

```

class LoginWork extends SimpleWork<User> {
  @override
  User onExtractResult(resultData) => User.fromJson(resultData);
  // 解析响应数据

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    // 装配请求参数，data为最终要发送的参数集合，params为[Work]调用处端传入的参数列表
    data["username"] = params[0]
      ..["password"] = params[1]
      ..["device"] = Platform.isIOS ? "Ios" : "Android";
  }

  @override
  String onUrl(List params) => "https://xxx/user/login";  
  // 地址必须为完整地址，没有baseUrl支持，项目代码必须集中拼接和管理所有接口地址，便于维护和查找

  @override
  HttpMethod get httpMethod => HttpMethod.post; // 使用post请求
}

```

## 调用接口

```

LoginWork().start(["user1","123456"]).then((data){
   // start方法返回Future<T> ，T为[SimpleWorkData]类

   if (data.success){
      // 登录成功
      final user = data.result;
   }else{
      // 登录失败
   }
});

```

## 其他Work生命周期函数

`Work`中还有很多生命周期方法，用于做有限的接口扩展和定制，原则是接口数据处理由接口自己(即`Work`)处理。
