// Created by 超悟空 on 2020/7/4.

import 'package:dio/dio.dart';
import 'work_model.dart';

/// 用于[HttpMethod.upload]请求类型的数据转换
///
/// [src]原始参数，返回处理后的符合dio接口的参数
Future<FormData> convertToDio(Map<String, dynamic> src) =>
    throw UnsupportedError('');

/// 转换dio异常类型到work库异常类型
HttpErrorType onConvertErrorType(DioErrorType type) {
  switch (type) {
    case DioErrorType.connectTimeout:
      return HttpErrorType.connectTimeout;
    case DioErrorType.sendTimeout:
      return HttpErrorType.sendTimeout;
    case DioErrorType.receiveTimeout:
      return HttpErrorType.receiveTimeout;
    case DioErrorType.response:
      return HttpErrorType.response;
    case DioErrorType.cancel:
      return HttpErrorType.cancel;
    default:
      return HttpErrorType.other;
  }
}
