// Created by 超悟空 on 2018/9/25.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;

import '_convert.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) '_convert_web.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '_convert_native.dart';
import '_print.dart';
import 'work_config.dart' as config;
import 'work_model.dart' as work;

/// 发起请求
///
/// dio实现
Future<work.Response> request(String tag, work.Options options) async {
  final dioOptions = _onConfigOptions(tag, options);

  dio.Response? dioResponse;

  var success = false;

  work.HttpErrorType? errorType;

  // 总接收字节数
  var receiveByteCount = 0;

  // 结果解析器
  final decoder = (responseBytes, options, responseBody) {
    receiveByteCount = responseBytes.length;
    return utf8.decode(responseBytes, allowMalformed: true);
  };

  dioOptions.responseDecoder = decoder;

  final isFormData = options.method == work.HttpMethod.upload ||
      (options.contentType ?? config.dio.options.contentType) == work.formData;

  final client = config.dioMap[options.clientKey] ?? config.dio;

  try {
    switch (options.method) {
      case work.HttpMethod.download:
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
      case work.HttpMethod.get:
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
    errorType = onConvertErrorType(e.type);
  } catch (e) {
    log(tag, 'http other error', e);
    errorType = work.HttpErrorType.other;
  }

  if (dioResponse != null) {
    return work.Response(
      success: success,
      statusCode: dioResponse.statusCode ?? 0,
      headers: dioResponse.headers.map,
      data: dioResponse.requestOptions.responseType == dio.ResponseType.stream
          ? dioResponse.data.stream
          : dioResponse.data,
      errorType: errorType,
      receiveByteCount: receiveByteCount,
    );
  } else {
    return work.Response(errorType: errorType);
  }
}

/// 生成dio专用配置
dio.Options _onConfigOptions(String tag, work.Options options) {
  final dioOptions = dio.Options();

  switch (options.method) {
    case work.HttpMethod.get:
    case work.HttpMethod.download:
      dioOptions.method = 'GET';
      break;
    case work.HttpMethod.post:
    case work.HttpMethod.upload:
      dioOptions.method = 'POST';
      break;
    case work.HttpMethod.put:
      dioOptions.method = 'PUT';
      break;
    case work.HttpMethod.head:
      dioOptions.method = 'HEAD';
      break;
    case work.HttpMethod.delete:
      dioOptions.method = 'DELETE';
      break;
  }

  if (options.responseType != null) {
    switch (options.responseType!) {
      case work.ResponseType.json:
        dioOptions.responseType = dio.ResponseType.json;
        break;
      case work.ResponseType.stream:
        dioOptions.responseType = dio.ResponseType.stream;
        break;
      case work.ResponseType.plain:
        dioOptions.responseType = dio.ResponseType.plain;
        break;
      case work.ResponseType.bytes:
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
