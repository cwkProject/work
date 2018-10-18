// Created by 超悟空 on 2018/9/26.
// Version 1.0 2018/9/26
// Since 1.0 2018/9/26
import 'package:work/work.dart';

class LoginWork extends SimpleWork {
  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data
      ..["mobileNum"] = params[0]
      ..["token"] = params[1]
      ..["deviceDesc"] = "Android";
  }

  @override
  String onUrl(List params) => "https://office.efaceboard"
      ".cn:4443/MeetingServer/user/mobileNumLogin";

  @override
  HttpMethod get httpMethod => HttpMethod.post;

  @override
  onExtractResult(resultData, SimpleWorkData data) {

  }
}
