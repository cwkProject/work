// Created by 超悟空 on 2021/5/10.

import 'package:test/test.dart';
import 'package:work/work.dart';

import 'test_works.dart';

void main() {
  group('basic_test', () {
    setUp(() {
      debugWork = true;

      workConfig = WorkConfig(
        dio: Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            contentType: 'application/x-www-form-urlencoded',
            baseUrl: 'http://httpbin.org/',
          ),
        ),
        delegate: WorkDelegateImp(),
      );
    });

    test('get', () async {
      final work = await const GetWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });

    test('post_form', () async {
      final work = await const PostFormWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });

    test('post_json', () async {
      final work = await const PostJsonWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });

    test('put_with_query', () async {
      final work = await const PutWithQueryWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });

    test('post_json_string', () async {
      final work = await const PostJsonStringWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });

    test('retry', () async {
      final work = await const ErrorWork().start(retry: 5);

      print('work message ${work.message}');
      expect(work.success, isFalse);
      expect(work.errorType, same(WorkErrorType.response));
    });

    test('download', () async {
      final work =
          await const DownloadWork().start(onReceiveProgress: (current, total) {
        print(current * 100 ~/ total);
      });

      print('work result ${work.result?.length} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });

    test('upload', () async {
      final download = await const DownloadWork().start();

      final work = await UploadWork(download.result!,
              name: 'test.webp', mimeType: 'image/webp')
          .start(onSendProgress: (current, total) {
        print(current * 100 ~/ total);
      });

      print('work message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });

    test('cancel', () async {
      final work = const DelayWork('超悟空', 32, 5).start();

      Timer(Duration(seconds: 1), () {
        work.cancel();
      });

      final data = await work;

      print('work message ${data.message}');
      expect(data.success, isFalse);
      expect(data.errorType, same(WorkErrorType.cancel));
    });

    test('failed', () async {
      final work = await const RequestFailedWork().start();

      expect(work.success, isFalse);
      expect(work.errorType, same(WorkErrorType.task));
    });

    test('parseFailed', () async {
      final work = await const ParseFailedWork('测试解析错误').start();

      expect(work.success, isFalse);
      expect(work.errorType, same(WorkErrorType.parse));
    });

    test('cache', () async {
      var work = await const CacheableWork(1, '超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
      expect(work.fromCache, isFalse);

      work = await const CacheableWork(1, '超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
      expect(work.fromCache, isTrue);
    });

    test('cacheByFailed', () async {
      var work = await const CacheableByFailedWork(2, '超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
      expect(work.fromCache, isFalse);

      work = await const CacheableByFailedWork(2, '超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
      expect(work.fromCache, isTrue);
      expect(work.restartCount, equals(1));
    });

    test('restart', () async {
      final work = await const RestartWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      expect(work.success, isTrue);
      expect(work.errorType, isNull);
    });
  });
}
