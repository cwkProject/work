// Created by 超悟空 on 2018/9/20.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

import 'work_config.dart';

/// 进度监听器
///
/// [current]为当前已传输字节，[total]为总传输字节
typedef OnProgress = void Function(int current, int total);

/// Http执行器，每次调用都应该发起独立的新http请求并返回dio[Response]
///
/// 由[WorkRequest]生成，最终调用由框架负责
/// 请求中的异常请正常抛出
typedef HttpCall = Future<Response> Function();

/// 网络请求生成器
///
/// 用于装配请求参数并生成最终的请求方法[HttpCall]
/// [tag]为跟踪日志标签，[options]为请求所需的全部参数，返回最终的网络请求执行方法
typedef WorkRequest = Future<HttpCall> Function(
    String tag, WorkRequestOptions options);

/// 输出日志函数
///
/// [tag]日志标签，[message]日志内容，[data]额外数据
typedef WorkLogger = void Function(String tag, String? message, [Object? data]);

/// 多分块提交格式
///
/// 上传文件时需要使用此格式，
/// 框架负责将传入的[Map]数据自动装配成[FormData]格式，
/// 用户也可以将自行装配的[FormData]实例作为参数
const multipartFormData = 'multipart/form-data';

/// 任务请求的全部配置信息
class WorkRequestOptions {
  /// 用于取消本次请求的工具，由框架管理，和使用，用户不应对其进行任何操作
  final cancelToken = CancelToken();

  /// 完整的请求地址（包含http(s)://），或者是相对地址（需调用过[workConfig]设置全局dio根地址）
  late String url;

  /// Http请求方法
  HttpMethod method = HttpMethod.get;

  /// 发送/上传进度监听器，在[HttpMethod.get]和[HttpMethod.head]以及设置了[downloadPath]的下载任务中无效
  ///
  /// 在[Work.start]中传入
  OnProgress? onSendProgress;

  /// 接收/下载进度监听器
  ///
  /// 在[Work.start]中传入
  OnProgress? onReceiveProgress;

  /// 自定义/追加的Http请求头
  ///
  /// 通常在[Work.onHeaders]中设置
  Map<String, dynamic>? headers;

  /// 用于发送的请求参数
  ///
  /// 通常在[Work.onFillParams]中装配并返回，此时框架会自动序列化参数，
  /// 支持[HttpMethod.get]和[HttpMethod.head]，
  /// 或者是带有请求body的方法中使用“application/x-www-form-urlencoded”或"application/json"，
  /// [multipartFormData]等与[Map]兼容的键值对或表单格式。
  ///
  /// 此外可以在[Work.onPostFillParams]中覆盖参数，
  /// 支持多种格式，通常有[Map]，[String]，[Stream]等，需要与[contentType]匹配，
  /// 同样可以使用自行拼装的[FormData]数据
  dynamic params;

  /// 发送的请求查询参数
  ///
  /// 由[Work.onQueryParams]方法返回，
  /// 用于配合"POST","PUT","PATCH","DELETE"方法传递在url中的查询参数。
  ///
  /// 如果在"GET","HEAD"中此参数非null，则会覆盖[params]参数。
  Map<String, dynamic>? queryParams;

  /// 发送超时
  ///
  /// 传出流上前后两次发送数据的间隔，单位毫秒，
  /// 可在[Work.onConfigOptions]中覆盖此属性，
  /// 默认值为[WorkConfig.dio]中的设置。
  int? sendTimeout;

  /// 读取超时
  ///
  /// 响应流上前后两次接受到数据的间隔，单位毫秒
  /// 可在[Work.onConfigOptions]中覆盖此属性，
  /// 默认值为[WorkConfig.dio]中的设置。
  int? readTimeout;

  /// 请求的Content-Type
  ///
  /// 如果需要上传文件或表单提交，请将该值设置为[multipartFormData]，
  /// 框架会自动进行表单装配，参考[params]的描述，
  /// 可以在[Work.onContentType]中覆盖此属性，
  /// 默认值为[WorkConfig.dio]中的设置，框架默认'application/x-www-form-urlencoded'
  String? contentType;

