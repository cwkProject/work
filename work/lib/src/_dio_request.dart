// Created by 超悟空 on 2018/9/25.
// Version 1.0 2018/9/25
// Since 1.0 2018/9/25

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' as dio;

import '_print.dart';
import 'communication.dart' as com;
import 'work_config.dart' as work;

/// 发起请求
///
/// dio实现
Future<com.Response> request(String tag, com.Options options) async {
  final dioOptions = _onConfigOptions(tag, options);

  dio.Response dioResponse;

  bool success = false;

  try {
    if (options.method == com.HttpMethod.download) {
      log(tag, "download path:${options.downloadPath}");
      dioResponse = await work.dio.download(options.url, options.downloadPath,
          data: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onProgress: options.onProgress);
    } else if (options.method == com.HttpMethod.upload) {
      options.params.forEach((key, value) {
        if (value is com.UploadFileInfo) {
          options.params[key] = dio.UploadFileInfo(
              File(value.filePath), value.fileName,
              contentType: ContentType.parse(value.mimeType));
        } else if (value is List) {
          value.map((item) {
            if (item is com.UploadFileInfo) {
              return dio.UploadFileInfo(File(item.filePath), item.fileName,
                  contentType: ContentType.parse(item.mimeType));
            } else {
              return item;
            }
          });
        }
      });

      dio.FormData formData = dio.FormData.from(options.params);

      dioResponse = await work.dio.post(options.url,
          data: formData,
          cancelToken: options.cancelToken.data,
          options: dioOptions);
    } else {
      dioResponse = await work.dio.request(options.url,
          data: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions);
    }
    success = true;
  } on dio.DioError catch (e) {
    log(tag, "http error", e.type);

    dioResponse = e.response;
    success = false;
  } catch (e) {
    log(tag, "http other error", e);
  }

  return _onParseResponse(tag, success, dioResponse);
}

/// 生成dio专用配置
dio.Options _onConfigOptions(String tag, com.Options options) {
  final dioOptions = dio.Options();

  switch (options.method) {
    case com.HttpMethod.get:
      dioOptions.method = "GET";
      break;
    case com.HttpMethod.post:
      dioOptions.method = "POST";
      break;
    case com.HttpMethod.put:
      dioOptions.method = "PUT";
      break;
    case com.HttpMethod.head:
      dioOptions.method = "HEAD";
      break;
    case com.HttpMethod.delete:
      dioOptions.method = "DELETE";
      break;
    case com.HttpMethod.upload:
      dioOptions.method = "POST";
      break;
    case com.HttpMethod.download:
      dioOptions.method = "GET";
      break;
  }

  if (options.responseType != null) {
    switch (options.responseType) {
      case com.ResponseType.json:
        dioOptions.responseType = dio.ResponseType.JSON;
        break;
      case com.ResponseType.stream:
        dioOptions.responseType = dio.ResponseType.STREAM;
        break;
      case com.ResponseType.plain:
        dioOptions.responseType = dio.ResponseType.PLAIN;
        break;
    }
  }

  dioOptions.contentType = options.contentType;
  dioOptions.connectTimeout = options.connectTimeout;
  dioOptions.receiveTimeout = options.readTimeout;
  if (options.headers != null) {
    dioOptions.headers = options.headers;
  }

  if (options.cancelToken.data is! dio.CancelToken) {
    com.CancelToken cancelToken = options.cancelToken;

    cancelToken.data = dio.CancelToken();

    cancelToken.stream.listen((_) {
      if (cancelToken.data is dio.CancelToken) {
        log(tag, "http cancel");
        cancelToken.data.cancel();
        cancelToken.data = null;
      }
    });
  }

  return dioOptions;
}

/// 处理dio Response为work的Response
com.Response _onParseResponse(
    String tag, bool success, dio.Response dioResponse) {
  if (dioResponse != null) {
    return com.Response(
        success: success,
        statusCode: dioResponse.statusCode,
        headers: dioResponse.headers,
        data: dioResponse.data);
  } else {
    return com.Response();
  }
}
