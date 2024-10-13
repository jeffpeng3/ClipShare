import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/material.dart';

class PermissionGuide extends StatefulWidget {
  final IconData icon;
  final String description;
  final String title;
  final void Function()? grantPerm;
  final Future<bool> Function()? checkPerm;
  final Widget Function(BuildContext context, bool hasPerm)? action;

  const PermissionGuide({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.grantPerm,
    this.checkPerm,
    this.action,
  });

  @override
  State<StatefulWidget> createState() {
    return _PermissionGuideState();
  }
}

class _PermissionGuideState extends State<PermissionGuide>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  bool _hasPerm = false;

  @override
  void initState() {
    super.initState();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    // 在构建完成后初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkPerm();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkPerm();
    }
  }

  void checkPerm() {
    widget.checkPerm?.call().then(
      (value) {
        if (mounted) {
          setState(() {
            _hasPerm = value;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget? action = widget.action?.call(context, _hasPerm);
    return Column(
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(
          height: 20,
        ),
        Icon(
          widget.icon,
          size: 60,
          color: Colors.blueAccent,
        ),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Text(widget.description),
        ),
        widget.grantPerm == null && widget.action == null
            ? const SizedBox.shrink()
            : const SizedBox(
                height: 30,
              ),
        action ??
            (widget.grantPerm == null
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: () {
                      if (!_hasPerm) {
                        widget.grantPerm!.call();
                      }
                    },
                    icon: _hasPerm
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                          )
                        : const SizedBox.shrink(),
                    label: Text(_hasPerm ? "已授权" : "去授权"),
                  )),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
