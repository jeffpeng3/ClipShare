import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/data_clean_module/clean_data_controller.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class CleanDataPage extends GetView<CleanDataController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TranslationKey.cleanData.tr)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  color: Colors.blueGrey,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  "过滤器",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.tag,
                  color: Colors.blueGrey,
                  size: 16,
                ),
                SizedBox(
                  width: 2,
                ),
                Text(
                  TranslationKey.filterByTag.tr,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.devices_outlined,
                  color: Colors.blueGrey,
                  size: 16,
                ),
                SizedBox(
                  width: 2,
                ),
                Text(
                  TranslationKey.filterByDevice.tr,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: Colors.blueGrey,
                  size: 16,
                ),
                SizedBox(
                  width: 2,
                ),
                Text(
                  TranslationKey.filterByDate.tr,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: Colors.blueGrey,
                  size: 16,
                ),
                SizedBox(
                  width: 2,
                ),
                Text(
                  "内容类型",
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
            CheckboxListTile(
              value: true,
              onChanged: (v) {},
              title: Text("保留置顶数据"),
            ),
            CheckboxListTile(
              value: false,
              onChanged: (v) {},
              title: Text("同时移除本地文件"),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Global.showTipsDialog(context: context, text: "暂未实现");
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save),
                        const SizedBox(
                          width: 5,
                        ),
                        Text("保存过滤器配置"),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Global.showTipsDialog(context: context, text: "暂未实现");
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.clear_all_outlined),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(TranslationKey.cleanData.tr),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: Colors.blueGrey,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  "定时清理",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Global.showTipsDialog(context: context, text: "暂未实现");
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save),
                  const SizedBox(
                    width: 5,
                  ),
                  Text("保存定时器配置"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
