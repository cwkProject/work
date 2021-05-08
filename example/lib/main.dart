import 'dart:io';

import 'package:work/work.dart';
import 'package:json_annotation/json_annotation.dart';

import 'simple_work.dart';

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

  final upload = await UploadWork(File('test.jpg')).start();

  if (upload.success) {
    print(upload.result);
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
  String onRequestFailedMessage(data) =>
      data.response!.data['message'] ?? '操作失败';

  @override
  String onRequestSuccessfulMessage(data) => data.response!.data['message'] ?? '';
}

@JsonSerializable()
class DownloadWork extends SimpleDownloadWork {
  DownloadWork({required this.path, required this.key, required this.resNo});

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
class UploadWork extends SimpleWork<String> {
  UploadWork(this.file);

  /// 需要上传的文件
  @JsonKey(toJson: workFileToJsonConvert)
  final File file;

  /// 假设返回的结果"result"标签对应的是文件的网络地址
  @override
  String onExtractResult(resultData, data) => resultData;

  @override
  String onUrl() => 'https://api.example.com/upload';

  @override
  Map<String, dynamic> onFillParams() => _$UploadWorkToJson(this);
}
