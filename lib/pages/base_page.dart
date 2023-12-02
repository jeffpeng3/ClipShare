import 'package:clipshare/pages/devices_page.dart';
import 'package:clipshare/pages/history_page.dart';
import 'package:clipshare/pages/profile_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  List<Widget> pages = const [HistoryPage(), DevicesPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => {_index = i, setState(() {})},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_rounded),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
