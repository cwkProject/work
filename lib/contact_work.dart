// Created by 超悟空 on 2018/9/28.
// Version 1.0 2018/9/28
// Since 1.0 2018/9/28
import 'package:work/work.dart';

class ContactWork extends SimpleWork<Null>{

  @override
  Null onExtractResult(resultData) {
  }

  @override
  String onUrl(List params) => "https://office.efaceboard"
      ".cn:4443/MeetingServer/department/getDepartment";

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["sessionId"] = "536e2eb1-9616-46d5-a570-f7dadbf8e975";
   data["departmentId"]=211;
  }

  @override
  HttpMethod get httpMethod => HttpMethod.post;
}