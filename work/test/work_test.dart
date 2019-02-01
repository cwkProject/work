import 'package:work/work.dart';

void main() async {
  await TestWork().start();
}

class TestWork extends SimpleWork<Null> {
  @override
  Null onExtractResult(resultData, SimpleWorkData<Null> data) {}

  @override
  String onUrl(List params) => "http://192.168.0.31:8070/MeetingServer/user/getMobileVerifyCode";

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["mobileNum"] = "18612345678";
  }

  @override
  HttpMethod get httpMethod => HttpMethod.post;
}
