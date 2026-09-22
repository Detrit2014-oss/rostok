import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/pet_selection_screen.dart';
import 'services/pet_service.dart';

class TimeToGrowApp extends StatelessWidget {
  const TimeToGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Время Расти',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _PetGate(),
    );
  }
}

/// Ворота главного экрана: пока питомец не выбран, показываем большой
/// экран выбора. Выбрали — живём в обычной оболочке с 4 вкладками.
/// После сброса прогресса (Профиль → «Сбросить») выбор возвращается.
class _PetGate extends StatelessWidget {
  const _PetGate();

  @override
  Widget build(BuildContext context) {
    final bool hasPets = context.watch<PetService>().pets.isNotEmpty;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: hasPets
          ? const HomeShell(key: ValueKey<bool>(true))
          : const PetSelectionScreen(key: ValueKey<bool>(false)),
    );
  }
}
