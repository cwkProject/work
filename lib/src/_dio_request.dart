// Created by 超悟空 on 2018/9/25.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;

import '_print.dart';
import 'communication.dart' as com;
import 'work_config.dart' as work;

import '_convert.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) '_convert_web.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '_convert_native.dart';

/// 发起请求
///
/// dio实现
Future<com.Response> request(String tag, com.Options options) async {
  final dioOptions = _onConfigOptions(tag, options);

  dio.Response? dioResponse;

  var success = false;

  com.HttpErrorType? errorType;

  // 总接收字节数
  var receiveByteCount = 0;

  // 结果解析器
  final decoder = (responseBytes, options, responseBody) {
    receiveByteCount = responseBytes.length;
    return utf8.decode(responseBytes, allowMalformed: true);
  };

  dioOptions.responseDecoder = decoder;

  final isFormData = options.method == com.HttpMethod.upload ||
      (options.contentType ?? work.dio.options.contentType) == com.formData;

  final client = work.dioMap[options.clientKey] ?? work.dio;

  try {
    switch (options.method) {
      case com.HttpMethod.download:
        log(tag, 'download path:${options.downloadPath}');

        // 接收进度代理
        final onReceiveProgress = (int receive, int total) {
          receiveByteCount = receive;
          options.onReceiveProgress?.call(receive, total);
        };

        dioResponse = await client.download(options.url, options.downloadPath,
            data: options.params,
            cancelToken: options.cancelToken.data,
            options: dioOptions,
            onReceiveProgress: onReceiveProgress);
        break;
      case com.HttpMethod.get:
        dioResponse = await client.get(
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
  } on dio.DioError catch (e) {
    log(tag, 'http error', e.type);

    dioResponse = e.response;
    success = false;
    errorType = _onConvertErrorType(e.type);
  } catch (e) {
    log(tag, 'http other error', e);
    errorType = com.HttpErrorType.other;
  }

  if (dioResponse != null) {
    return com.Response(
      success: success,
      statusCode: dioResponse.statusCode ?? 0,
      headers: dioResponse.headers.map,
      data: dioResponse.request.responseType == dio.ResponseType.stream
          ? dioResponse.data.stream
          : dioResponse.data,
      errorType: errorType,
      receiveByteCount: receiveByteCount,
    );
  } else {
    return com.Response(errorType: errorType);
  }
}

/// 转换dio异常类型到work库异常类型
com.HttpErrorType _onConvertErrorType(dio.DioErrorType type) {
  switch (type) {
    case dio.DioErrorType.connectTimeout:
      return com.HttpErrorType.connectTimeout;
    case dio.DioErrorType.sendTimeout:
      return com.HttpErrorType.sendTimeout;
    case dio.DioErrorType.receiveTimeout:
      return com.HttpErrorType.receiveTimeout;
    case dio.DioErrorType.response:
      return com.HttpErrorType.response;
    case dio.DioErrorType.cancel:
      return com.HttpErrorType.cancel;
    default:
      return com.HttpErrorType.other;
  }
}

/// 生成dio专用配置
dio.Options _onConfigOptions(String tag, com.Options options) {
  final dioOptions = dio.Options();

  switch (options.method) {
    case com.HttpMethod.get:
    case com.HttpMethod.download:
      dioOptions.method = 'GET';
      break;
    case com.HttpMethod.post:
    case com.HttpMethod.upload:
      dioOptions.method = 'POST';
      break;
    case com.HttpMethod.put:
      dioOptions.method = 'PUT';
      break;
    case com.HttpMethod.head:
      dioOptions.method = 'HEAD';
      break;
    case com.HttpMethod.delete:
      dioOptions.method = 'DELETE';
      break;
  }

  if (options.responseType != null) {
    switch (options.responseType!) {
      case com.ResponseType.json:
        dioOptions.responseType = dio.ResponseType.json;
        break;
      case com.ResponseType.stream:
        dioOptions.responseType = dio.ResponseType.stream;
        break;
      case com.ResponseType.plain:
        dioOptions.responseType = dio.ResponseType.plain;
        break;
      case com.ResponseType.bytes:
        dioOptions.responseType = dio.ResponseType.bytes;
        break;
    }
  }
  dioOptions.headers = options.headers;

  dioOptions.contentType = options.contentType;
  dioOptions.receiveTimeout = options.readTimeout;
  dioOptions.sendTimeout = options.sendTimeout;

  options.cancelToken.data = dio.CancelToken();

  options.cancelToken.whenCancel.then((cancelToken) {
    if (cancelToken is dio.CancelToken && !cancelToken.isCancelled) {
      log(tag, 'http cancel');
      cancelToken.cancel();
    }
  });

  return dioOptions;
}
