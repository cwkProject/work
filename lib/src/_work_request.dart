// Created by 超悟空 on 2021/3/23.

import 'dart:convert';

import 'package:dio/dio.dart';

import '_convert.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) '_convert_web.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '_convert_native.dart';
import 'work_config.dart';
import 'work_model.dart';

/// 执行网络请求
///
/// [tag]为跟踪日志标签，[options]为请求所需的全部参数，返回响应数据
Future<HttpCall> workRequest(String tag, WorkRequestOptions options) async {
  final client = (workConfigs[options.configKey] ?? workConfig).dio;
  final dioOptions = options.toDioOptions();

  Map<String, dynamic>? queryParameters;

  dynamic data;

  switch (options.method) {
    case HttpMethod.get:
    case HttpMethod.head:
      if (options.params is Map<String, dynamic>) {
        queryParameters = options.params;
      }
      break;
    default:
      final isFormData = (options.contentType ?? client.options.contentType) ==
          multipartFormData;
      data = isFormData && options.params is Map<String, dynamic>
          ? await convertToDio(options.params)
          : options.params;
      break;
  }

  return () => options.downloadPath != null
      ? client.download(
          options.url,
          options.downloadPath,
          data: data,
          queryParameters: queryParameters,
          cancelToken: options.cancelToken,
          options: dioOptions,
          onReceiveProgress: options.onReceiveProgress,
        )
      : client.request(
          options.url,
          data: data,
          queryParameters: queryParameters,
          cancelToken: options.cancelToken,
          options: dioOptions,
          onSendProgress: options.onSendProgress,
          onReceiveProgress: options.onReceiveProgress,
        );
}

/// dio异常类型扩展
extension DioErrorConvert on DioErrorType {
  /// 转换dio异常类型到work库异常类型
  WorkErrorType toWorkErrorType() {
    switch (this) {
      case DioErrorType.connectTimeout:
        return WorkErrorType.connectTimeout;
      case DioErrorType.sendTimeout:
        return WorkErrorType.sendTimeout;
      case DioErrorType.receiveTimeout:
        return WorkErrorType.receiveTimeout;
      case DioErrorType.response:
        return WorkErrorType.response;
      case DioErrorType.cancel:
        return WorkErrorType.cancel;
      default:
        return WorkErrorType.other;
    }
  }
}

/// [Response]扩展
extension ResponseConvert on Response {
  /// 转行到[HttpResponse]
  HttpResponse toHttpResponse() {
    final success = requestOptions.validateStatus(statusCode);

    var workData = requestOptions.responseType == ResponseType.stream
        ? data?.stream
        : data;

    // 尝试转换类型
    if (success &&
        requestOptions.responseType == ResponseType.json &&
        workData is String &&
        workData.isNotEmpty) {
      try {
        workData = json.decode(workData);
        // ignore: empty_catches
      } catch (e) {}
    }

    return HttpResponse(
      success: success,
      statusCode: statusCode ?? 0,
      headers: headers.map,
      data: workData,
    );
  }
}

/// 为[HttpMethod]扩展方法
extension HttpMethodExtension on HttpMethod {
  /// 对应的http方法名称
  String get name {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.head:
        return 'HEAD';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
    }
  }
}

/// [WorkRequestOptions]扩展
extension WorkRequestOptionsConvert on WorkRequestOptions {
  /// 转换到dio[Options]
  Options toDioOptions() {
    return Options()
      ..method = method.name
      ..headers = headers
      ..contentType = contentType
      ..receiveTimeout = readTimeout
      ..sendTimeout = sendTimeout
      ..responseType = responseType
      ..listFormat = listFormat;
  }
}
