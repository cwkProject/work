// Created by 超悟空 on 2021/5/10.

import 'package:test/test.dart';
import 'package:work/work.dart';

import 'test_works.dart';

void main() {
  group('basic_test', () {
    setUp(() {
      workConfig.dio.options.baseUrl = 'http://httpbin.org/';
    });

    test('get', () async {
      final work = await SimpleGetWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');

      assert(work.success);
      assert(work.errorType == null);
    });

    test('post_form', () async {
      final work = await SimplePostFormWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
    });

    test('post_json', () async {
      final work = await SimplePostJsonWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
    });

    test('put_with_query', () async {
      final work = await SimplePutWithQueryWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
    });

    test('post_json_string', () async {
      final work = await SimplePostJsonStringWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
    });

    test('retry', () async {
      final work = await SimpleErrorWork().start(retry: 5);

      print('work message ${work.message}');
      assert(!work.success);
      assert(work.errorType == WorkErrorType.response);
    });

    test('download', () async {
      final work =
          await SimpleLoadWork().start(onReceiveProgress: (current, total) {
        print(current * 100 ~/ total);
      });

      print('work result ${work.result?.length} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
    });

    test('upload', () async {
      final download = await SimpleLoadWork().start();

      final work = await SimpleUploadWork(download.result!,
              name: 'test.webp', mimeType: 'image/webp')
          .start(onSendProgress: (current, total) {
        print(current * 100 ~/ total);
      });

      print('work message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
    });

    test('cancel', () async {
      final work = DelayWork('超悟空', 32, 5).start();

      Timer(Duration(seconds: 1), () {
        work.cancel();
      });

      final date = await work;

      print('work message ${date.message}');
      assert(!date.success);
      assert(date.errorType == WorkErrorType.cancel);
    });

    test('failed', () async {
      final work = await SimpleRequestFailedWork().start();

      assert(!work.success);
      assert(work.errorType == WorkErrorType.task);
    });

    test('parseFailed', () async {
      final work = await SimpleParseFailedWork('测试解析错误').start();

      assert(!work.success);
      assert(work.errorType == WorkErrorType.parse);
    });

    test('cache', () async {
      var work = await CacheableWork(1, '超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
      assert(!work.fromCache);

      work = await CacheableWork(1, '超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
      assert(work.fromCache);
    });

    test('restart', () async {
      final work = await RestartWork('超悟空', 32).start();

      print('work result ${work.result} message ${work.message}');
      assert(work.success);
      assert(work.errorType == null);
    });
  });
}
