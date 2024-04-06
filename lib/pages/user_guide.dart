import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:clipshare/pages/nav/base_page.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

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
      _canNext = await widget.guides[_current].canNext();
      setState(() {});
    }
  }

  ///跳转下一项
  void gotoNext() async {
    if (_current != widget.guides.length - 1) {
      //允许下一步
      if (_canNext || widget.guides[_current].allowSkip) {
        _current += 1;
        _canNext = await widget.guides[_current].canNext();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return !_initFinished
        ? Container()
        : GestureDetector(
            onHorizontalDragEnd: (details) async {
              Log.debug("onHorizontalDragEnd", details.primaryVelocity);
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! > 500) {
                Log.debug("onHorizontalDragEnd", "right");
                // right
                gotoPre();
              } else if (details.primaryVelocity! < -500) {
                // left
                Log.debug("onHorizontalDragEnd", "left");
                gotoNext();
              }
            },
            child: Scaffold(
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
                              widget.guides[_current].allowSkip ? "跳过此项" : ""),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var idx = 0; idx < widget.guides.length; idx++)
                            Visibility(
                              visible: _current == idx,
                              child: widget.guides[_current].widget,
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
                                SizedBox(
                                  width: 16.0,
                                  height: 16.0,
                                  child: Center(
                                    child: Container(
                                      width: 10.0,
                                      height: 10.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
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
                            onPressed: _canNext ||
                                    widget.guides[_current].allowSkip
                                ? () async {
                                    if (_current == widget.guides.length - 1) {
                                      gotoHomePage();
                                    } else {
                                      gotoNext();
                                    }
                                  }
                                : null,
                            child: Text(
                              _current == widget.guides.length - 1
                                  ? "完成"
                                  : "下一步",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  void gotoHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BasePage(
          key: BasePage.pageKey,
        ),
      ),
    );
  }
}
