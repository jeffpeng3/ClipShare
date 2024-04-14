import 'dart:math';

import 'package:flutter/cupertino.dart';

class LargeText extends StatefulWidget {
  final String text;
  final int blockSize;
  final double bottomThreshold;
  final Widget Function(String text) onThresholdChanged;

  const LargeText({
    super.key,
    required this.text,
    required this.blockSize,
    required this.bottomThreshold,
    required this.onThresholdChanged,
  }) : assert(bottomThreshold >= 0.0 && bottomThreshold <= 1.0);

  @override
  State<StatefulWidget> createState() {
    return _LargeTextState();
  }
}

class _LargeTextState extends State<LargeText> {
  late String _showText;
  late int _startPos;
  late int _endPos;
  final _controller = ScrollController();
  double _lastOffset = 0;
  bool updating = false;
  final cacheLength = 2;

  @override
  void initState() {
    super.initState();
    updating = false;
    _controller.addListener(_onScroller);
    _startPos = 0;
    _endPos = min(widget.blockSize * cacheLength, widget.text.length);
    _showText = widget.text.substring(_startPos, _endPos);
  }

  bool isScrolledToTop() {
    return _controller.offset == _controller.position.minScrollExtent;
  }

  bool isScrolledToBottom() {
    return _controller.offset == _controller.position.maxScrollExtent;
  }

  bool get canScroll => !isScrolledToTop() || !isScrolledToBottom();

  void _loadLess() {
    var start = _startPos;
    var end = _endPos;
    start = max(0, _startPos - widget.blockSize);
    end = min(_startPos + widget.blockSize, widget.text.length);
    if (start != _startPos || end != _endPos) {
      _startPos = start;
      _endPos = end;
      updateShowText();
    }
  }

  void _loadMore() {
    var start = _startPos;
    var end = _endPos;
    start = min(
      start + widget.blockSize,
      widget.text.length - widget.blockSize,
    );
    end = min(
      start + widget.blockSize * cacheLength,
      widget.text.length,
    );
    if (start != _startPos || end != _endPos) {
      _startPos = start;
      _endPos = end;
      updateShowText(true);
    }
  }

  void _onScroller() {
    if (widget.text.length < widget.blockSize * cacheLength) {
      return;
    }
    var current = _controller.offset;
    if (updating) {
      //更新上次滚动值
      _lastOffset = current;
      return;
    }
    updating = true;
    var maxScrollExtent = _controller.position.maxScrollExtent;
    var thresholdOffset = widget.bottomThreshold * maxScrollExtent;
    var before = _controller.position.extentBefore;
    var after = _controller.position.extentAfter;
    //向上/左滚动
    if (current - _lastOffset < 0) {
      if (before <= thresholdOffset) {
        _loadLess();
      }
    } else {
      //向下/右滚动
      if (after <= thresholdOffset) {
        _loadMore();
      }
    }
    //更新上次滚动值
    _lastOffset = current;
    updating = false;
  }

  void updateShowText([bool down = false]) {
    _showText = widget.text.substring(_startPos, _endPos);
    var pos = (down ? 1 - widget.bottomThreshold : widget.bottomThreshold);
    _controller.jumpTo(
      _controller.position.maxScrollExtent * pos,
    );
    if (down) {}
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!canScroll && _showText.length < widget.text.length) {
        _loadMore();
      }
    });
    return SingleChildScrollView(
      controller: _controller,
      child: widget.onThresholdChanged.call(_showText),
    );
  }
}
