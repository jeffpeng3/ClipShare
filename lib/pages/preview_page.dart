import 'dart:io';

import 'package:clipshare/entity/clip_data.dart';
import 'package:flutter/material.dart';

class PreviewPage extends StatefulWidget {
  final ClipData clip;

  const PreviewPage({super.key, required this.clip});

  @override
  State<StatefulWidget> createState() {
    return _PreviewPageState();
  }
}

class _PreviewPageState extends State<PreviewPage> {
  final TransformationController _controller = TransformationController();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.black,
        child: InkWell(
          child: InteractiveViewer(
            maxScale: 15.0,
            transformationController: _controller,
            child: Image.file(File(widget.clip.data.content)),
          ),
          onTap: () {
            Navigator.pop(context);
          },
          onDoubleTap: () {
            _toggleZoom(context.size!.center(Offset.zero));
          },
        ),
      ),
    );
  }

  void _toggleZoom(Offset focalPoint) {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else {
      _controller.value = Matrix4.identity()
        //这里的系数=1-新的放大倍数
        ..translate(-1.5 * focalPoint.dx, -1.5 * focalPoint.dy)
        ..scale(2.5, 2.5);
    }
  }
}
