// Created by 超悟空 on 2018/9/26.
// Version 1.0 2018/9/26
// Since 1.0 2018/9/26
import 'package:work/work.dart';

class DownloadWork extends SimpleDownloadWork {
  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["sessionId"] = "5b0f2875-1d1f-4c2b-8c33-fbb55b24b31c";
    data["resourceId"] = "1c265d86-d8ba-43d2-86db-80f3e79c2bd8";
  }

  @override
  String onDownloadPath(List params) => params[0];

  @override
  String onUrl(List params) => "https://sdk.efaceboard"
      ".cn:8443/FileServer/resource/download";
}
