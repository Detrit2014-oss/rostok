import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'pet_service.dart';
import 'screen_time_service.dart';
import 'storage_service.dart';

enum FocusPhase { idle, running }

/// Сессия цифрового детокса, привязанная к ЭКРАННОМУ ВРЕМЕНИ телефона.
///
/// Засчитывается только время, когда пользователя НЕ БЫЛО в приложении:
///  • Android (с разрешением «Доступ к использованию», docs/SCREEN_TIME.md)
///    — минус всё время, когда экран был включён: растут ровно минуты
///    с погашенным экраном, даже если пользователь читал чужие приложения.
///  • iOS/Web — всё время вне приложения (точных данных о других
///    приложениях система не отдаёт).
///
/// Пока приложение открыто, счёт стоит на паузе — вы же смотрите в экран.
/// Сессия переживает перезапуск приложения: все счётчики хранятся локально.
///
/// Машина времени ×60 (тестовый режим) считает ВСЁ время подряд —
/// так удобно проверять рост питомца в Chrome без ожидания.
class FocusSessionService extends ChangeNotifier with WidgetsBindingObserver {
  FocusSessionService(this._pet, this._storage);

  final PetService _pet;
  final StorageService _storage;

  FocusPhase phase = FocusPhase.idle;
  DateTime? _startedAt;

  /// Уже засчитанные миллисекунды (экран погашен / приложение в фоне).
  int _countedMs = 0;

  /// Когда приложение ушло в фон (мс epoch). null — приложение на экране.
  int? _awaySinceMs;

  /// Прозрачность учёта: сколько за сессию экран горел в фоне (мс).
  /// Это время в рост НЕ засчитывается.
  int sessionScreenOnMs = 0;

  /// Поддержка точного учёта экранного времени (Android UsageStats).
  ScreenTimeSupport screenTimeSupport = ScreenTimeSupport.unavailable;

  /// Тестовый режим: 1 секунда = 1 минута, считается всё время.
  bool timeMachine = false;

  /// Итог последней завершённой сессии (в минутах).
  int? lastSessionMinutes;

  Timer? _ticker;

  static const String _kStartedAt = 'session_started_at';
  static const String _kCounted = 'session_counted_ms';
  static const String _kAwaySince = 'session_away_since_ms';
  static const String _kTimeMachine = 'settings_time_machine';

  bool get isRunning => phase == FocusPhase.running;

  /// Прямо сейчас питомец растёт? (приложение в фоне, время капает)
  bool get countingNow => isRunning && !timeMachine && _awaySinceMs != null;

  /// Засчитанное время с начала сессии.
  Duration get elapsed {
    if (!isRunning || _startedAt == null) return Duration.zero;
    if (timeMachine) {
      final Duration real = DateTime.now().difference(_startedAt!);
      return Duration(seconds: real.inSeconds * 60);
    }
    final int pending = _awaySinceMs == null
        ? 0
        : math.max(0, DateTime.now().millisecondsSinceEpoch - _awaySinceMs!);
    return Duration(milliseconds: _countedMs + pending);
  }

  int get elapsedMinutes => elapsed.inMinutes;

  void load() {
    timeMachine = _storage.getBool(_kTimeMachine);
    final int startedMs = _storage.getInt(_kStartedAt);
    _countedMs = _storage.getInt(_kCounted);
    final int away = _storage.getInt(_kAwaySince);
    if (startedMs > 0) {
      // Приложение перезапустили во время сессии — продолжаем её.
      _startedAt = DateTime.fromMillisecondsSinceEpoch(startedMs);
      phase = FocusPhase.running;
      if (away > 0) {
        // Фон накопился, пока приложение было закрыто: досчитываем.
        _awaySinceMs = away;
        _reconcileOnReturn();
      }
      _startTicker();
    }
    _probeSupport();
  }

  Future<void> _probeSupport() async {
    final ScreenTimeSupport s = await ScreenTimeService.checkSupport();
    screenTimeSupport = s;
    notifyListeners();
  }

  /// Перечитать статус разрешения (после возврата из настроек).
  Future<void> refreshSupport() => _probeSupport();

  /// Запустить сессию: «Отложить телефон».
  void start() {
    if (isRunning) return;
    _startedAt = DateTime.now();
    phase = FocusPhase.running;
    _countedMs = 0;
    _awaySinceMs = null;
    sessionScreenOnMs = 0;
    lastSessionMinutes = null;
    _persist();
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
    _countedMs = 0;
    _awaySinceMs = null;
    _storage.setInt(_kStartedAt, 0);
    _storage.setInt(_kCounted, 0);
    _storage.setInt(_kAwaySince, 0);
    _stopTicker();
    notifyListeners();
    return minutes;
  }

  void setTimeMachine(bool value) {
    timeMachine = value;
    _storage.setBool(_kTimeMachine, value);
    if (timeMachine) {
      // Тестовый режим считает всё время — период фона больше не нужен.
      _awaySinceMs = null;
      _storage.setInt(_kAwaySince, 0);
    }
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

  /// Приложение ушло с экрана: начинаем копить «фон».
  void _markAway() {
    if (!isRunning || timeMachine) return;
    _awaySinceMs ??= DateTime.now().millisecondsSinceEpoch;
    _persist();
  }

  /// Приложение вернулось: переводим накопленный фон в засчитанные минуты.
  ///
  /// На Android с разрешением вычитаем время, когда экран был включён
  /// (пользователь пользовался телефоном — это не отдых).
  Future<void> _reconcileOnReturn() async {
    final int? away = _awaySinceMs;
    if (away == null) return;
    _awaySinceMs = null;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int awayMs = math.max(0, nowMs - away);
    final int screenOn = await ScreenTimeService.screenOnMillis(away, nowMs);

    if (phase != FocusPhase.running) {
      // Сессию уже завершили — счётчики очищены, просто сохраняемся.
      _persist();
      return;
    }
    if (screenOn < 0) {
      // Нет точных данных (iOS/Web/нет разрешения): считаем весь фон.
      _countedMs += awayMs;
    } else {
      final int used = math.min(screenOn, awayMs);
      _countedMs += awayMs - used;
      sessionScreenOnMs += used;
    }
    _persist();
    notifyListeners();
  }

  void _persist() {
    _storage.setInt(_kStartedAt, _startedAt?.millisecondsSinceEpoch ?? 0);
    _storage.setInt(_kCounted, _countedMs);
    _storage.setInt(_kAwaySince, _awaySinceMs ?? 0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconcileOnReturn();
      notifyListeners(); // мгновенно обновить таймер после возврата
      return;
    }
    // inactive/hidden/paused/detached — приложение перестало быть на экране.
    // (перечисление без switch: новые состояния Flutter не сломают сборку)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _markAway();
    }
  }

  void reset() {
    phase = FocusPhase.idle;
    _startedAt = null;
    _countedMs = 0;
    _awaySinceMs = null;
    lastSessionMinutes = null;
    sessionScreenOnMs = 0;
    _stopTicker();
    _storage.setInt(_kStartedAt, 0);
    _storage.setInt(_kCounted, 0);
    _storage.setInt(_kAwaySince, 0);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
