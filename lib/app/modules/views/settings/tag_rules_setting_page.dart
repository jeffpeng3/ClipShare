import 'dart:convert';

import 'package:clipshare/app/data/models/rule.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/views/settings/rules_setting_page.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/rule_setting_add_dialog.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagRuleSettingPage extends StatelessWidget {
  TagRuleSettingPage({super.key});

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  @override
  Widget build(BuildContext context) {
    return RuleSettingPage(
      initData: Rule.fromJson(
        (jsonDecode(
          appConfig.tagRules,
        )["data"] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
      ),
      onAdd: (data, remove) {
        var tag = data.name;
        var rule = data.rule;
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
          name: Text(
            "标签：$tag",
            maxLines: 1,
          ),
          description: Text(
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
      editDialogLayout: (initData, onChange) {
        return RuleSettingAddDialog(
          labelText: "标签名",
          hintText: "请输入标签名",
          onChange: onChange,
          initData: initData,
        );
      },
      confirm: (res) async {
        var oldValue = jsonDecode(
          appConfig.tagRules,
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
            "rule": RuleType.tag.name,
            "data": data,
          }),
        );
        await dbService.opRecordDao.removeRuleRecord(
          RuleType.tag.name,
          appConfig.userId,
        );
        await appConfig.setTagRules(json);

        dbService.opRecordDao.addAndNotify(opRecord);
      },
      title: "标签规则配置",
    );
  }
}
