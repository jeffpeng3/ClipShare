
import 'package:flutter/material.dart';

class TagEditPage extends StatefulWidget {
  const TagEditPage({super.key});

  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("标签配置..."),
      ),
    );
  }
}
