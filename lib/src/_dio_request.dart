// Created by 超悟空 on 2018/9/25.

import 'dart:async';

import 'package:dio/dio.dart';

import '_convert.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) '_convert_web.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '_convert_native.dart';
import '_print.dart';
import 'work_config.dart';
import 'work_model.dart';

/// 发起请求
///
/// dio实现
Future<HttpResponse> request(String tag, HttpOptions options) async {
  final dioOptions = _onConfigOptions(tag, options);

  Response? dioResponse;

  var success = false;

  WorkErrorType? errorType;

  final client = (workConfigs[options.configKey] ?? workConfig).dio;

  final isFormData = options.method == HttpMethod.upload ||
      (options.contentType ?? client.options.contentType) == multipartFormData;

  try {
    switch (options.method) {
      case HttpMethod.download:
        log(tag, 'download path:${options.downloadPath}');

        dioResponse = await client.download(
          options.url,
          options.downloadPath,
          queryParameters: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onReceiveProgress: options.onReceiveProgress,
        );
        break;
      case HttpMethod.get:
      case HttpMethod.head:
        dioResponse = await client.request(
          options.url,
          queryParameters: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onReceiveProgress: options.onReceiveProgress,
        );
        break;
      default:
        dioResponse = await client.request(
          options.url,
          data:
              isFormData ? await convertToDio(options.params) : options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onSendProgress: options.onSendProgress,
          onReceiveProgress: options.onReceiveProgress,
        );
        break;
    }

    success = true;
  } on DioError catch (e) {
    log(tag, 'http error', e.type);

    dioResponse = e.response;
    success = false;
    errorType = _onConvertErrorType(e.type);
  } catch (e) {
    log(tag, 'http other error', e);
    errorType = WorkErrorType.other;
  }

  if (dioResponse != null) {
    return HttpResponse(
      success: success,
      statusCode: dioResponse.statusCode ?? 0,
      headers: dioResponse.headers.map,
      data: dioResponse.requestOptions.responseType == ResponseType.stream
          ? dioResponse.data.stream
          : dioResponse.data,
      errorType: errorType,
    );
  } else {
    return HttpResponse(errorType: errorType);
  }
}

/// 转换dio异常类型到work库异常类型
WorkErrorType _onConvertErrorType(DioErrorType type) {
  switch (type) {
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

/// 生成dio专用配置
Options _onConfigOptions(String tag, HttpOptions options) {
  final dioOptions = Options();

  switch (options.method) {
    case HttpMethod.get:
    case HttpMethod.download:
      dioOptions.method = 'GET';
      break;
    case HttpMethod.post:
    case HttpMethod.upload:
      dioOptions.method = 'POST';
      break;
    case HttpMethod.put:
      dioOptions.method = 'PUT';
      break;
    case HttpMethod.head:
      dioOptions.method = 'HEAD';
      break;
    case HttpMethod.patch:
      dioOptions.method = 'PATCH';
      break;
    case HttpMethod.delete:
      dioOptions.method = 'DELETE';
      break;
  }

  if (options.responseType != null) {
    switch (options.responseType!) {
      case HttpResponseType.json:
        dioOptions.responseType = ResponseType.json;
        break;
      case HttpResponseType.stream:
        dioOptions.responseType = ResponseType.stream;
        break;
      case HttpResponseType.plain:
        dioOptions.responseType = ResponseType.plain;
        break;
      case HttpResponseType.bytes:
        dioOptions.responseType = ResponseType.bytes;
        break;
    }
  }

  dioOptions.headers = options.headers;

  dioOptions.contentType = options.contentType;
  dioOptions.receiveTimeout = options.readTimeout;
  dioOptions.sendTimeout = options.sendTimeout;

  options.cancelToken.data = CancelToken();

  options.cancelToken.whenCancel.then((cancelToken) {
    if (cancelToken is CancelToken && !cancelToken.isCancelled) {
      log(tag, 'http cancel');
      cancelToken.cancel();
    }
  });

  return dioOptions;
}
