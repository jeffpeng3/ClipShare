import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:clipshare/pages/nav/base_page.dart';
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
  int _i = 0;
  bool _canNext = false;

  @override
  void initState() {
    super.initState();
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
      widget.guides[0].canNext().then((v) {
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
      var canNext = await widget.guides[_i].canNext();
      setState(() {
        _canNext = canNext;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.guides[_i].allowSkip
                      ? () async {
                          if (_i == widget.guides.length - 1) {
                            //跳转到首页
                            gotoHomePage();
                          } else {
                            _i = _i + 1;
                            _canNext = await widget.guides[_i].canNext();
                            setState(() {});
                          }
                        }
                      : null,
                  child: Text(widget.guides[_i].allowSkip ? "跳过此项" : ""),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [widget.guides[_i].widget],
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _i == 0
                      ? null
                      : () async {
                          _i = _i - 1;
                          _canNext = await widget.guides[_i].canNext();
                          setState(() {});
                        },
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
                                color: i <= _i ? Colors.blue : Colors.grey,
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
                    onPressed: _canNext || widget.guides[_i].allowSkip
                        ? () async {
                            if (_i == widget.guides.length - 1) {
                              gotoHomePage();
                            } else {
                              _i = _i + 1;
                              _canNext = await widget.guides[_i].canNext();
                              setState(() {});
                            }
                          }
                        : null,
                    child: Text(_i == widget.guides.length - 1 ? "完成" : "下一步"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void gotoHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BasePage(title: 'ChipShare'),
      ),
    );
  }
}
