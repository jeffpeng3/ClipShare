import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

// final ThemeData appThemeData = ThemeData(
//   primarySwatch: Colors.blue,
//   visualDensity: VisualDensity.adaptivePlatformDensity,
// );

final themeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
  fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
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
