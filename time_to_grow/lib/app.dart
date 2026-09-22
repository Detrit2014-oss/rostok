import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/home_shell.dart';

class TimeToGrowApp extends StatelessWidget {
  const TimeToGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Время Расти',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}
