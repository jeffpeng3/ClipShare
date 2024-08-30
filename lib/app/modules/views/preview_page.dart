import 'dart:io';

import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
  var checkedList = <int>{};

  History get _currentImage =>
      _images.isEmpty ? widget.clip.data : _images[_current - 1];
  late PageController _pageController;

  bool get _canPre => _current > 1;

  bool get _canNext => _current < _total;
  final List<History> _images = List.empty(growable: true);

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  int _pointerCnt = 0;

  @override
  void initState() {
    super.initState();
    dbService.historyDao.getAllImages(appConfig.userId).then((images) {
      _images.addAll(images);
      _total = _images.length;
      var i = images.indexWhere((item) => item.id == widget.clip.data.id);
      _current = i + 1;
      _pageController = PageController(initialPage: i);
      _initFinished = true;
      setState(() {});
    });
  }

  Future<void> _loadPreImage() async {
    if (!_canPre) return;
    _current--;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
    setState(() {});
  }

  Future<void> _loadNextImage() async {
    if (!_canNext) return;
    _current++;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
    setState(() {});
  }

  Widget renderImageItem(int idx, BoxConstraints ct) {
    var file = File(_images[idx].content);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: ct.maxWidth,
        height: ct.maxHeight,
      );
    }
    return const EmptyContent(
      description: "图片不存在或已被删除",
    );
  }

  @override
  Widget build(BuildContext context) {
    var header = SizedBox(
      height: 48,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            const SizedBox(
              width: 15,
            ),
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
                        _currentImage.content,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onLongPress: () {
                        Clipboard.setData(
                          ClipboardData(text: _currentImage.content),
                        );
                        Global.showSnackBarSuc(context, "复制路径成功");
                      },
                    ),
                  ),
                  Text(
                    _currentImage.time,
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
              value: checkedList.contains(_currentImage.id),
              hoverColor: Colors.white12,
              onChanged: (checked) {
                if (checked == null || !checked) {
                  checkedList.remove(_currentImage.id);
                } else {
                  checkedList.add(_currentImage.id);
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
              onPressed: () => {},
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        // systemOverlayStyle: SystemUiOverlayStyle.light,
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
                            //listener解决PageView和InteractiveViewer之间的缩放与滚动冲突
                            child: Listener(
                              onPointerUp: (_) => setState(() {
                                _pointerCnt--;
                              }),
                              onPointerDown: (_) {
                                _pointerCnt++;
                                setState(() {});
                              },
                              child: PageView.builder(
                                itemCount: _images.length,
                                controller: _pageController,
                                physics: _pointerCnt == 2
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                onPageChanged: (idx) {
                                  _current = idx + 1;
                                  setState(() {});
                                },
                                itemBuilder: (ctx, idx) {
                                  return InteractiveViewer(
                                    maxScale: 15.0,
                                    onInteractionStart: (details) {
                                      print("onScaleStart");
                                    },
                                    transformationController: _controller,
                                    child: renderImageItem(idx, ct),
                                  );
                                },
                              ),
                            ),
                            onSecondaryTap: () => Navigator.pop(context),
                            onDoubleTap: () {
                              _toggleZoom(context.size!.center(Offset.zero));
                            },
                          ),
                          header,
                          Visibility(
                            visible: _canPre &&
                                MediaQuery.of(context).size.width >=
                                    Constants.smallScreenWidth,
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
                                      onPressed: _canPre ? _loadPreImage : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _canNext &&
                                MediaQuery.of(context).size.width >=
                                    Constants.smallScreenWidth,
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
                                      onPressed:
                                          _canNext ? _loadNextImage : null,
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

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: const Color.fromRGBO(245, 245, 245, 1),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}
