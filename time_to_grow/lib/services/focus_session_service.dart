import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'pet_service.dart';
import 'storage_service.dart';

enum FocusPhase { idle, running }

/// Сессия цифрового детокса.
///
/// Ядро механики: таймер считается по РЕАЛЬНОМУ времени и не останавливается,
/// когда приложение свёрнуто. Отложили телефон — питомец растёт. Вернулись —
/// нажали «Я вернулся» и получили минуты. Если приложение закрыли во время
/// сессии, при следующем запуске она продолжится (timestamp хранится локально).
class FocusSessionService extends ChangeNotifier with WidgetsBindingObserver {
  FocusSessionService(this._pet, this._storage);

  final PetService _pet;
  final StorageService _storage;

  FocusPhase phase = FocusPhase.idle;
  DateTime? _startedAt;
  Timer? _ticker;

  /// Тестовый режим (машина времени): 1 секунда = 1 минута сада.
  /// Удобно для проверки роста в Chrome без ожидания.
  bool timeMachine = false;

  /// Итог последней завершённой сессии (в минутах).
  int? lastSessionMinutes;

  static const String _kStartedAt = 'session_started_at';
  static const String _kTimeMachine = 'settings_time_machine';

  void load() {
    timeMachine = _storage.getBool(_kTimeMachine);
    final int startedMs = _storage.getInt(_kStartedAt);
    if (startedMs > 0) {
      // Приложение перезапустили во время сессии — продолжаем её.
      _startedAt = DateTime.fromMillisecondsSinceEpoch(startedMs);
      phase = FocusPhase.running;
      _startTicker();
    }
  }

  bool get isRunning => phase == FocusPhase.running;

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    final Duration real = DateTime.now().difference(_startedAt!);
    if (timeMachine) {
      return Duration(seconds: real.inSeconds * 60);
    }
    return real;
  }

  int get elapsedMinutes => elapsed.inMinutes;

  /// Запустить сессию: «Отложить телефон».
  void start() {
    if (isRunning) return;
    _startedAt = DateTime.now();
    phase = FocusPhase.running;
    _storage.setInt(_kStartedAt, _startedAt!.millisecondsSinceEpoch);
    _startTicker();
    notifyListeners();
  }

  /// Завершить сессию: «Я вернулся». Возвращает начисленные минуты.
  int stop() {
    if (!isRunning) return 0;
    final int minutes = elapsedMinutes;
    _pet.addDetoxMinutes(minutes);
    lastSessionMinutes = minutes;

    phase = FocusPhase.idle;
    _startedAt = null;
    _storage.setInt(_kStartedAt, 0);
    _stopTicker();
    notifyListeners();
    return minutes;
  }

  void setTimeMachine(bool value) {
    timeMachine = value;
    _storage.setBool(_kTimeMachine, value);
    notifyListeners();
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      // Обновляем экран таймера раз в секунду.
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Специально ничего не прерываем: сессия живёт по настенным часам,
    // поэтому в свёрнутом состоянии минуты продолжают накапливаться.
    if (state == AppLifecycleState.resumed) {
      notifyListeners(); // мгновенно обновить таймер после возврата
    }
  }

  void reset() {
    phase = FocusPhase.idle;
    _startedAt = null;
    lastSessionMinutes = null;
    _stopTicker();
    _storage.setInt(_kStartedAt, 0);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
