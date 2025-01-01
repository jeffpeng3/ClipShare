import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/environment_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EnvironmentSelections extends StatefulWidget {
  final void Function(EnvironmentType? selected) onSelected;
  final EnvironmentType? selected;

  const EnvironmentSelections({
    super.key,
    required this.onSelected,
    this.selected,
  });

  @override
  State<StatefulWidget> createState() => _EnvironmentSelectionsState();
}

class _EnvironmentSelectionsState extends State<EnvironmentSelections>
    with AutomaticKeepAliveClientMixin, ClipboardListener {
  EnvironmentType? _selectedEnv;
  bool requesting = false;
  EnvironmentType? requestingPerm;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    clipboardManager.addListener(this);
  }

  @override
  void onPermissionStatusChanged(EnvironmentType environment, bool isGranted) {
    Log.debug(
      "EnvironmentSelections",
      "onPermissionStatusChanged $environment $isGranted",
    );
    if (!requesting || requestingPerm != environment) return;
    //关闭等待弹窗
    Get.back();
    setState(() {
      requesting = false;
      requestingPerm = null;
    });
    if (isGranted) {
      setState(() {
        _selectedEnv = environment;
        widget.onSelected(_selectedEnv);
      });
    } else {
      if (environment == EnvironmentType.shizuku) {
        Global.showTipsDialog(
          context: context,
          title: '请求失败',
          text: "Shizuku 权限请求失败，请确保已启动Shizuku并重试",
          showCancel: false,
          onOk: () {
            Get.back();
          },
        );
      } else if (environment == EnvironmentType.root) {
        Global.showTipsDialog(
          context: context,
          title: '请求失败',
          text: "似乎没有 Root 权限，可选择 Shizuku 模式启动",
          showCancel: false,
        );
      }
    }
  }

  @override
  void onClipboardChanged(ClipboardContentType type, String content) {
    // TODO: implement onClipboardChanged
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        EnvironmentSelectionCard(
          selected: _selectedEnv == EnvironmentType.shizuku,
          icon: Image.asset(
            Constants.shizukuLogoPath,
            width: 48,
            height: 48,
          ),
          tipContent: Row(
            children: [
              const Text(
                "Shizuku 模式",
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              GestureDetector(
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blueGrey,
                  size: 20,
                ),
                onTap: () {
                  Global.showTipsDialog(
                    context: context,
                    text: "为保证正常授权，请确保将 Shizuku 添加到电池优化白名单并允许后台运行",
                    showCancel: false,
                  );
                },
              ),
            ],
          ),
          tipDesc: const Text(
            "无需 Root，需要安装 Shizuku，重启手机后需要重新激活",
            style: TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
          onTap: () {
            setState(() {
              requesting = true;
              requestingPerm = EnvironmentType.shizuku;
            });
            Global.showLoadingDialog(context: context, loadingText: '等待请求结果');
            clipboardManager.requestPermission(EnvironmentType.shizuku);
          },
        ),
        EnvironmentSelectionCard(
          selected: _selectedEnv == EnvironmentType.root,
          icon: Image.asset(
            Constants.rootLogoPath,
            width: 48,
            height: 48,
          ),
          tipContent: const Text(
            "Root模式",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tipDesc: const Text(
            "以 Root 权限启动，重启手机无需重新激活",
            style: TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
          onTap: () {
            setState(() {
              requesting = true;
              requestingPerm = EnvironmentType.root;
            });
            Global.showLoadingDialog(context: context, loadingText: '等待请求结果');
            clipboardManager.requestPermission(EnvironmentType.root);
          },
        ),
        EnvironmentSelectionCard(
          selected: _selectedEnv == EnvironmentType.none,
          onTap: () {
            setState(() {
              _selectedEnv = EnvironmentType.none;
              widget.onSelected.call(EnvironmentType.none);
              requestingPerm = null;
              requesting = false;
            });
          },
          icon: const Icon(
            Icons.block_outlined,
            size: 40,
            color: Colors.blueGrey,
          ),
          tipContent: const Text(
            "忽略",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tipDesc: const Text(
            "剪贴板将无法后台监听，只能被动同步",
            style: TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
        ),
      ],
    );
  }
}
