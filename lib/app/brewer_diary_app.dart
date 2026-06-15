import 'package:flutter/material.dart';

import '../controllers/batch_controller.dart';
import '../screens/main_shell.dart';

/// Root widget that wires app theme and the shared controller together.
class BrewerDiaryApp extends StatefulWidget {
  const BrewerDiaryApp({super.key});

  @override
  State<BrewerDiaryApp> createState() => _BrewerDiaryAppState();
}

class _BrewerDiaryAppState extends State<BrewerDiaryApp> {
  late final BatchController controller;

  @override
  void initState() {
    super.initState();
    controller = BatchController()..load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brewer Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B1E4D)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B1E4D),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MainShell(controller: controller),
    );
  }
}
