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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SmsRuleSettingPage extends StatelessWidget {
  SmsRuleSettingPage({super.key});

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  @override
  Widget build(BuildContext context) {
    return RuleSettingPage(
      title: "短信规则配置",
      initData: Rule.fromJson(
        (jsonDecode(
          appConfig.smsRules,
        )["data"] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
      ),
      onAdd: (data) {
        var name = data.name;
        var rule = data.rule;
        if (name.isNullOrEmpty || rule.isNullOrEmpty) {
          Global.showTipsDialog(
            context: context,
            text: "请输入完整！",
          );
          return false;
        }
        return true;
      },
      editDialogLayout: (initData, onChange) {
        return RuleSettingAddDialog(
          labelText: "规则名",
          hintText: "请输入规则名",
          onChange: onChange,
          initData: initData,
        );
      },
      confirm: (res) async {
        var oldValue = jsonDecode(
          appConfig.smsRules,
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
            "rule": RuleType.sms.name,
            "data": data,
          }),
        );
        await dbService.opRecordDao.removeRuleRecord(
          RuleType.sms.name,
          appConfig.userId,
        );
        await appConfig.setSmsRules(json);

        dbService.opRecordDao.addAndNotify(opRecord);
      },
      action: (i, rule, remove) {
        return IconButton(
          onPressed: () {
            remove(i, rule);
          },
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
        );
      },
    );
  }
}
