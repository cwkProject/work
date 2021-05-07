// Created by 超悟空 on 2018/9/26.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:work/work.dart';

/// 简化的[WorkData]类实现
///
/// 使用特定的公司接口协议描述。
///
/// ``` http协议
/// 所有接口响应数据格式
///
/// json结构
///
/// {
/// "state":true, // 业务的成功失败标志
/// "errorCode":0, // 错误码，成功时返回0
/// "message":null, // 业务消息字符串，可以是成功时用于显示的信息，也可以是失败时的提示信息
/// "result": {}  // 真正响应的有效业务数据，任意类型
/// }
///
/// ```
class SimpleWorkData<T> extends WorkData<T> {
  /// 协议错误码
  int _errorCode = 0;

  /// 协议错误码
  int get errorCode => _errorCode;
}

/// 简化的[Work]类
///
/// * [D]为关联的接口结果数据类型。
/// * 适用于除下载任务以外的请求任务，下载任务请使用[SimpleDownloadWork]
/// * 使用特定的公司接口协议描述。
///
/// ``` http协议
/// 所有接口响应数据格式
///
/// json结构
///
/// {
/// "state":true, // 业务的成功失败标志
/// "errorCode":0, // 错误码
/// "message":null, // 业务消息字符串，可以是成功时用于显示的信息，也可以是失败时的提示信息
/// "result": {}  // 真正响应的有效业务数据，任意类型
/// }
///
/// ```
abstract class SimpleWork<D> extends Work<D, SimpleWorkData<D>> {
  /// 用于获取响应json数据协议中"result"字段
  static const String result = 'result';

  @override
  SimpleWorkData<D> onCreateWorkData() => SimpleWorkData<D>();

  @override
  FutureOr<D?> onRequestSuccess(SimpleWorkData<D> data) {
    if (data.response?.data?[result] == null) {
      return onDefaultResult(data);
    } else {
      return onExtractResult(data.response!.data[result], data);
    }
  }

  @override
  bool onRequestResult(SimpleWorkData<D> data) => data.response!.data['state'];

  @mustCallSuper
  @override
  FutureOr<D?> onRequestFailed(SimpleWorkData<D> data) {
    if (data.response!.data['errorCode'] != null) {
      data._errorCode = data.response!.data['errorCode']!;
    }

    return super.onRequestFailed(data);
  }

  @override
  String? onRequestSuccessMessage(SimpleWorkData<D> data) =>
      data.response!.data['message'];

  @override
  String? onRequestFailedMessage(SimpleWorkData<D> data) =>
      data.response!.data['message'];

  /// 生成响应成功的结果数据
  ///
  /// * [resultData]为协议中的[result]标签下的数据
  /// * 当请求成功且返回结果中存在[result]标签且不为null时被调用
  /// * 返回装配后的本地数据对象
  /// * [data]为将要返回的数据包装类
  @protected
  FutureOr<D?> onExtractResult(resultData, SimpleWorkData<D> data);

  /// 生成响应成功的默认结果数据
  ///
  /// * 当请求成功且返回结果不存在[result]标签或值为null时被调用，默认实现为null
  /// * [data]为将要返回的数据包装类
  @protected
  FutureOr<D?> onDefaultResult(SimpleWorkData<D> data) => null;
}

/// 简化的下载专用[Work]类
///
/// * 适用于下载文件任务，其他类型任务请使用[SimpleWork]
abstract class SimpleDownloadWork extends Work<void, SimpleWorkData<void>> {
  @override
  SimpleWorkData<void> onCreateWorkData() => SimpleWorkData<void>();

  @override
  bool onRequestResult(SimpleWorkData<void> data) => true;

  @override
  FutureOr<void> onRequestSuccess(SimpleWorkData<void> data) => null;

  @override
  HttpMethod onHttpMethod() => HttpMethod.download;

  @mustCallSuper
  @override
  FutureOr<void> onConfigOptions(HttpOptions options) {
    options.downloadPath = onDownloadPath();
  }

  /// 返回下载文件路径
  String onDownloadPath();
}
