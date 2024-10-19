import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/flat_list.dart';
import 'package:flutter/foundation.dart';

class PacketProfile {
  final int totalSize;
  final int bodySize;
  final int totalPackets;
  final int seq;

  PacketProfile({
    required this.totalSize,
    required this.bodySize,
    required this.totalPackets,
    required this.seq,
  })  : assert(bodySize > 0),
        assert(seq > 0),
        assert(totalPackets >= seq),
        assert(totalSize >= bodySize);
}

class DataPacketSplitter extends StreamTransformerBase<Uint8List, Uint8List> {
  List<int>? _delimiter;
  late int _useComputeThreshold;
  Duration? delayed;

  String? get delimiter => _delimiter == null ? null : utf8.decode(_delimiter!);
  final FlatList<int> _flatBuffer = FlatList();
  List<int> _bytesBuffer = Uint8List(0);
  PacketProfile? _remainingPacket;
  int _lastSeq = 1;

  void _clearBuffer() {
    _bytesBuffer = [];
    _lastSeq = 1;
    _remainingPacket = null;
  }

  void _addBuffer(Iterable<int> buffer, int packetSize) {
    _bytesBuffer.addAll(buffer);
  }

  set delimiter(String? value) {
    if (value == null) {
      _delimiter = null;
      return;
    }
    _delimiter = utf8.encode(value);
  }

  set useComputeThreshold(int value) {
    assert(value > 0);
    _useComputeThreshold = value;
  }

  final _controller = StreamController<Uint8List>();

  DataPacketSplitter(
    String? delimiter,
    int useComputeThreshold, [
    this.delayed,
  ]) {
    this.delimiter = delimiter;
    this.useComputeThreshold = useComputeThreshold;
  }

  Future _queue = Future.value();

  // final Lock _lock = Lock(); // 创建互斥锁
  Uint8List _headerBuffer = Uint8List(0);

  Future<void> _processUint8Buffer(Uint8List packet) async {
    int lastReadEnd = 0;
    if (_headerBuffer.isNotEmpty) {
      var tmp = Uint8List(_headerBuffer.length + packet.length);
      tmp.setAll(0, _headerBuffer);
      tmp.setAll(_headerBuffer.length, packet);
      packet = tmp;
      _headerBuffer = Uint8List(0);
    }
    while (lastReadEnd < packet.length) {
      if (packet.length < Constants.packetHeaderSize) {
        _headerBuffer = packet;
        return;
      }
      int totalSize = 0, bodySize = 0, totalPackets = 0, seq = 0, readStart = 0;
      var isStickyRemaining = _remainingPacket != null;
      //上次有粘包截断了部分数据
      if (_remainingPacket != null) {
        totalSize = _remainingPacket!.totalSize;
        bodySize = _remainingPacket!.bodySize;
        totalPackets = _remainingPacket!.totalPackets;
        seq = _remainingPacket!.seq;
        _remainingPacket = null;
      } else {
        ByteData header = ByteData.sublistView(
          packet,
          lastReadEnd,
          lastReadEnd + Constants.packetHeaderSize,
        );
        totalSize = header.getUint32(0, Endian.big);
        bodySize = header.getUint16(4, Endian.big);
        totalPackets = header.getUint16(6, Endian.big);
        seq = header.getUint16(8, Endian.big);
        readStart = lastReadEnd + Constants.packetHeaderSize;
        if (seq != 1 && _lastSeq + 1 != seq) {
          throw Exception("seq error, lastSeq is $_lastSeq, current is $seq");
        }
        _lastSeq = seq;
      }
      if (readStart >= packet.length) {
        _clearBuffer();
        throw Exception(
            "error: index out of range ${packet.length}, readStart:$readStart");
      }
      int readEnd = lastReadEnd = readStart + bodySize;
      //判断数据是否完整
      if (readEnd > packet.length) {
        if (totalPackets < seq) {
          _clearBuffer();
          throw Exception("totalPackets $totalPackets less than seq $seq");
        }
        //更新读取结束位置为包尾
        readEnd = lastReadEnd = packet.length;
        //记录粘包数据
        _remainingPacket = PacketProfile(
          totalSize: totalSize,
          bodySize: bodySize - (readEnd - readStart),
          totalPackets: totalPackets,
          seq: seq,
        );
      }
      //读取本次数据
      Uint8List packetData = packet.sublist(readStart, readEnd);
      if (seq == 1 && !isStickyRemaining) {
        //初始化大小
        _bytesBuffer = [];
      }
      if (seq != 1 && _bytesBuffer.isEmpty) {
        _clearBuffer();
        throw Exception("error: invalid seq $seq for empty data");
      }
      //添加到缓冲区
      _addBuffer(packetData, bodySize);
      // print(
      //   "totalSize:$totalSize, len: ${packetData.length},seq: $seq, totalPackets: $totalPackets",
      // );
      //没有读到最后一个包 或者 此包粘包跳过
      if (seq != totalPackets || _remainingPacket != null) continue;
      if (_bytesBuffer.length != totalSize) {
        String msg =
            "Buffer size ${_bytesBuffer.length} does not match the total size $totalSize.";
        _clearBuffer();
        throw Exception(msg);
      }
      //缓冲区完成，发送数据
      var buffer = _bytesBuffer;
      _clearBuffer();
      _controller.add(Uint8List.fromList(buffer));
    }
  }

  @override
  Stream<Uint8List> bind(Stream<Uint8List> stream) {
    stream.listen(
      (data) {
        _queue = _queue.whenComplete(() => _processUint8Buffer(data));
      },
      onDone: () {
        _controller.close();
      },
      onError: (error) {
        _controller.addError(error);
        _controller.close();
      },
    );
    return _controller.stream;
  }
}
