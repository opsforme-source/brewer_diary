import 'package:flutter/material.dart';

import '../controllers/batch_controller.dart';
import 'batch_list_screen.dart';
import 'ideas_screen.dart';
import 'rating_screen.dart';
import 'settings_screen.dart';

/// Bottom-tab navigation for the app's main sections.
class MainShell extends StatefulWidget {
  final BatchController controller;
  const MainShell({super.key, required this.controller});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      IdeasScreen(controller: widget.controller),
      BatchListScreen(controller: widget.controller),
      RatingScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Ötletek',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_bar_outlined),
            selectedIcon: Icon(Icons.local_bar),
            label: 'Elkészült',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Pontozás',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Beállítások',
          ),
        ],
      ),
    );
  }
}
