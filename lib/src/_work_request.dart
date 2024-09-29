// Created by 超悟空 on 2021/3/23.

import 'dart:convert';

import 'package:dio/dio.dart';

import '_convert.dart'
// ignore: uri_does_not_exist
    if (dart.library.js_interop) '_convert_web.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '_convert_native.dart';
import 'work_model.dart';

/// Http执行器，每次调用都应该发起独立的新http请求并返回dio[Response]
///
/// 由[WorkRequest]生成，最终调用由框架负责
/// 请求中的异常请正常抛出
typedef HttpCall = Future<Response> Function();

/// 执行网络请求
///
/// [tag]为跟踪日志标签，[options]为请求所需的全部参数，返回响应数据
HttpCall workRequest(String tag, Dio client, WorkRequestOptions options) {
  final dioOptions = options.dioOptions;

  Map<String, dynamic>? queryParameters = options.queryParams;

  dynamic data;

  switch (dioOptions.method) {
    case 'GET':
    case 'HEAD':
      if (options.params is Map<String, dynamic>) {
        queryParameters ??= options.params;
      }
      break;
    default:
      final isFormData = (dioOptions.contentType ?? client.options.contentType)
              ?.startsWith(Headers.multipartFormDataContentType) ??
          false;
      data = isFormData && options.params is Map<String, dynamic>
          ? convertToDio(options.params)
          : options.params;
      break;
  }

  if (options.downloadPath != null) {
    return () => client.download(
          options.url,
          options.downloadPath,
          data: data,
          queryParameters: queryParameters,
          cancelToken: options.cancelToken,
          options: dioOptions,
          onReceiveProgress: options.onReceiveProgress,
        );
  } else {
    return () => client.request(
          options.url,
          data: data,
          queryParameters: queryParameters,
          cancelToken: options.cancelToken,
          options: dioOptions,
          onSendProgress: options.onSendProgress,
          onReceiveProgress: options.onReceiveProgress,
        );
  }
}

/// dio异常类型扩展
extension DioErrorConvert on DioExceptionType {
  /// 转换dio异常类型到work库异常类型
  WorkErrorType toWorkErrorType() {
    switch (this) {
      case DioExceptionType.connectionTimeout:
        return WorkErrorType.connectionTimeout;
      case DioExceptionType.sendTimeout:
        return WorkErrorType.sendTimeout;
      case DioExceptionType.receiveTimeout:
        return WorkErrorType.receiveTimeout;
      case DioExceptionType.badResponse:
        return WorkErrorType.response;
      case DioExceptionType.cancel:
        return WorkErrorType.cancel;
      case DioExceptionType.badCertificate:
        return WorkErrorType.certificate;
      case DioExceptionType.connectionError:
        return WorkErrorType.connection;
      case DioExceptionType.unknown:
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
      dioResponse: this,
      success: success,
      data: workData,
    );
  }
}
