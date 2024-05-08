import 'package:clipshare/util/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthPasswordInput extends StatefulWidget {
  final bool Function(String first, String? second) onFinished;
  final void Function()? onError;
  final bool Function(String input) onOk;
  final String tipText;
  final String againText;
  final String errorText;
  final bool again;

  const AuthPasswordInput({
    super.key,
    required this.onFinished,
    this.tipText = "输入密码",
    this.againText = "再次输入",
    this.errorText = "输入错误，请重新输入",
    this.again = false,
    this.onError,
    required this.onOk,
  });

  @override
  State<StatefulWidget> createState() {
    return _AuthPasswordInputState();
  }
}

class _AuthPasswordInputState extends State<AuthPasswordInput> {
  static const _maxLen = 4;
  var _first = "";
  String _second = "";
  var _secondInput = false;
  var _error = false;

  String get _currentInput => _secondInput && widget.again ? _second : _first;

  String get _currentShowText =>
      _secondInput ? widget.againText : widget.tipText;

  void _setCurrentInput(String input) {
    if (_secondInput && widget.again) {
      _second = input;
    } else {
      _first = input;
    }
  }

  void _onNumberInput(int i) {
    HapticFeedback.mediumImpact();
    if (_currentInput.length >= _maxLen) {
      return;
    }
    _setCurrentInput("$_currentInput$i");
    if (_currentInput.length == _maxLen) {
      //不需要重复输入或是第二次输入完成
      if (!widget.again || (widget.again && _secondInput)) {
        _error = !widget.onFinished.call(_first, _secondInput ? _second : null);
        if (_error) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _setCurrentInput("");
            if (widget.again) {
              //如果是重复输入模式，清除第一次输入
              _secondInput = false;
              _setCurrentInput("");
            }
            setState(() {});
            //连续振动
            for (var i = 0; i < 4; i++) {
              HapticFeedback.mediumImpact();
            }
            widget.onError?.call();
          });
        } else {
          if (widget.onOk.call(_currentInput)) {
            Navigator.pop(context);
          }
        }
      } else {
        //需要重复输入且第一次输入完成
        _secondInput = true;
      }
    } else {
      _error = false;
    }
    setState(() {});
  }

  void _onNumberDelete() {
    HapticFeedback.mediumImpact();
    if (_currentInput.isEmpty) return;
    _setCurrentInput(_currentInput.substring(0, _currentInput.length - 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Image.asset(
              Constants.logoPngPath,
              width: 150,
              fit: BoxFit.fitWidth,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  _error ? widget.errorText : _currentShowText,
                  style: TextStyle(
                    fontSize: 18,
                    color: _error ? Colors.red : Colors.blue,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < 4; i++)
                        AnimatedContainer(
                          width: 15.0,
                          height: 15.0,
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: _currentInput.length > i
                                ? Colors.blue
                                : Colors.transparent,
                            border: Border.all(
                              color: Colors.blue,
                              width: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 1; i <= 3; i++)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            for (var j = 1; j <= 3; j++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 25),
                                child: Ink(
                                  decoration: const BoxDecoration(
                                    //颜色放外面的Ink，否则水波纹被遮挡
                                    color: Color(0Xfff2f2f2),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(50),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(50),
                                    ),
                                    child: AnimatedContainer(
                                      width: 100,
                                      height: 100,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Center(
                                        child: Text(
                                          "${(i - 1) * 3 + j}",
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: () =>
                                        _onNumberInput((i - 1) * 3 + j),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 25),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 25),
                            child: Ink(
                              decoration: const BoxDecoration(
                                //颜色放外面的Ink，否则水波纹被遮挡
                                color: Color(0Xfff2f2f2),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(50),
                                ),
                                child: AnimatedContainer(
                                  width: 100,
                                  height: 100,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Center(
                                    child: Text(
                                      "0",
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () => _onNumberInput(0),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 25),
                            child: Ink(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50),
                                ),
                              ),
                              child: InkWell(
                                splashColor: Colors.orange.withOpacity(0.1),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(50),
                                ),
                                onTap: _onNumberDelete,
                                child: AnimatedContainer(
                                  width: 100,
                                  height: 100,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Center(
                                    child: Icon(
                                      Icons.backspace_outlined,
                                      color: Colors.orange,
                                      size: 45,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
