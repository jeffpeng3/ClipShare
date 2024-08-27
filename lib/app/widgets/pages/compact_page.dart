import 'dart:convert';
import 'dart:math';

import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/widgets/clip_data_card_compact.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CompactPage extends StatefulWidget {
  const CompactPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CompactPageState();
  }
}

class CompactClipData {
  final String devName;
  final ClipData data;

  const CompactClipData({required this.devName, required this.data});
}

class _CompactPageState extends State<CompactPage> {
  final ScrollController _scrollController = ScrollController();
  List<CompactClipData> _list = [];
  bool _loadNewData = false;
  bool _showBackToTopButton = false;
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();

  @override
  void initState() {
    super.initState();
    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
    //处理弹窗事件
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = jsonDecode(call.arguments);
      switch (call.method) {
        //更新通知
        case MultiWindowMethod.notify:
          refresh();
          break;
      }
      //都不符合，返回空
      return Future.value();
    });
    refresh();
  }

  void _scrollListener() {
    if (_scrollController.offset == 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _list = _list.sublist(0, min(_list.length, 20));
        setState(() {});
      });
    }
    // 判断是否快要滑动到底部
    if (_scrollController.position.extentAfter <= 200 && !_loadNewData) {
      refresh(true);
    }
    if (_scrollController.offset >= 300) {
      if (!_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = true;
        });
      }
    } else {
      if (_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = false;
        });
      }
    }
  }

  Future<void> refresh([bool loadMore = false]) {
    setState(() {
      _loadNewData = true;
    });
    return Future.delayed(const Duration(milliseconds: 500), () {
      var fromId = 0;
      if (loadMore) {
        fromId = _list.isEmpty ? 0 : _list.last.data.data.id;
      }
      return multiWindowChannelService.getHistories(0, fromId).then(
        (json) {
          var data = jsonDecode(json);
          var devInfos = data["devInfos"] as Map<String, dynamic>;
          var lst = History.fromJsonList(data["list"]);
          var res = List<CompactClipData>.empty(growable: true);
          for (var history in lst) {
            res.add(
              CompactClipData(
                devName: devInfos[history.devId] ?? "unknown",
                data: ClipData(history),
              ),
            );
          }
          setState(() {
            if (loadMore) {
              _list.addAll(res);
            } else {
              _list = res;
            }
            _loadNewData = false;
          });
        },
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      //这个刷新不知道为什么没效果
      body: RefreshIndicator(
        onRefresh: refresh,
        child: _list.isEmpty
            ? const EmptyContent()
            : ListView.builder(
                itemCount: _list.length,
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (ctx, idx) {
                  return ClipDataCardCompact(
                    devName: _list[idx].devName,
                    clip: _list[idx].data,
                  );
                },
              ),
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: const Icon(Icons.arrow_upward), // 可以选择其他图标
            )
          : null,
    );
  }
}
