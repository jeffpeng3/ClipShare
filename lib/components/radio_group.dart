import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

class RadioData<T> {
  final T value;
  final Widget label;

  const RadioData({required this.value, required this.label});
}

class RadioGroup<T> extends StatefulWidget {
  final List<RadioData<T>> data;
  final Axis direction;
  final T defaultValue;
  final void Function(T value) onSelected;
  final bool Function(T value) selected;

  const RadioGroup({
    super.key,
    required this.data,
    this.direction = Axis.vertical,
    required this.defaultValue,
    required this.onSelected,
    required this.selected,
  });

  @override
  State<StatefulWidget> createState() {
    return _RadioGroupState<T>();
  }
}

class _RadioGroupState<T> extends State<RadioGroup> {
  late T groupValue;

  @override
  Widget build(BuildContext context) {
    groupValue = widget.defaultValue;
    List<RadioListTile<T>> widgets = List.generate(
      widget.data.length,
      (index) {
        var v = widget.data[index].value;
        return RadioListTile<T>(
          value: v,
          groupValue: groupValue,
          selected: widget.selected.call(v),
          title: widget.data[index].label,
          onChanged: (T? value) {
            groupValue = v;
            setState(() {});
            widget.onSelected(value!);
          },
        );
      },
    );
    return widget.direction == Axis.horizontal
        ? IntrinsicWidth(
            child: Row(children: widgets),
          )
        : IntrinsicHeight(
            child: Column(children: widgets),
          );
  }
}
