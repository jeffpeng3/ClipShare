import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/utils/flat_list.dart';
import 'package:flutter/foundation.dart';

class StringSplitter extends StreamTransformerBase<Uint8List, String> {
  late List<int> _delimiter;

  String get delimiter => utf8.decode(_delimiter);
  final FlatList<int> _buffer = FlatList();

  set delimiter(String value) {
    assert(value.isNotEmpty);
    _delimiter = utf8.encode(value);
  }

  final controller = StreamController<String>();

  StringSplitter(String delimiter) {
    this.delimiter = delimiter;
  }

  static int _indexOfDelimiterStatic(
    FlatList<int> buffer,
    List<int> delimiter,
  ) {
    for (int i = 0; i <= buffer.length - delimiter.length; i++) {
      if (buffer.sublist(i, i + delimiter.length).equals(delimiter)) {
        return i;
      }
    }
    return -1;
  }

  void _processBuffer() async {
    final useCompute = _buffer.length > 1024 * 1024;
    String? data;
    if (useCompute) {
      data = await compute((params) {
        return _processBufferStatic(
          params[0] as FlatList<int>,
          params[1] as List<int>,
        );
      }, [_buffer, _delimiter]);
    } else {
      data = _processBufferStatic(
        _buffer,
        _delimiter,
      );
    }
    if (data != null) {
      controller.add(data);
    }
  }

  static String? _processBufferStatic(
    FlatList<int> buffer,
    List<int> delimiter,
  ) {
    int index;
    if ((index = _indexOfDelimiterStatic(buffer, delimiter)) != -1) {
      List<int> chunk = buffer.sublist(0, index);
      buffer.removeRange(0, index + delimiter.length);
      return utf8.decode(chunk);
    }
    return null;
  }

  Future f = Future.value();

  @override
  Stream<String> bind(Stream<Uint8List> stream) {
    stream.listen(
      (data) {
        _buffer.add(data);
        f = f.whenComplete(() => _processBuffer());
      },
      onDone: () {
        controller.close();
      },
      onError: (error) {
        controller.addError(error);
        controller.close();
      },
    );
    return controller.stream;
  }
}
