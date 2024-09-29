// Created by 超悟空 on 2018/9/20.

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:work/src/work_core.dart';

import '_print.dart';
import 'work_model.dart' show HttpMethod;

export '_print.dart' show WorkLogger;

part '_work_config_delegate.dart';

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

/// 全局默认使用的[WorkConfig]配置
///
/// 如果个别请求需要特殊配置比如多个服务器节点的应用，可以在[Work.onWorkConfig]中指定
WorkConfig workConfig = WorkConfig(
  dio: Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.formUrlEncodedContentType,
    ),
  ),
);

/// Work库全局网络客户端配置
class WorkConfig {
  WorkConfig({
    required this.dio,
    this.delegate = const _WorkDelegateImp(),
  });

  /// 全局使用的默认网络访问器实例
  final Dio dio;

  /// [Work]生命周期方法的全局委托
  ///
  /// 作用类似于给[Work]增加了一个超类实现
  /// 最终以子类实现优先
  final WorkDelegate delegate;
}
