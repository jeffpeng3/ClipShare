import 'dart:convert';

import 'package:clipshare/components/rule_setting_add_dialog.dart';
import 'package:clipshare/components/settings/card/setting_card.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/settings/rules_setting_page.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/global.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

class TagRuleSettingPage extends StatelessWidget {
  const TagRuleSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RuleSettingPage(
      initData: jsonDecode(
        App.settings.tagRules,
      )["data"],
      onAdd: (data, remove) {
        var tag = data["name"] as String?;
        var rule = data["rule"] as String?;
        if (tag.isNullOrEmpty || rule.isNullOrEmpty) {
          Global.showTipsDialog(
            context: context,
            text: "请输入完整！",
          );
          return null;
        }
        var key = UniqueKey();
        return SettingCard(
          key: key,
          main: Text(
            "标签：$tag",
            maxLines: 1,
          ),
          sub: Text(
            "规则：$rule",
            maxLines: 1,
          ),
          value: data,
          borderRadius: const BorderRadius.all(
            Radius.circular(8.0),
          ),
          action: (data) {
            return IconButton(
              onPressed: () {
                remove(key);
              },
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            );
          },
        );
      },
      editDialogLayout: (onChange) {
        return RuleSettingAddDialog(
          labelText: "标签名",
          hintText: "请输入标签名",
          onChange: onChange,
        );
      },
      confirm: (res) async {
        var oldValue = jsonDecode(
          App.settings.tagRules,
        );
        var data = {
          "version": oldValue["version"] + 1,
          "data": res,
        };
        var json = jsonEncode(data);
        var opRecord = OperationRecord.fromSimple(
          Module.rules,
          OpMethod.update,
          jsonEncode({
            "rule": Rule.tag.name,
            "data": data,
          }),
        );
        await AppDb.inst.opRecordDao.removeRuleRecord(
          Rule.tag.name,
          App.userId,
        );
        await context.ref.notifier(settingProvider).setTagRules(json);

        AppDb.inst.opRecordDao.addAndNotify(opRecord);
      },
      title: "标签规则配置",
    );
  }
}
