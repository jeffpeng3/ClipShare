import 'dart:io';

import 'package:clipshare/components/empty_content.dart';
import 'package:clipshare/components/loading.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pinput/pinput.dart';

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
  int _current = 1;
  int _total = 1;
  bool _initFinished = false;
  late History _history;
  bool _error = false;
  var checkedList = <int>{};

  @override
  void initState() {
    super.initState();
    _history = widget.clip.data;
    AppDb.inst.historyDao.getAllImagesCnt(App.userId).then(
      (cnt) {
        AppDb.inst.historyDao
            .getImageSeqDesc(_history.id, App.userId)
            .then((seq) {
          if (seq == null || seq <= 0) {
            _error = true;
          }
          _total = cnt!;
          _current = seq!;
          _initFinished = true;
          setState(() {});
        }).catchError(
          (e) {
            setState(() {
              _error = true;
              _initFinished = true;
            });
          },
        );
      },
    ).catchError(
      (e) {
        setState(() {
          _error = true;
          _initFinished = true;
        });
      },
    );
  }

  void _loadImage(bool pre) {
    AppDb.inst.historyDao
        .getImageBrotherById(
      _history.id,
      App.userId,
      pre ? 1 : 0,
    )
        .then(
      (data) {
        if (data == null) {
          _error = true;
          _initFinished = true;
          setState(() {});
          return;
        }
        _history = data;
        _current += pre ? -1 : 1;
        setState(() {});
      },
    );
  }

  void _loadPreImage() {
    if (_current <= 1) return;
    _loadImage(true);
  }

  void _loadNextImage() {
    if (_current >= _total) return;
    _loadImage(false);
  }

  @override
  Widget build(BuildContext context) {
    var header = SizedBox(
      height: 48,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            IconButton(
              hoverColor: Colors.white12,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: GestureDetector(
                      child: Text(
                        _error ? "error" : _history.content,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onLongPress: () {
                        Clipboard.setData(
                          ClipboardData(text: _history.content),
                        );
                        Global.snackBarSuc(context, "复制路径成功");
                      },
                    ),
                  ),
                  Text(
                    _error ? "error" : _history.time,
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 5,
            ),
          ],
        ),
      ),
    );
    var footer = SizedBox(
      height: 48,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            const SizedBox(
              width: 15,
            ),
            Checkbox(
              value: _error ? false : checkedList.contains(_history.id),
              hoverColor: Colors.white12,
              onChanged: _error
                  ? null
                  : (checked) {
                      if (checked == null || !checked) {
                        checkedList.remove(_history.id);
                      } else {
                        checkedList.add(_history.id);
                      }
                      setState(() {});
                    },
              side: const BorderSide(color: Colors.white70),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Center(
                child: Visibility(
                  visible: _total > 0,
                  child: Text(
                    "$_current/$_total",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _error ? null : () => {},
              hoverColor: Colors.white12,
              icon: const Icon(
                Icons.share,
                color: Colors.white,
                size: 15,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, ct) {
              return SizedBox(
                width: ct.maxWidth,
                height: ct.maxHeight,
                child: _initFinished
                    ? Stack(
                        children: [
                          GestureDetector(
                            child: InteractiveViewer(
                              maxScale: 15.0,
                              transformationController: _controller,
                              child: _error
                                  ? const EmptyContent()
                                  : Image.file(
                                      File(_history.content),
                                      width: ct.maxWidth,
                                      height: ct.maxHeight,
                                    ),
                            ),
                            onTap: () {},
                            onSecondaryTap: () => Navigator.pop(context),
                            onDoubleTap: () {
                              _toggleZoom(context.size!.center(Offset.zero));
                            },
                          ),
                          header,
                          Visibility(
                            visible: _current > 1 && !_error,
                            child: Positioned(
                              left: 10,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                    child: IconButton(
                                      hoverColor: Colors.white12,
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed:
                                          _current <= 1 ? null : _loadPreImage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _current < _total && !_error,
                            child: Positioned(
                              right: 10,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                    child: IconButton(
                                      hoverColor: Colors.white12,
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: _current >= _total
                                          ? null
                                          : _loadNextImage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: footer,
                          ),
                        ],
                      )
                    : const Loading(),
              );
            },
          ),
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
