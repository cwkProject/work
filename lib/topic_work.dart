// Created by 超悟空 on 2018/9/28.
// Version 1.0 2018/9/28
// Since 1.0 2018/9/28
import 'package:work/work.dart';

class TopicWork extends SimpleWork<Null>{

  @override
  Null onExtractResult(resultData) {

  }

  @override
  String onUrl(List params) => "https://office.efaceboard"
      ".cn:4443/MeetingServer/topic/getList";

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["sessionId"] = "5b0f2875-1d1f-4c2b-8c33-fbb55b24b31c";
  }

  @override
  HttpMethod get httpMethod => HttpMethod.post;
}