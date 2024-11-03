import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/**
 * GetX Template Generator - fb.com/htngu.99
 * */
const lightBackgroundColor = Color.fromARGB(255, 238, 238, 238);
const darkBackgroundColor = Colors.black;
final lightThemeData = ThemeData.light().copyWith(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
  cardTheme: const CardTheme(color: Colors.white),
  scaffoldBackgroundColor: lightBackgroundColor,
  textTheme: Platform.isWindows
      ? ThemeData.light().textTheme.apply(fontFamily: 'Microsoft YaHei')
      : null,
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xffdde1e3),
    selectedColor: Colors.blue[100],
  ),
  dialogBackgroundColor: const Color(0xffdde1e3),
);
final darkThemeData = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.lightBlueAccent,
    brightness: Brightness.dark,
  ),
  // cardTheme: const CardTheme(color: Colors.blueGrey),
  scaffoldBackgroundColor: darkBackgroundColor,
  textTheme: Platform.isWindows
      ? ThemeData.dark().textTheme.apply(fontFamily: 'Microsoft YaHei')
      : null,
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xff2e3b42),
    selectedColor: Colors.blue[800],
  ),
  dialogBackgroundColor: const Color(0xff2e3b42),
);
const locale = Locale("zh", "CH");
const supportedLocales = [
  Locale("zh", "CH"),
  Locale('en', 'US'),
];
const localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

//解决 Windows 端 SingleChildScrollView 无法水平滚动的问题
//https://stackoverflow.com/questions/72528980/horizontal-singlechildscrollview-not-working-inside-a-column-on-windows
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods like buildOverscrollIndicator and buildScrollbar
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
