// Created by 超悟空 on 2018/9/20.
// Version 1.0 2018/9/20
// Since 1.0 2018/9/20
import 'dart:math';

import 'work_config.dart';

/// 每次打印的最大长度
const _logBufferSize = 800;

/// 输出日志
///
/// [tag]日志标签，[message]日志内容，额外数据
void log(String tag, String message, [Object data]) {
  if (!debugWork) {
    return;
  }

  final finalMessage = '$message ${data ?? ''}';

  for (final it in _wrap(finalMessage)) {
    print('$tag: $it');
  }
}

/// 按换行父切割字符串为若干组
///
/// [src]原字符串
Iterable<String> _wrap(String src) sync* {
  final buffer = StringBuffer();

  for (final line in src.split('\n')) {
    for (final part in _chunked(line)) {
      if (buffer.length + part.length > _logBufferSize) {
        yield buffer.toString();
        buffer.clear();
      }

      buffer.write(part);
    }

    if (buffer.isNotEmpty) {
      yield buffer.toString();
      buffer.clear();
    }
  }
}

/// 按照指定大小将字符串截取成一组子字符串
///
/// [src]原字符串
Iterable<String> _chunked(String src) sync* {
  final length = src.length;

  var index = 0;
  while (index < length) {
    final end = index + _logBufferSize;
    final coercedEnd = min(length, end);
    yield src.substring(index, coercedEnd);

    index = coercedEnd;
  }
}
