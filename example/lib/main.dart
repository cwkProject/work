import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:work/work.dart';

part 'main.g.dart';

void main() async {
  workConfig = WorkConfig(
    dio: Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/x-www-form-urlencoded',
      ),
    ),
    delegate: WorkDelegateImp(),
  );

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

  final upload = await UploadWork(File('test.jpg')).start();

  if (upload.success) {
    print(upload.result);
  }
}

/// 简化的[WorkData]类实现
///
/// 使用特定的公司接口协议描述。
///
/// ``` http协议
/// 所有接口响应数据格式
///
/// json结构
///
/// {
/// "errorCode":0, // 错误码，成功时返回0
/// "message":null, // 业务消息字符串，可以是成功时用于显示的信息，也可以是失败时的提示信息
/// "result": {}  // 真正响应的有效业务数据，任意类型
/// }
///
/// ```
extension WorkDataExtension<T> on WorkData<T> {
  /// 协议错误码
  int get errorCode => response?.data['errorCode'] ?? 0;

  /// 原始响应结果数据
  dynamic get resultData => response?.data['result'];
}

/// 实现通用处理
///
/// ``` http协议
/// 所有接口响应数据格式
///
/// json结构
///
/// {
/// "errorCode":0, // 错误码
/// "message":null, // 业务消息字符串，可以是成功时用于显示的信息，也可以是失败时的提示信息
/// "result": {}  // 真正响应的有效业务数据，任意类型
/// }
///
/// ```
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

class TestWork extends Work<String> {
  const TestWork(this.param1);

  /// 请求参数1
  final String param1;

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'param1': param1,
      };

  @override
  FutureOr<String?> onRequestSuccessful(WorkData<String> data) {
    return data.resultData['account'];
  }

  @override
  String onUrl(WorkData<String> data) => 'https://api.example.com/test';
}

@JsonSerializable()
class DownloadWork extends Work<void> {
  const DownloadWork({
    required this.path,
    required this.key,
    required this.resNo,
  });

  /// 存放路径
  @JsonKey(includeToJson: false)
  final String path;

  /// 请求参数key
  final String key;

  /// 请求参数resNo
  final int resNo;

  @override
  FutureOr<dynamic> onFillParams(WorkData<void> data) =>
      _$DownloadWorkToJson(this);

  @override
  FutureOr<void> onRequestSuccessful(WorkData<void> data) {}

  @override
  FutureOr<void> onPostOptions(WorkData<void> data) {
    data.options!.downloadPath = path;
  }

  @override
  String onRequestFailedMessage(data) => '下载失败';

  @override
  String onRequestSuccessfulMessage(data) => '下载成功';

  @override
  String onUrl(WorkData<void> data) => 'https://api.example.com/test.jpg';
}

@JsonSerializable()
class UploadWork extends Work<String> {
  const UploadWork(this.file);

  /// 需要上传的文件
  @JsonKey(toJson: workFileToJsonConvert)
  final File file;

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) =>
      _$UploadWorkToJson(this);

  @override
  FutureOr<String?> onRequestSuccessful(WorkData<String> data) {
    return data.resultData; // 假设返回的是文件url
  }

  @override
  String onUrl(WorkData<String> data) => 'https://api.example.com/upload';
}
