import 'package:work/work.dart';

void main() async {
  await TestWork().start();
}

class TestWork extends SimpleWork<Null> {
  @override
  Null onExtractResult(resultData, SimpleWorkData<Null> data) {}

  @override
  String onUrl(List params) => "http://192.168.0"
      ".31:8080/Chatboard/meeting/getFileGroupId";

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["sessionId"] = "6cf09a7b-cf47-400f-a859-2671ca6b3b5e";
    data["meetingId"] = "0518ccc93edd4da197165c1cd7198fb1";
  }
}