  /// 表示期望以哪种格式(方式)接受响应数据
  ///
  /// 可以在[Work.onResponseType]中覆盖此属性，
  /// 默认值在[WorkConfig.dio]中设置，dio默认[ResponseType.json]。
  ResponseType? responseType;

  /// 下载文件的本地存放路径
  ///
  /// 下载并保存到文件的快捷方式，web不支持此方式。
  /// 如果该值不为空，则本任务会被认为是一个下载任务，
  /// 框架会自动使用[Dio.download]方法执行下载任务。
  /// 可在[Work.onConfigOptions]中设置此属性，
  /// 此时[Work.onRequestResult]通常总是返回true
  String? downloadPath;

  /// 用于指定使用的网络全局网络访问器的key
  ///
  /// 返回null或key不存在则表示使用默认访问器
  /// 关联性请查看[workConfigs]
  String? configKey;

  /// 在表单提交中自动装配数组使用的序列化格式
  ListFormat? listFormat;

  @override
  String toString() => '''request 
method: $method
url: $url
headers: $headers
params: $params
queryParams: $queryParams''';
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
  /// 通常数据类型由[ResponseType]决定
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
      for (var e in value) {
        stringBuffer.writeln('$key: $e');
      }
    });
    return stringBuffer.toString();
  }

  /// 将[body]转换为显示字符串
  dynamic get _bodyToString =>
      data is List<int> ? 'bytes ${data.length}' : data;

  @override
  String toString() => '''response 
success: $success; code: $statusCode
headers: $_headersToString
body: $_bodyToString''';
}

/// 上传文件时的包装格式
///
/// 用于描述要上传的文件信息
class UploadFileInfo {
  UploadFileInfo._raw(
      {this.stream, this.length, this.filePath, this.fileName, this.mimeType});

  /// 使用[filePath]创建上传文件
  ///
  /// 仅native端支持
  factory UploadFileInfo(String filePath,
      {String? fileName, String? mimeType}) {
    fileName ??= basename(filePath);

    mimeType ??= lookupMimeType(fileName);

    return UploadFileInfo._raw(
        stream: null,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType);
  }

  /// 使用文件的字节流[bytes]创建上传文件
  factory UploadFileInfo.bytes(List<int> bytes,
      {String? fileName, String? mimeType}) {
    return UploadFileInfo._raw(
        stream: Stream.fromIterable([bytes]),
        length: bytes.length,
        filePath: null,
        fileName: fileName,
        mimeType: mimeType);
  }

  /// 使用文件的字节流[stream]创建上传文件
  factory UploadFileInfo.stream(Stream<List<int>> stream, int length,
      {String? fileName, String? mimeType}) {
    return UploadFileInfo._raw(
        stream: stream,
        length: length,
        filePath: null,
        fileName: fileName,
        mimeType: mimeType);
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
  String toString() =>
      "UploadFileInfo:'${filePath ?? 'stream length:$length'}' fileName:$fileName mimeType:$mimeType";
}

/// 用于[json_annotation]库序列化标记需要上传的文件类型参数转换
///
/// 支持[File]和[UploadFileInfo]类型标记
/// 通常标记为 @JsonKey(toJson: workFileToJsonConvert)
dynamic workFileToJsonConvert(dynamic file) => file;

/// Http请求类型
enum HttpMethod {
  /// GET请求
  get,

  /// POST请求
  post,

  /// PUT请求
  put,

  /// DELETE请求
  delete,

  /// HEAD请求
  head,

  /// PATCH请求
  patch,
}

/// Work的异常类型
enum WorkErrorType {
  /// 任务传入参数错误
  ///
  /// 可能是[Work.onCheckParams]未通过，或者是url不合法
  params,

  /// 连接超时
  connectTimeout,

  /// 发送超时
  sendTimeout,

  /// 接收超时
  receiveTimeout,

  /// 服务器响应错误，4xx,5xx
  response,

  /// 用户取消请求
  cancel,

  /// 任务返回错误（应用业务逻辑失败）
  ///
  /// Http请求成功，但是[Work.onRequestResult]返回false。
  /// 通常代表了业务逻辑失败。
  task,

  /// 响应数据解析错误
  ///
  /// Http请求成功，但是读取响应数据时出错
  parse,

  /// 一些其他异常，可能是网络库或其他数据处理异常
  other,
}
