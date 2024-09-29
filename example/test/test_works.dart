// Created by 超悟空 on 2021/5/10.

import 'dart:convert';

import 'package:work/work.dart';

/// 全局生命周期代理，实现通用处理逻辑
class WorkDelegateImp extends WorkDelegate {
  const WorkDelegateImp();

  @override
  String? onParamsError(WorkData data) => '参数不合法';

  @override
  bool onRequestResult(WorkData data) => data.response!.data['headers'] != null;

  @override
  String? onRequestSuccessfulMessage(WorkData data) =>
      data.response!.data['origin'];

  @override
  String? onRequestFailedMessage(WorkData data) => '业务失败了';

  @override
  String? onNetworkError(WorkData data) => '网络错误';

  @override
  String? onNetworkRequestFailed(WorkData data) => '服务器错误';

  @override
  String? onParseFailed(WorkData data) => '数据解析错误';
}

/// 简单的get任务
class GetWork extends Work<String> {
  const GetWork(this.name, this.age);

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
class PostFormWork extends Work<String> {
  const PostFormWork(this.name, this.age);

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
class PostJsonWork extends Work<String> {
  const PostJsonWork(this.name, this.age);

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
class PutWithQueryWork extends Work<String> {
  const PutWithQueryWork(this.name, this.age);

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
class PostJsonStringWork extends Work<String> {
  const PostJsonStringWork(this.name, this.age);

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
class ParseFailedWork extends Work<int> {
  const ParseFailedWork(this.content);

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
class ErrorWork extends Work<void> {
  const ErrorWork();

  @override
  FutureOr<dynamic> onFillParams(WorkData<void> data) => null;

  @override
  void onRequestSuccessful(WorkData<void> data) {}

  @override
  String onUrl(WorkData<void> data) => '/status/500';
}

/// 总是业务失败的任务
class RequestFailedWork extends Work<void> {
  const RequestFailedWork();

  @override
  bool onRequestResult(WorkData<void> data) => false;

  @override
  FutureOr<dynamic> onFillParams(WorkData<void> data) => null;

  @override
  void onRequestSuccessful(WorkData<void> data) {}

  @override
  String onUrl(WorkData<void> data) => '/get';
}

/// 简单的上传任务
class UploadWork extends Work<void> {
  const UploadWork(this.buffer, {this.name, this.mimeType});

  final List<int> buffer;

  final String? name;

  final String? mimeType;

  @override
  HttpMethod onHttpMethod(WorkData<void> data) => HttpMethod.post;

  @override
  String? onContentType(WorkData<void> data) =>
      Headers.multipartFormDataContentType;

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
class DownloadWork extends Work<List<int>> {
  const DownloadWork();

  @override
  bool onRequestResult(WorkData<List<int>> data) => true;

  @override
  ResponseType? onResponseType(WorkData<List<int>> data) => ResponseType.bytes;

  @override
  FutureOr<dynamic> onFillParams(WorkData<List<int>> data) => null;

  @override
  List<int>? onRequestSuccessful(WorkData<List<int>> data) =>
      data.response!.data;

  @override
  String? onRequestSuccessfulMessage(WorkData data) => '下载成功';

  @override
  String onUrl(WorkData<List<int>> data) => '/image/webp';
}

/// 简单的延迟任务
class DelayWork extends Work<String> {
  const DelayWork(this.name, this.age, this.delay);

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
class CacheableWork extends Work<String> {
  const CacheableWork(this.id, this.name, this.age);

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
class CacheableByFailedWork extends Work<String> {
  const CacheableByFailedWork(this.id, this.name, this.age);

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
class RestartWork extends Work<String> {
  const RestartWork(this.name, this.age);

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
  FutureOr<void> onPostOptions(WorkData<String> data) {
    if (data.restartCount > 0) {
      data.options!.url = '/post';
    }
  }

  @override
  FutureOr<bool> onFailed(WorkData<String> data) {
    return data.restartCount == 0;
  }
}
