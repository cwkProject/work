// Created by 超悟空 on 2021/5/7.

import 'package:flutter_test/flutter_test.dart';
import 'package:work/work.dart';

void main() async {
  test('get',() async{
    final data = await TestWork().start(['超悟空',32]);

    if (data.success) {
      print(data.result);
    } else {
      print(data.message);
    }
  });
}

class TestWork extends Work<String, WorkData<String>> {

  @override
  bool onResponseResult(data) => data.response!.data.containsKey('args');

  @override
  WorkData<String> onCreateWorkData() => WorkData();

  @override
  String? onResponseSuccess(WorkData<String> data) => data.response!.data['args'].toString();

  @override
  String onUrl(List params) => 'http://httpbin.org/get';

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data['name'] = params[0];
    data['age'] = params[1];
  }

  @override
  String onNetworkError(data) => '网络连接失败，当前网络不可用';

  @override
  String onNetworkRequestFailed(data) => '请求失败，服务器异常';

  @override
  String onParseFailed(data) => '请求失败，服务器异常';

  @override
  String onRequestFailedMessage(data) => data.response?.data?['message'] ?? '操作失败';

  @override
  String onRequestSuccessMessage(data) => data.response?.data?['message'] ?? '';
}
