// Created by 超悟空 on 2021/5/10.

import 'dart:convert';

import 'package:work/work.dart';

/// 一个简单的任务基类
abstract class BaseWork<D> extends Work<D, WorkData<D>> {
  const BaseWork();

  @override
  WorkData<D> onCreateWorkData() => WorkData<D>.create();

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
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl(WorkData<String> data) => '/get';
}

/// 简单的post form任务
class SimplePostFormWork extends BaseWork<String> {
  SimplePostFormWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod(WorkData<String> data) => HttpMethod.post;

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['form'].toString();

  @override
  String onUrl(WorkData<String> data) => '/post';
}

/// 简单的post json任务
class SimplePostJsonWork extends BaseWork<String> {
  SimplePostJsonWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod(WorkData<String> data) => HttpMethod.post;

  @override
  String? onContentType(WorkData<String> data) => 'application/json';

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['json'].toString();

  @override
  String onUrl(WorkData<String> data) => '/post';
}

/// 简单的put任务附加查询参数
class SimplePutWithQueryWork extends BaseWork<String> {
  SimplePutWithQueryWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod(WorkData<String> data) => HttpMethod.put;

  @override
  String? onContentType(WorkData<String> data) => 'application/json';

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
      };

  @override
  FutureOr<Map<String, dynamic>?> onQueryParams(WorkData<String> data) => {
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      '${data.response!.data['json']}\n${data.response!.data['args']}';

  @override
  String onUrl(WorkData<String> data) => '/put';
}

/// 简单的post json字符串任务
class SimplePostJsonStringWork extends BaseWork<String> {
  SimplePostJsonStringWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod(WorkData<String> data) => HttpMethod.post;

  @override
  String? onContentType(WorkData<String> data) => 'application/json';

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) =>
      json.encode({'name': name, 'age': age});

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['json'].toString();

  @override
  String onUrl(WorkData<String> data) => '/post';
}

/// 总是解析失败的任务
class SimpleParseFailedWork extends BaseWork<int> {
  SimpleParseFailedWork(this.content);

  final String content;

  @override
  HttpMethod onHttpMethod(WorkData<int> data) => HttpMethod.post;

  @override
  String? onContentType(WorkData<int> data) => 'application/json';

  @override
  FutureOr<dynamic> onFillParams(WorkData<int> data) =>
      json.encode({'content': content});

  @override
  int? onRequestSuccessful(WorkData<int> data) =>
      data.response!.data['json']['content'];

  @override
  String? onParseFailed(WorkData<int> data) => '数据解析错误';

  @override
  String onUrl(WorkData<int> data) => '/post';
}

/// 总是返回500的任务
class SimpleErrorWork extends BaseWork<void> {
  @override
  FutureOr<dynamic> onFillParams(WorkData<void> data) => null;

  @override
  void onRequestSuccessful(WorkData<void> data) => null;

  @override
  String onUrl(WorkData<void> data) => '/status/500';
}

/// 总是业务失败的任务
class SimpleRequestFailedWork extends BaseWork<void> {
  @override
  bool onRequestResult(WorkData<void> data) => false;

  @override
  FutureOr<dynamic> onFillParams(WorkData<void> data) => null;

  @override
  void onRequestSuccessful(WorkData<void> data) => null;

  @override
  String onUrl(WorkData<void> data) => '/get';
}

/// 简单的上传任务
class SimpleUploadWork extends BaseWork<void> {
  SimpleUploadWork(this.buffer, {this.name, this.mimeType});

  final List<int> buffer;

  final String? name;

  final String? mimeType;

  @override
  HttpMethod onHttpMethod(WorkData<void> data) => HttpMethod.post;

  @override
  String? onContentType(WorkData<void> data) => multipartFormData;

  @override
  FutureOr<dynamic> onFillParams(WorkData<void> data) => {
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
  String onUrl(WorkData<void> data) => '/post';
}

/// 简单的下载任务
class SimpleLoadWork extends Work<List<int>, WorkData<List<int>>> {
  @override
  WorkData<List<int>> onCreateWorkData() => WorkData<List<int>>.create();

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
  ResponseType? onResponseType(WorkData<List<int>> data) => ResponseType.bytes;

  @override
  FutureOr<dynamic> onFillParams(WorkData<List<int>> data) => null;

  @override
  List<int>? onRequestSuccessful(WorkData<List<int>> data) =>
      data.response!.data;

  @override
  String onUrl(WorkData<List<int>> data) => '/image/webp';
}

/// 简单的延迟任务
class DelayWork extends BaseWork<String> {
  DelayWork(this.name, this.age, this.delay);

  final String name;

  final int age;

  final int delay;

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl(WorkData<String> data) => '/delay/$delay';
}

/// 假设这是个本地缓存数据库
final _caches = <int, String?>{};

/// 简单的可缓存任务
class CacheableWork extends BaseWork<String> {
  CacheableWork(this.id, this.name, this.age);

  final String name;

  final int age;

  final int id;

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl(WorkData<String> data) => '/get';

  @override
  FutureOr<bool> onHitCache(WorkData<String> data) {
    return _caches[id] != null;
  }

  @override
  FutureOr<String?> onFromCache(WorkData<String> data) {
    return _caches[id];
  }

  @override
  String? onFromCacheMessage(WorkData<String> data) => '本地缓存命中成功';

  @override
  bool onSuccessful(WorkData<String> data) {
    _caches[id] = data.result;
    return false;
  }
}

/// 当首次请求失败后从缓存加载的任务
class CacheableByFailedWork extends BaseWork<String> {
  CacheableByFailedWork(this.id, this.name, this.age);

  final String name;

  final int age;

  final int id;

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  bool onRequestResult(WorkData<String> data) {
    return super.onRequestResult(data) && _caches[id] == null;
  }

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['args'].toString();

  @override
  String onUrl(WorkData<String> data) => '/get';

  @override
  FutureOr<bool> onHitCache(WorkData<String> data) {
    return data.extra != null;
  }

  @override
  FutureOr<String?> onFromCache(WorkData<String> data) {
    return data.extra;
  }

  @override
  String? onFromCacheMessage(WorkData<String> data) => '本地缓存命中成功';

  @override
  FutureOr<bool> onFailed(WorkData<String> data) {
    data.extra = _caches[id];
    return _caches[id] != null;
  }

  @override
  bool onSuccessful(WorkData<String> data) {
    _caches[id] = data.result;
    return false;
  }
}

/// 重执行任务
class RestartWork extends BaseWork<String> {
  RestartWork(this.name, this.age);

  final String name;

  final int age;

  @override
  HttpMethod onHttpMethod(WorkData<String> data) => HttpMethod.post;

  @override
  String? onContentType(WorkData<String> data) => 'application/json';

  @override
  FutureOr<dynamic> onFillParams(WorkData<String> data) => {
        'name': name,
        'age': age,
      };

  @override
  String? onRequestSuccessful(WorkData<String> data) =>
      data.response!.data['json'].toString();

  @override
  String onUrl(WorkData<String> data) => '/get';

  @override
  FutureOr<void> onConfigOptions(
      WorkData<String> data, WorkRequestOptions options) {
    if (data.restartCount > 0) {
      options.url = '/post';
    }
  }

  @override
  FutureOr<bool> onFailed(WorkData<String> data) {
    return data.restartCount == 0;
  }
}
