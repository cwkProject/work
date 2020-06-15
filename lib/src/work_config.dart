// Created by 超悟空 on 2018/9/20.
// Version 1.0 2018/9/20
// Since 1.0 2018/9/20

import 'package:dio/dio.dart';

/// 是否开启debug模式，开启后会输出日志
bool _debugWork = true;

/// 是否开启debug模式，开启后会输出日志
bool get debugWork => _debugWork;

/// 是否开启debug模式，开启后会输出日志
set debugWork(bool enable) {
  assert(enable != null);
  _debugWork = enable;
}

/// 全局使用的[Dio]请求对象
final _dio = Dio(
  BaseOptions(
    connectTimeout: 10000,
    receiveTimeout: 30000,
    sendTimeout: 30000,
    contentType: "application/x-www-form-urlencoded",
  ),
);

/// 全局使用的[Dio]请求对象
Dio get dio => _dio;

/// 替换[dio.options]中的参数
void mergeBaseOptions({
  String method,
  String baseUrl,
  Map<String, dynamic> queryParameters,
  String path,
  int connectTimeout,
  int receiveTimeout,
  int sendTimeout,
  Map<String, dynamic> extra,
  Map<String, dynamic> headers,
  ResponseType responseType,
  String contentType,
  ValidateStatus validateStatus,
  bool receiveDataWhenStatusError,
  bool followRedirects,
  int maxRedirects,
  RequestEncoder requestEncoder,
  ResponseDecoder responseDecoder,
}) {
  dio.options = dio.options.merge(
    method: method,
    baseUrl: baseUrl,
    queryParameters: queryParameters,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    sendTimeout: sendTimeout,
    extra: extra,
    headers: headers,
    responseType: responseType,
    contentType: contentType,
    validateStatus: validateStatus,
    receiveDataWhenStatusError: receiveDataWhenStatusError,
    followRedirects: followRedirects,
    maxRedirects: maxRedirects,
    requestEncoder: requestEncoder,
    responseDecoder: responseDecoder,
  );
}
