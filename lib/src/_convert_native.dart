// Created by 超悟空 on 2020/7/4.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'communication.dart';

/// 用于[com.HttpMethod.upload]请求类型的数据转换
///
/// [src]原始参数，返回处理后的符合dio接口的参数
Future<FormData> convertToDio(Map<String, dynamic> src) async {
  Future<dynamic> onConvert(value) async {
    if (value is File) {
      value = UploadFileInfo(value.path);
    }

    if (value is UploadFileInfo) {
      if (value.stream != null) {
        return MultipartFile(
          value.stream,
          value.length,
          filename: value.fileName,
          contentType: MediaType.parse(value.mimeType),
        );
      }

      return MultipartFile.fromFile(
        value.filePath,
        filename: value.fileName,
        contentType: MediaType.parse(value.mimeType),
      );
    }

    return value;
  }

  final params = Map<String, dynamic>();

  for (final entry in src.entries) {
    if (entry.value is List) {
      params[entry.key] =
          await Stream.fromFutures(entry.value.map<Future<dynamic>>(onConvert)).toList();
    } else {
      params[entry.key] = await onConvert(entry.value);
    }
  }

  return FormData.fromMap(params);
}
