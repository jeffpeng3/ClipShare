import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/widgets/pages/guide/base_guide.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserGuide extends StatefulWidget {
  final List<BaseGuide> guides;

  const UserGuide({super.key, required this.guides});

  @override
  State<StatefulWidget> createState() {
    return _UserGuideState();
  }
}

class _UserGuideState extends State<UserGuide> with WidgetsBindingObserver {
  int _current = 0;
  bool _canNext = false;
  bool _initFinished = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.guides.isEmpty) {
      gotoHomePage();
      return;
    }
    var f = Future(() => true);
    //只要有一个返回false就要走引导，如果全部返回true，直接跳转主页
    for (var guide in widget.guides) {
      f = f.then((v) {
        if (v != true) return false;
        return guide.canNext();
      });
    }
    f.then((v) {
      if (v) {
        gotoHomePage();
      } else {
        setState(() {
          _initFinished = true;
        });
      }
    });
    if (widget.guides.isNotEmpty) {
      widget.guides[_current].canNext().then((v) {
        _canNext = v;
        setState(() {});
      });
    }
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      var canNext = await widget.guides[_current].canNext();
      setState(() {
        _canNext = canNext;
      });
    }
  }

  ///跳转上一项
  void gotoPre() async {
    if (_current != 0) {
      _current -= 1;
      await updateCanNext();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease,
      );
      setState(() {});
    }
  }

  Future<void> updateCanNext() async {
    _canNext = await widget.guides[_current].canNext() ||
        widget.guides[_current].allowSkip;
    setState(() {});
  }

  ///跳转下一项
  void gotoNext() async {
    if (_current != widget.guides.length - 1) {
      //允许下一步
      if (_canNext || widget.guides[_current].allowSkip) {
        _current += 1;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.ease,
        );
        await updateCanNext();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return !_initFinished
        ? const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
              ),
            ),
          )
        : Scaffold(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.guides[_current].allowSkip
                            ? () async {
                                if (_current == widget.guides.length - 1) {
                                  //跳转到首页
                                  gotoHomePage();
                                } else {
                                  gotoNext();
                                }
                              }
                            : null,
                        child: Text(
                          widget.guides[_current].allowSkip && !_canNext
                              ? "跳过此项"
                              : "",
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      pageSnapping: true,
                      onPageChanged: (idx) async {
                        if (idx > _current && !_canNext) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease,
                          );
                          return;
                        }
                        _current = idx;
                        await updateCanNext();
                        setState(() {});
                      },
                      children: [
                        for (var idx = 0; idx < widget.guides.length; idx++)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [widget.guides[idx].widget],
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _current == 0 ? null : gotoPre,
                        child: const Text("上一步"),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < widget.guides.length; i++)
                              AnimatedContainer(
                                width: i == _current ? 36.0 : 16.0,
                                height: 16.0,
                                duration: const Duration(milliseconds: 200),
                                child: Center(
                                  child: AnimatedContainer(
                                    width: i == _current ? 30.0 : 10.0,
                                    height: 10.0,
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: i <= _current
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: TextButton(
                          onPressed: _canNext
                              ? () async {
                                  if (_current == widget.guides.length - 1) {
                                    gotoHomePage();
                                  } else {
                                    gotoNext();
                                  }
                                }
                              : null,
                          child: Text(
                            _current == widget.guides.length - 1 ? "完成" : "下一步",
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  void gotoHomePage() {
    Get.offNamed(Routes.home);
  }
}
