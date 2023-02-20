// Created by 超悟空 on 2018/9/20.

import 'package:dio/dio.dart';

import '_print.dart';
import '_work_request.dart' as request;
import 'work_model.dart' show WorkRequest, WorkLogger;

/// 是否开启debug模式，开启后会输出日志
bool _debugWork = true;

/// 是否开启debug模式，开启后会输出日志
bool get debugWork => _debugWork;

/// 是否开启debug模式，开启后会输出日志
set debugWork(bool value) {
  _debugWork = value;

  if (value) {
    log = _workLog;
  } else {
    log = logEmpty;
  }
}

/// 全局默认使用的[WorkConfig]配置
WorkConfig workConfig = WorkConfig(
  dio: Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: 'application/x-www-form-urlencoded',
    ),
  ),
);

/// 存放自定义的[WorkConfig]对象
///
/// 如果项目中有多种全局请求配置，可以在这里缓存自定义的[WorkConfig]实例
/// 比如项目中有多个域名的根host，可以在这里配置每个域名的dio。
/// 使用时需要在[Work.onConfigKey]中指定对应的key
final workConfigs = <String, WorkConfig>{};

/// Work库全局网络客户端配置
class WorkConfig {
  WorkConfig({
    required this.dio,
    this.workRequest = request.workRequest,
  });

  /// 全局使用的默认网络访问器实例
  final Dio dio;

  /// 全局实际执行网络请求的方法
  final WorkRequest workRequest;
}

/// work库的日志打印函数，可以覆盖
///
/// 当[debugWork]为true时生效
WorkLogger _workLog = logImp;

/// work库的日志打印函数，可以覆盖
///
/// 当[debugWork]为true时生效
set workLog(WorkLogger value) {
  _workLog = value;

  if (debugWork) {
    log = value;
  }
}
