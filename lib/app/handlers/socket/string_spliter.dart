import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/exceptions/data_too_large_exception.dart';
import 'package:clipshare/app/utils/flat_list.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/foundation.dart';

class StringSplitter extends StreamTransformerBase<Uint8List, String> {
  late List<int> _delimiter;
  late int _useComputeThreshold;
  Duration? delayed;

  String get delimiter => utf8.decode(_delimiter);
  final FlatList<int> _buffer = FlatList();

  set delimiter(String value) {
    assert(value.isNotEmpty);
    _delimiter = utf8.encode(value);
  }

  set useComputeThreshold(int value) {
    assert(value > 0);
    _useComputeThreshold = value;
  }

  final controller = StreamController<String>();

  StringSplitter(String delimiter, int useComputeThreshold, [this.delayed]) {
    this.delimiter = delimiter;
    this.useComputeThreshold = useComputeThreshold;
  }

  static int _indexOfDelimiterStatic({
    required FlatList<int> buffer,
    required List<int> delimiter,
    required int useComputeThreshold,
    bool useCompute = false,
  }) {
    for (int i = 0; i <= buffer.length - delimiter.length; i++) {
      bool isEqual = true;
      if (!useCompute && i > useComputeThreshold) {
        throw DataTooLargeException(
          "Buffer size exceeds $useComputeThreshold, use compute",
        );
      }
      for (int j = 0; j < delimiter.length; j++) {
        if (buffer[i + j] != delimiter[j]) {
          isEqual = false;
          break;
        }
      }
      if (isEqual) {
        return i;
      }
    }
    return -1;
  }

  Future _queue = Future.value();

  void _processBuffer() async {
    if (_buffer.isEmpty) return;
    int index = -1;
    do {
      try {
        index = _indexOfDelimiterStatic(
          buffer: _buffer,
          delimiter: _delimiter,
          useComputeThreshold: _useComputeThreshold,
        );
      } on DataTooLargeException catch (e) {
        index = await compute(
          (dynamic params) => _indexOfDelimiterStatic(
            buffer: params[0],
            delimiter: params[1],
            useComputeThreshold: params[2],
            useCompute: true,
          ),
          [_buffer, _delimiter, _useComputeThreshold],
        );
      }
      if (index != -1) {
        List<int> chunk = _buffer.sublist(0, index);
        // print("chunk length: ${chunk.length}/${_buffer.length}");
        _buffer.removeRange(0, index + _delimiter.length);
        // print("after remove:${_buffer.length}");
        final useCompute = chunk.length > 1024 * 1024;
        String result;
        if (useCompute) {
          result = await compute((data) => utf8.decode(data), chunk);
        } else {
          result = utf8.decode(chunk);
        }
        controller.add(result);
        if (delayed != null) {
          await Future.delayed(delayed!);
        }
      }
    } while (index != -1);
  }

  @override
  Stream<String> bind(Stream<Uint8List> stream) {
    stream.listen(
      (data) {
        _buffer.add(data);
        _queue = _queue.whenComplete(() => _processBuffer());
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
