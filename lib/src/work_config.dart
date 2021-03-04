// Created by 超悟空 on 2018/9/20.

import 'package:dio/dio.dart';

/// 表单提交格式
///
/// 如果默认的post使用'multipart/form-data'方式提交，
/// 则需要将[mergeBaseOptions.contentType]设为此值，
/// 框架负责将传入的map数据自动装配成FormData格式
const formDataContentType = 'multipart/form-data';

/// 是否开启debug模式，开启后会输出日志
bool debugWork = true;

/// 全局使用的[Dio]请求对象
final _dio = Dio(
  BaseOptions(
    connectTimeout: 10000,
    receiveTimeout: 30000,
    sendTimeout: 30000,
    contentType: 'application/x-www-form-urlencoded',
  ),
);

/// 全局使用的默认网络访问器实例
Dio get dio => _dio;

/// 存放自定义的dio对象
///
/// 如果项目中有多种配置的基础请求参数，可以在这里缓存自定义的全局dio实例
/// 比如项目中有多个域名的根host，可以在这里配置每个域名的dio。
/// 使用时需要在[Work.clientKey]中指定对应的key
final dioMap = <String, Dio>{};

/// 替换[dio.options]中的参数
void mergeBaseOptions({
  String? method,
  String? baseUrl,
  Map<String, dynamic>? queryParameters,
  int? connectTimeout,
  int? receiveTimeout,
  int? sendTimeout,
  Map<String, dynamic>? extra,
  Map<String, dynamic>? headers,
  ResponseType? responseType,
  String? contentType,
  ValidateStatus? validateStatus,
  bool? receiveDataWhenStatusError,
  bool? followRedirects,
  int? maxRedirects,
  RequestEncoder? requestEncoder,
  ResponseDecoder? responseDecoder,
  ListFormat? listFormat,
}) {
  dio.options = dio.options.copyWith(
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
    listFormat: listFormat,
  );
}
