// Created by 超悟空 on 2018/9/20.
// Version 1.0 2018/9/20
// Since 1.0 2018/9/20
import 'package:dio/dio.dart';

/// 是否开启debug模式，开启后会输出日志
bool debugWork = true;

/// 全局使用的[Dio]请求对象
Dio dio = Dio(
  BaseOptions(
    connectTimeout: 10000,
    receiveTimeout: 30000,
    sendTimeout: 30000,
    contentType: "application/x-www-form-urlencoded",
  ),
);
