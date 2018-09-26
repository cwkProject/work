// Created by 超悟空 on 2018/9/20.
// Version 1.0 2018/9/20
// Since 1.0 2018/9/20
import 'work_config.dart';

/// 每次打印的最大长度
const _logBufferSize = 1024 * 3;

/// 输出日志
///
/// [tag]日志标签，[message]日志内容，额外数据
void log(String tag, String message, [Object data]) {
  if (!debugWork) {
    return;
  }

  String finalMessage;
  if (data != null) {
    finalMessage = message + " " + data.toString();
  } else {
    finalMessage = message;
  }

  if (finalMessage.length <= _logBufferSize) {
    print(finalMessage);
  } else {
    final it = _chunked(finalMessage).iterator;
    while (it.moveNext()) {
      print(it.current);
    }
  }
}

/// 按照指定大小将字符串截取成一组子字符串
///
/// [src]原字符串，[size]截取的大小
Iterable<String> _chunked(String src) sync* {
  final length = src.length;

  var index = 0;
  while (index < length) {
    final end = index + _logBufferSize;
    final coercedEnd = end > length ? length : end;
    yield src.substring(index, coercedEnd);
    index += _logBufferSize;
  }
}
