import 'package:clipshare/listener/ClipListener.dart';
import 'package:clipshare/pages/base_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  //定义channel
  static const channel = MethodChannel('clip');

  const MyApp({super.key});

  void initClipHandler(BuildContext context) {
    MyApp.channel.setMethodCallHandler((call) {
      switch (call.method) {
        case "setClipText":
          {
            String text = call.arguments['text'];
            ClipListener.instance().setClip(text);
            print("clipboard changed: " + text);
            break;
          }
      }
      return Future(() => "接受成功");
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    initClipHandler(context);
    print("main created");
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Flutter Demo'),
    );
  }
}
