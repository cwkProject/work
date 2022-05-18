// Created by 超悟空 on 2021/5/10.

import 'dart:convert';

import 'package:work/work.dart';

/// 一个简单的任务基类
abstract class BaseWork<D> extends Work<D, WorkData<D>> {
  @override
  WorkData<D> onCreateWorkData() => WorkData<D>();

  @override
  bool onRequestResult(WorkData<D> data) =>
      data.response!.data['headers'] != null;

  @override
  String? onRequestSuccessfulMessage(WorkData<D> data) =>
      data.response!.data['origin'];

  @override
  String? onRequestFailedMessage(WorkData<D> data) => '业务失败了';

  @override
  String? onNetworkError(WorkData<D> data) => '网络错误';

  @override
  String? onNetworkRequestFailed(WorkData<D> data) => '服务器错误';

  @override
  String? onParseFailed(WorkData<D> data) => '数据解析错误';
}

/// 简单的get任务
class SimpleGetWork extends BaseWork<String> {
  SimpleGetWork(this.name, this.age);

  final String name;

  final int age;

  @override
  Map<String, dynamic>? onFillParams() => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl() => '/get';
}

/// 简单的post form任务
class SimplePostFormWork extends BaseWork<String> {
  SimplePostFormWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod() => HttpMethod.post;

  @override
  Map<String, dynamic>? onFillParams() => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['form'].toString();

  @override
  String onUrl() => '/post';
}

/// 简单的post json任务
class SimplePostJsonWork extends BaseWork<String> {
  SimplePostJsonWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod() => HttpMethod.post;

  @override
  String? onContentType() => 'application/json';

  @override
  Map<String, dynamic>? onFillParams() => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['json'].toString();

  @override
  String onUrl() => '/post';
}

/// 简单的post json字符串任务
class SimplePostJsonStringWork extends BaseWork<String> {
  SimplePostJsonStringWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod() => HttpMethod.post;

  @override
  String? onContentType() => 'application/json';

  @override
  Map<String, dynamic>? onFillParams() => null;

  @override
  dynamic onPostFillParams(Map<String, dynamic>? data) =>
      json.encode({'name': name, 'age': age});

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['json'].toString();

  @override
  String onUrl() => '/post';
}

/// 总是返回500的任务
class SimpleErrorWork extends BaseWork<void> {
  @override
  Map<String, dynamic>? onFillParams() => null;

  @override
  void onRequestSuccessful(WorkData<void> data) => null;

  @override
  String onUrl() => '/status/500';
}

/// 总是业务失败的任务
class SimpleRequestFailedWork extends BaseWork<void> {
  @override
  bool onRequestResult(WorkData<void> data) => false;

  @override
  Map<String, dynamic>? onFillParams() => null;

  @override
  void onRequestSuccessful(WorkData<void> data) => null;

  @override
  String onUrl() => '/get';
}

/// 简单的上传任务
class SimpleUploadWork extends BaseWork<void> {
  SimpleUploadWork(this.buffer, {this.name, this.mimeType});

  final List<int> buffer;

  final String? name;

  final String? mimeType;

  @override
  HttpMethod onHttpMethod() => HttpMethod.post;

  @override
  String? onContentType() => multipartFormData;

  @override
  Map<String, dynamic>? onFillParams() => {
        'name': name,
        'file':
            UploadFileInfo.bytes(buffer, fileName: name, mimeType: mimeType),
      };

  @override
  bool onRequestResult(WorkData<void> data) =>
      data.response!.data['files']?.isNotEmpty == true;

  @override
  void onRequestSuccessful(WorkData<void> data) {}

  @override
  String onUrl() => '/post';
}

/// 简单的下载任务
class SimpleLoadWork extends Work<List<int>, WorkData<List<int>>> {
  @override
  WorkData<List<int>> onCreateWorkData() => WorkData<List<int>>();

  @override
  bool onRequestResult(WorkData<List<int>> data) => true;

  @override
  String? onRequestFailedMessage(WorkData<List<int>> data) => '业务失败了';

  @override
  String? onNetworkError(WorkData<List<int>> data) => '网络错误';

  @override
  String? onNetworkRequestFailed(WorkData<List<int>> data) => '服务器错误';

  @override
  String? onParseFailed(WorkData<List<int>> data) => '数据解析错误';

  @override
  ResponseType? onResponseType() => ResponseType.bytes;

  @override
  Map<String, dynamic>? onFillParams() => null;

  @override
  List<int>? onRequestSuccessful(WorkData<List<int>> data) =>
      data.response!.data;

  @override
  String onUrl() => '/image/webp';
}

/// 简单的延迟任务
class DelayWork extends BaseWork<String> {
  DelayWork(this.name, this.age, this.delay);

  final String name;

  final int age;

  final int delay;

  @override
  Map<String, dynamic>? onFillParams() => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl() => '/delay/$delay';
}

/// 简单的可缓存任务
class CacheableWork extends BaseWork<String> {
  CacheableWork(this.id, this.name, this.age);

  /// 假设这是个本地缓存数据库
  static final _caches = <int, String?>{};

  final String name;

  final int age;

  final int id;

  @override
  Map<String, dynamic>? onFillParams() => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl() => '/get';

  @override
  String? onStarted() => _caches[id];

  @override
  String? onFromCacheMessage() => '本地缓存命中成功';

  @override
  void onSuccessful(WorkData<String> data) {
    _caches[id] = data.result;
  }
}
