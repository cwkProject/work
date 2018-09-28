// Created by 超悟空 on 2018/9/26.
// Version 1.0 2018/9/26
// Since 1.0 2018/9/26
import 'package:work/work.dart';
import 'dart:io';

class UploadWork extends SimpleWork<String> {
  @override
  String onExtractResult(resultData) => resultData;

  @override
  String onUrl(List params) => "https://sdk.efaceboard"
      ".cn:8443/FileServer/upload/uploadHeadPic";

  @override
  void onFillParams(Map<String, dynamic> data, List params) {
    data["sessionId"] = "5b0f2875-1d1f-4c2b-8c33-fbb55b24b31c";
    data["file"] = UploadFileInfo(params[0]);
  }

  @override
  HttpMethod get httpMethod => HttpMethod.upload;
}
