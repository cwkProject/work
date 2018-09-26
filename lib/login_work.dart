// Created by 超悟空 on 2018/9/26.
// Version 1.0 2018/9/26
// Since 1.0 2018/9/26
import 'package:work/work.dart';

class LoginWork extends SimpleWork<Null> {
  @override
  Null onExtractResult(resultData) => null;

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["mobileNum"] = params[0];
    data["token"] = params[1];
    data["deviceDesc"] = "Android";
  }

  @override
  String onUrl(List params) => "https://office.efaceboard"
      ".cn:4443/MeetingServer/user/mobileNumLogin";

  @override
  HttpMethod get httpMethod => HttpMethod.post;
}
