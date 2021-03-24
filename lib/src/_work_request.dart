// Created by 超悟空 on 2021/3/23.

import 'dart:convert';

import '_dio_request.dart' as http;
import '_print.dart';
import 'work_config.dart';
import 'work_model.dart';

/// 执行网络请求
///
/// [tag]为跟踪日志标签，[options]为请求所需的全部参数，返回响应数据
Future<Response> workRequest(String tag, Options options) async {
  if (!options.url.startsWith(RegExp(r'https?://')) &&
      (dioMap[options.clientKey] ?? dio).options.baseUrl.isEmpty) {
    // 地址不合法
    log(tag, 'url error');
    return Response(errorType: HttpErrorType.other);
  }

  log(tag, 'http', options);

  Response response;
  var i = 0;

  do {
    if (i > 0) {
      log(tag, 'retry ', i);
    }
    response = await http.request(tag, options);
    if (response.success) {
      break;
    }
    i++;
  } while (i <= options.retry);

  log(tag, 'http', response);

  // 转换类型
  if (response.success &&
      (options.responseType == null ||
          options.responseType == ResponseType.json) &&
      response.data is String &&
      response.data.isNotEmpty) {
    response.data = json.decode(response.data);
  }

  return response;
}
