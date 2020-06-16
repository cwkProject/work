import 'package:work/work.dart';

void main() async {
  final data = await TestWork().start(["xxx"]);

  if (data.success) {
    print(data.result);
  } else {
    print(data.message);
    print(data.errorCode);
  }

  final download = await DownloadWork().start([
    'file:/xxx/test.jpg',
    'key',
    123,
  ]);

  if (download.success) {
    // show('file:/xxx/test.jpg')
  }
}

class TestWork extends SimpleWork<String> {
  @override
  String onExtractResult(resultData, data) => resultData['account'];

  @override
  String onUrl(List params) => "https://api.example.com/test";

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["param1"] = params[0];
  }

  @override
  String onNetworkError(data) => '网络连接失败，当前网络不可用';

  @override
  String onNetworkRequestFailed(data) => '请求失败，服务器异常';

  @override
  String onParseFailed(data) => '请求失败，服务器异常';

  @override
  String onRequestFailedMessage(data) =>
      data.response.data['message'] ?? '操作失败';

  @override
  String onRequestSuccessMessage(data) => data.response.data['message'] ?? '';
}

class DownloadWork extends SimpleDownloadWork {
  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["key"] = params[1];
    data["resNo"] = params[2];
  }

  @override
  String onDownloadPath(List params) => params[0];

  @override
  String onUrl(List params) => "https://api.example.com/test.jpg";
}
