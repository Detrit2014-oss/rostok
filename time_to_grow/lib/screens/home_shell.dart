import 'package:flutter/material.dart';

import '../widgets/update_banner.dart';
import 'challenge_screen.dart';
import 'diary_screen.dart';
import 'pet_screen.dart';
import 'profile_screen.dart';

/// Оболочка приложения: глобальный баннер обновлений поверх
/// содержимого + нижняя навигация из 4 вкладок.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _screens = <Widget>[
    PetScreen(),
    DiaryScreen(),
    ChallengeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const UpdateBanner(),
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (int i) => setState(() => _index = i),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.pets_rounded), label: 'Питомец'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_rounded), label: 'Дневник'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Челлендж'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
    );
  }
}
