import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart'
    as search_module;
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/widgets/clip_list_view.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SearchPage extends GetView<search_module.SearchController> {
  final appConfig = Get.find<ConfigService>();

  @override
  Widget build(BuildContext context) {
    controller.screenWidth = MediaQuery.of(context).size.width;
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: controller.showLeftBar ? 0 : null,
          automaticallyImplyLeading: !controller.showLeftBar,
          backgroundColor: controller.showLeftBar
              ? Colors.transparent
              : Theme.of(context).colorScheme.inversePrimary,
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.textController,
                  focusNode: controller.searchFocus,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                    ),
                    hintText: TranslationKey.search.tr,
                    border: controller.showLeftBar
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4), // 边框圆角
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 1.0,
                            ), // 边框样式
                          )
                        : InputBorder.none,
                    suffixIcon: InkWell(
                      onTap: () {
                        controller.refreshData();
                      },
                      splashColor: Colors.black12,
                      highlightColor: Colors.black12,
                      borderRadius: BorderRadius.circular(50),
                      child: Tooltip(
                        message: TranslationKey.search.tr,
                        child: const Icon(
                          Icons.search_rounded,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    controller.refreshData();
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, right: 5),
                child: IconButton(
                  onPressed: () async {
                    await controller.loadSearchCondition();
                    _showExtendSearchDialog();
                  },
                  tooltip: TranslationKey.moreFilter.tr,
                  icon: Icon(
                    controller.hasCondition
                        ? Icons.playlist_add_check_outlined
                        : Icons.menu_rounded,
                    color: controller.hasCondition ? Colors.blueAccent : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
          child: Column(
            children: [
              const SizedBox(
                height: 5,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var type in [
                      HistoryContentType.all,
                      HistoryContentType.text,
                      HistoryContentType.image,
                      HistoryContentType.file,
                      HistoryContentType.sms,
                    ])
                      Row(
                        children: [
                          RoundedChip(
                            selected: controller.searchType.label == type.label,
                            onPressed: () {
                              if (controller.searchType.label == type.label) {
                                return;
                              }
                              controller.loading.value = true;
                              controller.searchType = type;
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                controller.refreshData,
                              );
                            },
                            selectedColor: controller.searchType == type
                                ? Theme.of(context).chipTheme.selectedColor
                                : null,
                            label: Text(type.label),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Expanded(
                child: ConditionWidget(
                  condition: controller.loading.value,
                  visible: const Loading(),
                  invisible: ClipListView(
                    list: controller.list,
                    parentController: controller,
                    onRefreshData: controller.refreshData,
                    onUpdate: controller.sortList,
                    onRemove: (id) {
                      controller.list.removeWhere(
                        (element) => element.data.id == id,
                      );
                    },
                    onLoadMoreData: (minId) {
                      return controller.loadData(minId);
                    },
                    detailBorderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    imageMasonryGridViewLayout:
                        controller.searchType == HistoryContentType.image,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///加载扩展搜索底部弹窗
  void _showExtendSearchDialog() {
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: Get.context!,
      elevation: 100,
      builder: (context) {
        var start = controller.searchStartDate == ""
            ? TranslationKey.startDate.tr
            : controller.searchStartDate;
        var end = controller.searchEndDate == ""
            ? TranslationKey.endDate.tr
            : controller.searchEndDate;
        var now = DateTime.now();
        var nowDayStr = now.toString().substring(0, 10);
        var tags = Set<String>.from(controller.selectedTags);
        var devs = Set<String>.from(controller.selectedDevIds);
        bool searchOnlyNoSync = controller.searchOnlyNoSync;
        onDateRangeClick(state) async {
          //显示时间选择器
          var range = await showCalendarDatePicker2Dialog(
            context: context,
            config: CalendarDatePicker2WithActionButtonsConfig(
              calendarType: CalendarDatePicker2Type.range,
            ),
            dialogSize: const Size(325, 400),
            borderRadius: BorderRadius.circular(15),
          );
          if (range != null) {
            start = range[0]!.format("yyyy-MM-dd");
            end = range[1]!.format("yyyy-MM-dd");
          }
          state(() {});
        }

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Container(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  children: [
                    //筛选日期 label
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              TranslationKey.filterByDate.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                icon: Icon(
                                  searchOnlyNoSync
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank_sharp,
                                ),
                                label: Text(
                                  TranslationKey.onlyNotSync.tr,
                                ),
                                onPressed: () {
                                  setInnerState(() {
                                    searchOnlyNoSync = !searchOnlyNoSync;
                                  });
                                },
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              var hasCondition = false;
                              //判断是否加入了筛选条件
                              if (!start.contains(
                                    TranslationKey
                                        .searchPageMoreFilterByDateJudgeText.tr,
                                  ) ||
                                  !end.contains(
                                    TranslationKey
                                        .searchPageMoreFilterByDateJudgeText.tr,
                                  ) ||
                                  tags.isNotEmpty ||
                                  devs.isNotEmpty ||
                                  searchOnlyNoSync) {
                                hasCondition = true;
                              }
                              controller.searchStartDate = start.contains(
                                TranslationKey
                                    .searchPageMoreFilterByDateJudgeText.tr,
                              )
                                  ? ""
                                  : start;
                              controller.searchEndDate = end.contains(
                                TranslationKey
                                    .searchPageMoreFilterByDateJudgeText.tr,
                              )
                                  ? ""
                                  : end;
                              controller.selectedTags.clear();
                              controller.selectedTags.addAll(tags);
                              controller.selectedDevIds.clear();
                              controller.selectedDevIds.addAll(devs);
                              controller.searchOnlyNoSync = searchOnlyNoSync;
                              // controller.hasCondition = hasCondition;
                              controller.refreshData();
                            },
                            child: Text(TranslationKey.confirm.tr),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        RoundedChip(
                          onPressed: () => onDateRangeClick(setInnerState),
                          label: Text(
                            start,
                            style: TextStyle(
                              color: controller.searchStartDate == "" &&
                                      start == TranslationKey.startDate.tr
                                  ? Colors.blueGrey
                                  : null,
                            ),
                          ),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: Icon(
                            start != nowDayStr ||
                                    start == TranslationKey.startDate.tr
                                ? Icons.location_on
                                : Icons.close,
                            size: 17,
                            color: Colors.blue,
                          ),
                          deleteButtonTooltipMessage: start != nowDayStr ||
                                  start == TranslationKey.startDate.tr
                              ? TranslationKey.toToday.tr
                              : TranslationKey.clear.tr,
                          onDeleted: start != nowDayStr
                              ? () {
                                  start = DateTime.now()
                                      .toString()
                                      .substring(0, 10);
                                  setInnerState(() {});
                                }
                              : () {
                                  start = TranslationKey.startDate.tr;
                                  setInnerState(() {});
                                },
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 10, left: 10),
                          child: const Text("-"),
                        ),
                        RoundedChip(
                          onPressed: () => onDateRangeClick(setInnerState),
                          label: Text(
                            end,
                            style: TextStyle(
                              color: controller.searchEndDate == "" &&
                                      end == "结束日期"
                                  ? Colors.blueGrey
                                  : null,
                            ),
                          ),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: Icon(
                            end != nowDayStr || end == "结束日期"
                                ? Icons.location_on
                                : Icons.close,
                            size: 17,
                            color: Colors.blue,
                          ),
                          deleteButtonTooltipMessage:
                              end != nowDayStr || end == "结束日期"
                                  ? "定位到今天"
                                  : "清除",
                          onDeleted: end != nowDayStr || end == "结束日期"
                              ? () {
                                  end = DateTime.now()
                                      .toString()
                                      .substring(0, 10);
                                  setInnerState(() {});
                                }
                              : () {
                                  end = "结束日期";
                                  setInnerState(() {});
                                },
                        ),
                      ],
                    ),
                    //筛选设备
                    Row(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Text(
                            TranslationKey.filterByDevice.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        devs.isNotEmpty
                            ? SizedBox(
                                height: 25,
                                width: 25,
                                child: IconButton(
                                  padding: const EdgeInsets.all(2),
                                  tooltip: TranslationKey.clear.tr,
                                  iconSize: 13,
                                  color: Colors.blueGrey,
                                  onPressed: () {
                                    devs.clear();
                                    setInnerState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.cleaning_services_sharp,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Wrap(
                      direction: Axis.horizontal,
                      children: [
                        for (var dev in controller.allDevices)
                          Container(
                            margin: const EdgeInsets.only(right: 5, bottom: 5),
                            child: RoundedChip(
                              onPressed: () {
                                var guid = dev.guid;
                                if (devs.contains(guid)) {
                                  devs.remove(guid);
                                } else {
                                  devs.add(guid);
                                }
                                setInnerState(() {});
                              },
                              selected: devs.contains(dev.guid),
                              label: Text(dev.name),
                            ),
                          ),
                      ],
                    ),
                    //筛选标签
                    Row(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Text(
                            TranslationKey.filterByTag.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        tags.isNotEmpty
                            ? SizedBox(
                                height: 25,
                                width: 25,
                                child: IconButton(
                                  padding: const EdgeInsets.all(2),
                                  tooltip: TranslationKey.clear.tr,
                                  iconSize: 13,
                                  color: Colors.blueGrey,
                                  onPressed: () {
                                    tags.clear();
                                    setInnerState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.cleaning_services_sharp,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Wrap(
                      direction: Axis.horizontal,
                      children: [
                        for (var tag in controller.allTagNames)
                          Container(
                            margin: const EdgeInsets.only(right: 5, bottom: 5),
                            child: RoundedChip(
                              onPressed: () {
                                if (tags.contains(tag)) {
                                  tags.remove(tag);
                                } else {
                                  tags.add(tag);
                                }
                                setInnerState(() {});
                              },
                              selected: tags.contains(tag),
                              label: Text(tag),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
