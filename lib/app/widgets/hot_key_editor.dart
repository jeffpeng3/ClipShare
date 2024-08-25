import 'package:clipshare/app/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotKeyEditor extends StatefulWidget {
  final String hotKey;
  final void Function(
    List<HotKeyModifier>,
    PhysicalKeyboardKey?,
    String keyLabel,
    String key,
  ) onDone;

  const HotKeyEditor({
    super.key,
    required this.hotKey,
    required this.onDone,
  });

  @override
  State<StatefulWidget> createState() {
    return _HotKeyEditorState();
  }

  static String toText(String hotKeys) {
    var [modifiers, key] = hotKeys.split(";");
    var res = modifiers.split(",").map((e) {
      var key = PhysicalKeyboardKey(e.toInt());
      return PhysicalKeyboardKeyExt.toModifyString(key.toModify);
    }).toList(growable: true);
    res.add(PhysicalKeyboardKey(key.toInt()).simpleLabel!);
    return res.join(" + ");
  }
}

class _HotKeyEditorState extends State<HotKeyEditor> {
  final _editor = TextEditingController();
  final _focusNode = FocusNode();
  var _outlined = false;
  PhysicalKeyboardKey? _key;
  final List<HotKeyModifier> _modifiers = [];
  List<HotKeyModifier> customOrder = [
    HotKeyModifier.control,
    HotKeyModifier.alt,
    HotKeyModifier.shift,
    HotKeyModifier.fn,
    HotKeyModifier.capsLock,
    HotKeyModifier.meta,
  ];
  var _keyCodes = "";

  @override
  void initState() {
    _editor.text = widget.hotKey;
    super.initState();
  }

  void updateText() {
    var descList = _modifiers
        .map((e) => PhysicalKeyboardKeyExt.toModifyString(e))
        .toList(growable: true);
    //将modifiers以逗号分隔，然后以分号结尾
    _keyCodes =
        "${_modifiers.map((e) => e.physicalKeys[0].usbHidUsage).toList().join(',')};";
    if (_key != null) {
      _keyCodes += _key!.usbHidUsage.toString();
      descList.add(_key!.simpleLabel!);
    }
    _editor.text = descList.join(" + ");
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        var isKeyUp = event is KeyUpEvent;
        var key = event.physicalKey;
        if (key.isModify) {
          //判断是否包含
          var isInclude = false;
          for (var saved in _modifiers) {
            if (saved.physicalKeys.contains(key)) {
              isInclude = true;
              break;
            }
          }
          if (isInclude && !isKeyUp && _modifiers.length != 1 && _key != null) {
            _modifiers.clear();
            _modifiers.add(key.toModify);
            _key = null;
          } else if (!isInclude) {
            _modifiers.add(key.toModify);
            _modifiers.sort((a, b) {
              var i = customOrder.indexOf(a);
              var j = customOrder.indexOf(b);
              return i.compareTo(j);
            });
          }
        } else {
          if (key.label != null) {
            _key = key;
          }
        }
        updateText();
      },
      child: TextField(
        readOnly: true,
        controller: _editor,
        style: _outlined ? null : const TextStyle(color: Colors.grey),
        decoration: InputDecoration(
          border: _outlined ? const OutlineInputBorder() : InputBorder.none,
          isDense: _outlined,
          focusedBorder: _outlined
              ? const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                )
              : null,
        ),
        onTap: () {
          setState(() {
            _outlined = true;
            _modifiers.clear();
            _key = null;
          });
        },
        onTapOutside: (event) {
          setState(() {
            _outlined = false;
            _focusNode.unfocus();
            widget.onDone.call(
              _modifiers,
              _key,
              _editor.text,
              _keyCodes,
            );
          });
        },
      ),
    );
  }
}
