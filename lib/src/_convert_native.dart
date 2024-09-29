// Created by 超悟空 on 2020/7/4.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import 'work_model.dart';

/// 用于[Headers.multipartFormDataContentType]请求类型的数据转换
///
/// [src]原始参数，返回处理后的符合dio接口的参数
FormData convertToDio(Map<String, dynamic> src) {
  dynamic onConvert(dynamic value) {
    if (value is File) {
      value = UploadFileInfo(value.path);
    }

    if (value is UploadFileInfo) {
      if (value.stream != null) {
        return MultipartFile.fromStream(
          () => value.stream!,
          value.length!,
          filename: value.fileName,
          contentType:
              value.mimeType != null ? MediaType.parse(value.mimeType!) : null,
        );
      }

      return MultipartFile.fromFile(
        value.filePath!,
        filename: value.fileName,
        contentType:
            value.mimeType != null ? MediaType.parse(value.mimeType!) : null,
      );
    }

    return value;
  }

  final params = <String, dynamic>{};

  for (final entry in src.entries) {
    if (entry.value is List) {
      params[entry.key] = entry.value.map(onConvert).toList();
    } else {
      params[entry.key] = onConvert(entry.value);
    }
  }

  return FormData.fromMap(params);
}
