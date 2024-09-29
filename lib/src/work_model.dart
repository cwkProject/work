// Created by 超悟空 on 2018/9/20.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

/// 进度监听器
///
/// [current]为当前已传输字节，[total]为总传输字节
typedef OnProgress = void Function(int current, int total);

/// 任务请求的全部配置信息
class WorkRequestOptions {
  /// 用于取消本次请求的工具，由框架管理，和使用，用户不应对其进行任何操作
  final cancelToken = CancelToken();

  /// 完整的请求地址（包含http(s)://），或者是相对地址（需调用过[workConfig]设置全局dio根地址）
  late String url;

  /// [dio]中的请求选项，也是原始http请求的配置选项
  ///
  /// 在这里可以覆盖设置[Options.headers]，[Options.sendTimeout]，[Options.receiveTimeout]，[Options.responseType]等等
  final dioOptions = Options();

  /// 发送/上传进度监听器，在[HttpMethod.get]和[HttpMethod.head]以及设置了[downloadPath]的下载任务中无效
  ///
  /// 在[Work.start]中传入
  OnProgress? onSendProgress;

  /// 接收/下载进度监听器
  ///
  /// 在[Work.start]中传入
  OnProgress? onReceiveProgress;

  /// 用于发送的请求参数
  ///
  /// 通常在[Work.onFillParams]中装配并返回，此时框架会自动序列化参数，
  /// 支持[HttpMethod.get]和[HttpMethod.head]，
  /// 或者是带有请求body的方法中使用“application/x-www-form-urlencoded”或"application/json"，
  /// [Headers.multipartFormDataContentType]等与[Map]兼容的键值对或表单格式。
  ///
  /// 支持多种格式，通常有[Map]，[String]，[List]，[Stream]等，需要与[Options.contentType]匹配，
  /// 同样可以使用自行拼装的[FormData]数据
  dynamic params;

  /// 发送的请求查询参数
  ///
  /// 由[Work.onQueryParams]方法返回，
  /// 用于配合"POST","PUT","PATCH","DELETE"方法传递在url中的查询参数。
  ///
  /// 如果在"GET","HEAD"中此参数非null，则会覆盖[params]参数。
  Map<String, dynamic>? queryParams;

  /// 下载文件的本地存放路径
  ///
  /// 下载并保存到文件的快捷方式，web不支持此方式。
  /// 如果该值不为空，则本任务会被认为是一个下载任务，
  /// 框架会自动使用[Dio.download]方法执行下载任务。
  /// 可在[Work.onConfigOptions]中设置此属性，
  /// 此时[Work.onRequestResult]通常总是返回true
  String? downloadPath;

  @override
  String toString() => '''request 
method: ${dioOptions.method}
url: $url
headers: ${dioOptions.headers}
content-type: ${dioOptions.contentType}
params: $params
queryParams: $queryParams''';
}

/// 实际的Http响应数据
class HttpResponse {
  HttpResponse({
    required this.dioResponse,
    this.success = false,
    this.data,
  });

  /// 原始dio响应数据
  final Response dioResponse;

  /// 请求成功失败标志
  final bool success;

  /// 响应数据
  ///
  /// 通常数据类型由[Options.ResponseType]决定
  final dynamic data;

  /// 请求头信息
  Map<String, dynamic> get requestHeaders => dioResponse.requestOptions.headers;

  /// 响应头信息
  Map<String, List<String>> get headers => dioResponse.headers.map;

  /// 响应状态码
  int get statusCode => dioResponse.statusCode ?? 0;

  /// 最终请求的地址
  ///
  /// 可能是重定向后的地址
  Uri get realUri => dioResponse.realUri;

  /// 将头信息转换成文本输出
  String get _headersToString {
    final stringBuffer = StringBuffer();
    stringBuffer.writeln('{');
    headers.forEach((key, value) {
      for (var e in value) {
        stringBuffer.writeln('$key: $e');
      }
    });
    stringBuffer.write('}');
    return stringBuffer.toString();
  }

  /// 将[body]转换为显示字符串
  dynamic get _bodyToString =>
      data is List<int> ? 'bytes ${data.length}' : data;

  @override
  String toString() => '''response 
realUri: $realUri
request headers: $requestHeaders
success: $success; code: $statusCode
response headers: $_headersToString
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
    mimeType ??= fileName != null ? lookupMimeType(fileName) : null;
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
    mimeType ??= fileName != null ? lookupMimeType(fileName) : null;
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
  get('GET'),

  /// POST请求
  post('POST'),

  /// PUT请求
  put('PUT'),

  /// DELETE请求
  delete('DELETE'),

  /// HEAD请求
  head('HEAD'),

  /// PATCH请求
  patch('PATCH');

  const HttpMethod(this.name);

  /// 对应的http方法名称
  final String name;
}

/// Work的异常类型
enum WorkErrorType {
  /// 任务传入参数错误
  ///
  /// 可能是[Work.onCheckParams]未通过，或者是url不合法
  params,

  /// 连接超时
  connectionTimeout,

  /// 发送超时
  sendTimeout,

  /// 接收超时
  receiveTimeout,

  /// 服务器响应错误，4xx,5xx
  response,

  /// socket连接失败
  connection,

  /// 证书错误
  certificate,

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

  /// [WorkData.result]为null
  ///
  /// 目前仅在[WorkFuture.requiredResultOrThrow]和[WorkFuture.requiredResultOrThrowMessage]中可能抛出
  noResult,

  /// 一些其他异常，可能是网络库或其他数据处理异常
  other,
}
