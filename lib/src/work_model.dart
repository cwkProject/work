// Created by 超悟空 on 2018/9/20.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

import 'work_config.dart';

/// 进度监听器
typedef OnProgress = void Function(int current, int total);

/// Http执行器，每次调用都应该发起独立的新http请求并返回dio[Response]
///
/// 由[WorkRequest]生成
/// 请求中的异常请正常抛出
typedef HttpCall = Future<Response> Function();

/// 网络请求生成器
///
/// 用于装配请求参数并生成最终的请求方法[HttpCall]
/// [tag]为跟踪日志标签，[options]为请求所需的全部参数，返回响应数据
typedef WorkRequest = Future<HttpCall> Function(String tag, WorkRequestOptions options);

/// 输出日志函数
///
/// [tag]日志标签，[message]日志内容，[data]额外数据
typedef WorkLogger = void Function(String tag, String? message, [Object? data]);

/// 多分块提交格式
///
/// 上传文件时需要使用此格式，
/// 框架负责将传入的map数据自动装配成FormData格式
const multipartFormData = 'multipart/form-data';

/// 请求配置信息
class WorkRequestOptions {
  /// 用于取消本次请求的工具，由框架管理，无法被覆盖
  final cancelToken = CancelToken();

  /// 完整的请求地址（包含http(s)://），或者是相对地址（需调用过[workConfig]设置全局dio根地址）
  late String url;

  /// Http请求方法
  HttpMethod method = HttpMethod.get;

  /// 发送/上传进度监听器，在[HttpMethod.get]和[HttpMethod.head]中无效
  OnProgress? onSendProgress;

  /// 接收/下载进度监听器
  OnProgress? onReceiveProgress;

  /// 自定义/追加的Http请求头
  Map<String, dynamic>? headers;

  /// 最终用于发送的请求参数
  ///
  /// 支持多种格式，需要与[contentType]匹配
  /// 可以使用自行拼装的dio中的FormData数据
  dynamic params;

  ///  发送超时
  ///
  ///  传出流上前后两次发送数据的间隔，单位毫秒
  int? sendTimeout;

  ///  读取超时
  ///
  ///  响应流上前后两次接受到数据的间隔，单位毫秒
  int? readTimeout;

  /// 请求的Content-Type
  ///
  /// 默认值'application/x-www-form-urlencoded'
  /// 如果需要formData的表单提交格式，请将该值设置为[multipartFormData]
  /// 框架会自动进行表单装配
  String? contentType;

  /// [responseType] 表示期望以哪种格式(方式)接受响应数据
  ///
  /// 默认值在[WorkConfig.dio]中设置，dio默认[ResponseType.json]
  ResponseType? responseType;

  /// 下载文件的存放路径
  String? downloadPath;

  /// 用于指定使用的网络全局网络访问器的key
  ///
  /// 返回null或key不存在则表示使用默认访问器
  /// 关联性请查看[workConfigs]
  String? configKey;

  /// 在表单提交中自动装配数组使用的序列化格式
  ListFormat? listFormat;

  /// 转换到dio[Options]
  Options toDioOptions() {
    return Options()
      ..method = method.name
      ..headers = headers
      ..contentType = contentType
      ..receiveTimeout = readTimeout
      ..sendTimeout = sendTimeout
      ..responseType = responseType
      ..listFormat = listFormat;
  }

  @override
  String toString() => '''request 
$method
url: ${(workConfigs[configKey] ?? workConfig).dio.options.baseUrl}$url
headers: $headers
params: $params''';
}

/// 实际的Http响应数据
class HttpResponse {
  HttpResponse({
    this.success = false,
    this.data,
    this.headers,
    this.statusCode = 0,

  });

  /// 响应数据
  ///
  /// 数据类型由[HttpResponseType]决定
  final dynamic data;

  /// 响应头信息
  final Map<String, List<String>>? headers;

  /// 响应状态码
  final int statusCode;

  /// 请求成功失败标志
  final bool success;

  /// 将头信息转换成文本输出
  String get _headersToString {
    final stringBuffer = StringBuffer();
    headers?.forEach((key, value) {
      value.forEach((e) => stringBuffer.writeln('$key: $e'));
    });
    return stringBuffer.toString();
  }

  /// 将[body]转换为显示字符串
  dynamic get _bodyToString => data is List<int> ? 'bytes ${data.length}' : data;

  @override
  String toString() => '''response 
success: $success; code: $statusCode;
headers: $_headersToString;
body: $_bodyToString''';
}

/// 描述要上传的文件信息
class UploadFileInfo {
  UploadFileInfo._raw({this.stream, this.length, this.filePath, this.fileName, this.mimeType});

  /// 使用[filePath]创建上传文件
  ///
  /// 仅native端支持
  factory UploadFileInfo(String filePath, {String? fileName, String? mimeType}) {
    fileName ??= basename(filePath);

    mimeType ??= lookupMimeType(fileName);

    return UploadFileInfo._raw(stream: null, filePath: filePath, fileName: fileName, mimeType: mimeType);
  }

  /// 使用文件的字节流[bytes]创建上传文件
  factory UploadFileInfo.bytes(List<int> bytes, {String? fileName, String? mimeType}) {
    return UploadFileInfo._raw(
        stream: Stream.fromIterable([bytes]),
        length: bytes.length,
        filePath: null,
        fileName: fileName,
        mimeType: mimeType);
  }

  /// 使用文件的字节流[stream]创建上传文件
  factory UploadFileInfo.stream(Stream<List<int>> stream, int length, {String? fileName, String? mimeType}) {
    return UploadFileInfo._raw(stream: stream, length: length, filePath: null, fileName: fileName, mimeType: mimeType);
  }

  /// 文件字节流
  ///
  /// web端仅支持此模式上传
  /// native端如果[stream]不为null则会忽略[filePath]
  final Stream<List<int>>? stream;

  /// [stream]中的文件字节流长度
  final int? length;

  /// 文件路径（不支持web）
  final String? filePath;

  /// 文件名
  ///
  /// 带后缀，用于表示要上传的文件名称，覆盖[filePath]中的文件名
  final String? fileName;

  /// 要上传的文件mime类型
  final String? mimeType;

  @override
  String toString() => "UploadFileInfo:'$filePath' fileName:$fileName mimeType:$mimeType";
}

/// 用于[json_annotation]库序列化标记需要上传的文件类型参数转换
///
/// 支持[File]和[UploadFileInfo]类型标记
/// 通常标记为 @JsonKey(toJson: workFileToJsonConvert)
dynamic workFileToJsonConvert(dynamic file) => file;

/// http请求类型
enum HttpMethod {
  /// get请求
  get,

  /// post请求
  post,

  /// put请求
  put,

  /// delete请求
  delete,

  /// head请求
  head,

  /// patch请求
  patch,
}

/// 为[HttpMethod]扩展方法
extension HttpMethodExtension on HttpMethod {
  /// 对应的http方法名称
  String get name {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.head:
        return 'HEAD';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
    }
  }
}

/// Work的异常类型
enum WorkErrorType {
  /// 任务传入参数错误
  params,

  /// 连接超时
  connectTimeout,

  /// 发送超时
  sendTimeout,

  /// 接收超时
  receiveTimeout,

  /// 服务器返回错误，4xx,5xx
  response,

  /// 用户取消请求
  cancel,

  /// 业务任务执行错误（应用业务逻辑失败）
  task,

  /// 响应数据解析错误
  parse,

  /// 一些其他异常，可能是网络库或其他数据处理异常
  other,
}
