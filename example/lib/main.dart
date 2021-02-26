import 'package:work/work.dart';
import 'package:json_annotation/json_annotation.dart';

part 'main.g.dart';

void main() async {
  final data = await TestWork('xxx').start();

  if (data.success) {
    print(data.result);
  } else {
    print(data.message);
    print(data.errorCode);
  }

  final download = await DownloadWork(
    path: 'file:/xxx/test.jpg',
    key: 'key',
    resNo: 123,
  ).start();

  if (download.success) {
    // show('file:/xxx/test.jpg')
  }
}

class TestWork extends SimpleWork<String> {
  TestWork(this.param1);

  /// 请求参数1
  final String param1;

  @override
  String onExtractResult(resultData, data) => resultData['account'];

  @override
  String onUrl() => 'https://api.example.com/test';

  @override
  Map<String, dynamic> onFillParams() => {'param1': param1};

  @override
  String onNetworkError(data) => '网络连接失败，当前网络不可用';

  @override
  String onNetworkRequestFailed(data) => '请求失败，服务器异常';

  @override
  String onParseFailed(data) => '请求失败，服务器异常';

  @override
  String onRequestFailedMessage(data) => data.response.data['message'] ?? '操作失败';

  @override
  String onRequestSuccessMessage(data) => data.response.data['message'] ?? '';
}

@JsonSerializable()
class DownloadWork extends SimpleDownloadWork {
  DownloadWork({this.path, this.key, this.resNo});

  /// 存放路径
  @JsonKey(ignore: true)
  final String path;

  /// 请求参数key
  final String key;

  /// 请求参数resNo
  final int resNo;

  @override
  Map<String, dynamic> onFillParams() => _$DownloadWorkToJson(this);

  @override
  String onDownloadPath() => path;

  @override
  String onUrl() => 'https://api.example.com/test.jpg';
}

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
  // 地址可以是完整地址，支持baseUrl，需调用[mergeBaseOptions]设置

  @override
  HttpMethod onHttpMethod() => HttpMethod.post; // 使用post请求
}