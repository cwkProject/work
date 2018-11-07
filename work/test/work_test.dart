import 'dart:io';

import 'package:work/work.dart';

void main() async {
  await TestWork().start();
}

class TestWork extends SimpleWork<Null> {
  @override
  Null onExtractResult(resultData, SimpleWorkData<Null> data) {}

  @override
  String onUrl(List params) => "http://192.168.0"
      ".20:8080/MeetingServer/test/postParam";

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["members"] = ["aaa"];
  }

  @override
  HttpMethod get httpMethod => HttpMethod.post;

  @override
  void onConfigOptions(Options options, List params) {
    options.contentType = ContentType.json;
  }
}
