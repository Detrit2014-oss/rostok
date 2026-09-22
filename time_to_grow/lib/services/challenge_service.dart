import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/challenge.dart';
import 'challenge_backend.dart';
import 'pet_service.dart';

/// Недельный челлендж «Детокс-неделя»: соревнование по минутам,
/// проведённым вне телефона. Минуты пользователя — реальные (из сессий),
/// соперники в v1.0.0 — дружелюбные боты (демо-режим, помечен в UI).
///
/// Для реальных друзей: реализуйте ChallengeBackend на Firestore —
/// полный код и инструкция в docs/FIREBASE.md.
class ChallengeService extends ChangeNotifier {
  ChallengeService(this._pet, this._backend);

  final PetService _pet;
  final ChallengeBackend _backend;
  final Random _random = Random();

  Challenge? weekly;

  static const List<String> _botNames = <String>[
    'Аня', 'Марк', 'Лена', 'Дима', 'Соня', 'Кирилл',
  ];
  static const List<String> _botEmojis = <String>[
    '🌻', '🌷', '🌿', '🌲', '🍀', '🐝',
  ];

  Future<void> load() async {
    try {
      weekly = await _backend.load();
    } catch (_) {
      weekly = null;
    }
    _ensureWeekly();
    _syncUserMinutes();
  }

  void _ensureWeekly() {
    final int monday = _mondayMs(DateTime.now());
    if (weekly == null || weekly!.weekStartMs != monday) {
      weekly = Challenge(
        id: 'w$monday',
        title: 'Детокс-неделя',
        goalHours: 10,
        weekStartMs: monday,
        participants: <ChallengeParticipant>[
          ChallengeParticipant(name: 'Вы', emoji: '🐾', isUser: true),
          for (int i = 0; i < 4; i++)
            ChallengeParticipant(
                name: _botNames[i], emoji: _botEmojis[i]),
        ],
      );
      unawaited(_backend.save(weekly!));
    }
  }

  /// Боты живут своей жизнью: прогресс стабильный внутри дня
  /// (детерминированный сид) и растёт с каждым днём недели.
  void _updateBots() {
    final Challenge? c = weekly;
    if (c == null) return;
    final int dayIndex = DateTime.now().weekday; // 1..7
    final Random seeded = Random(c.id.hashCode);
    for (final ChallengeParticipant p in c.participants) {
      if (p.isUser) continue;
      final int pacePerDay = 40 + seeded.nextInt(60); // 40–99 мин/день
      p.minutes = pacePerDay * dayIndex + seeded.nextInt(30);
    }
  }

  void _syncUserMinutes() {
    if (weekly == null) return;
    _updateBots();
    bool changed = false;
    for (final ChallengeParticipant p in weekly!.participants) {
      if (p.isUser && p.minutes != _pet.weekMinutes) {
        p.minutes = _pet.weekMinutes;
        changed = true;
      }
    }
    if (changed) {
      unawaited(_backend.save(weekly!));
    }
    notifyListeners();
  }

  /// Вызывается при входе на вкладку «Челлендж» и после сессий.
  void refresh() => _syncUserMinutes();

  void resetLocally() {
    weekly = null;
    _ensureWeekly();
    _syncUserMinutes();
  }

  List<ChallengeParticipant> get leaderboard {
    final List<ChallengeParticipant> list =
        List<ChallengeParticipant>.from(
            weekly?.participants ?? <ChallengeParticipant>[]);
    list.sort((ChallengeParticipant a, ChallengeParticipant b) =>
        b.minutes.compareTo(a.minutes));
    return list;
  }

  void createChallenge(String title, int goalHours) {
    final int monday = _mondayMs(DateTime.now());
    weekly = Challenge(
      id: 'w$monday-${DateTime.now().millisecondsSinceEpoch % 100000}',
      title: title.trim().isEmpty ? 'Мой челлендж' : title.trim(),
      goalHours: goalHours.clamp(1, 60).toInt(),
      weekStartMs: monday,
      participants: <ChallengeParticipant>[
        ChallengeParticipant(name: 'Вы', emoji: '🐾', isUser: true),
        for (int i = 0; i < 4; i++)
          ChallengeParticipant(
            name: _botNames[_random.nextInt(_botNames.length)],
            emoji: _botEmojis[_random.nextInt(_botEmojis.length)],
          ),
      ],
    );
    _syncUserMinutes();
    unawaited(_backend.save(weekly!));
  }

  int get daysLeft {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime monday = today.subtract(Duration(days: now.weekday - 1));
    final DateTime nextMonday = monday.add(const Duration(days: 7));
    return nextMonday.difference(today).inDays;
  }

  static int _mondayMs(DateTime d) {
    final DateTime day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: d.weekday - 1)).millisecondsSinceEpoch;
  }
}
