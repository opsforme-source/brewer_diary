import 'package:flutter/material.dart';

import 'app/brewer_diary_app.dart';

/// Brewer Diary entrypoint.
///
/// The actual app wiring lives in `app/brewer_diary_app.dart`; keeping this
/// file tiny makes it obvious where execution starts.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrewerDiaryApp());
}
