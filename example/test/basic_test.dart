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

      if (work.success) {
        print('work result ${work.result}');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }
    });

    test('post_form', () async {
      final work = await SimplePostFormWork('超悟空', 32).start();

      if (work.success) {
        print('work result ${work.result}');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }
    });

    test('post_json', () async {
      final work = await SimplePostJsonWork('超悟空', 32).start();

      if (work.success) {
        print('work result ${work.result}');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }
    });

    test('post_json_string', () async {
      final work = await SimplePostJsonStringWork('超悟空', 32).start();

      if (work.success) {
        print('work result ${work.result}');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }
    });

    test('retry', () async {
      final work = await SimpleErrorWork().start(retry: 5);

      if (!work.success) {
        print('work error ${work.errorType} message ${work.message}');
      }
    });

    test('download', () async {
      final work = await SimpleLoadWork().start(onReceiveProgress: (current, total) {
        print(current * 100 ~/ total);
      });

      if (work.success) {
        print('work result ${work.result!.length}');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }
    });

    test('upload', () async {
      final download = await SimpleLoadWork().start();

      final work = await SimpleUploadWork(download.result!, name: 'test.webp', mimeType: 'image/webp').start(
          onSendProgress: (current, total) {
        print(current * 100 ~/ total);
      });

      if (work.success) {
        print('work result success');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }
    });

    test('cancel', () async {
      final work = DelayWork('超悟空', 32, 5).start();

      work.then((value) {
        if (value.success) {
          print('work result ${value.result}');
        } else {
          print('work error ${value.errorType} message ${value.message}');
        }
      });

      await Future.delayed(Duration(seconds: 1));

      work.cancel();
    });

    test('cache', () async {
      var work = await CacheableWork(1, '超悟空', 32).start();

      if (work.success) {
        print('work result ${work.result}');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }

      work = await CacheableWork(1, '超悟空', 32).start();

      if (work.success) {
        print('work result ${work.result} cache ${work.fromCache} message ${work.message}');
      } else {
        print('work error ${work.errorType} message ${work.message}');
      }
    });
  });
}
