import 'package:flutter/foundation.dart';

import '../core/app_version.dart';
import '../models/app_update.dart';
import 'storage_service.dart';
import 'update_source.dart';

/// Проверка обновлений (гибридная схема).
///
/// Как это работает:
///  1) при запуске (через 3 с) и далее раз в N часов читаем version.json;
///  2) если версия на сервере новее — баннер «Доступна обновление»
///     появляется на ВСЕХ экранах (UpdateBanner в HomeShell);
///  3) нет сети / файл не размещён — приложение молча работает дальше;
///  4) «Симулировать обновление» в Профиле — мгновенный баннер для теста.
class UpdateService extends ChangeNotifier {
  UpdateService(this._storage);

  final StorageService _storage;

  AppUpdateInfo? available;
  String? lastError;
  bool checking = false;
  DateTime? _lastCheck;
  DateTime? _lastTry;

  /// Демо-переключатель: показывает баннер без сервера.
  bool simulateUpdate = false;

  /// Пользовательский URL проверки (меняется в Профиле, хранится локально).
  String customUrl = '';

  static const String _kSimulate = 'update_simulate';
  static const String _kCustomUrl = 'update_custom_url';
  static const String _kLastCheck = 'update_last_check_ms';

  void load() {
    simulateUpdate = _storage.getBool(_kSimulate);
    customUrl = _storage.getString(_kCustomUrl);
    final int ms = _storage.getInt(_kLastCheck);
    if (ms > 0) {
      _lastCheck = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (simulateUpdate) {
      available = _simulatedInfo();
    }
  }

  AppUpdateInfo _simulatedInfo() => AppUpdateInfo(
        latestVersion: _nextVersion(kAppVersion),
        notes: 'Демо-обновление: ровно так баннер увидят все пользователи '
            'после публикации нового version.json на хостинге.',
        forceUpdate: false,
        androidUrl: 'https://play.google.com/store/apps/details?id=REPLACE_ME',
        iosUrl: 'https://apps.apple.com/app/REPLACE_ME',
      );

  static String _nextVersion(String current) {
    final List<String> parts = current.split('.');
    final int minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${parts[0]}.${minor + 1}.0';
  }

  Uri get checkUri => Uri.parse(
        customUrl.trim().isNotEmpty ? customUrl.trim() : kDefaultUpdateUrl,
      );

  bool get _isTimeToCheck {
    if (_lastCheck == null) return true;
    return DateTime.now().difference(_lastCheck!) >=
        const Duration(hours: kUpdateCheckIntervalHours);
  }

  /// Защита от частых повторов при ошибках (не чаще раза в 30 секунд).
  bool get _isCooldownPassed {
    if (_lastTry == null) return true;
    return DateTime.now().difference(_lastTry!) > const Duration(seconds: 30);
  }

  Future<void> check({bool manual = false}) async {
    if (checking) return;
    if (!manual && !_isCooldownPassed) return;

    if (simulateUpdate) {
      available = _simulatedInfo();
      notifyListeners();
      return;
    }

    if (!manual && !_isTimeToCheck) return;

    checking = true;
    lastError = null;
    _lastTry = DateTime.now();
    notifyListeners();

    try {
      final AppUpdateInfo? info =
          await JsonHttpUpdateSource(checkUri).fetchLatest();
      _lastCheck = DateTime.now();
      _storage.setInt(_kLastCheck, _lastCheck!.millisecondsSinceEpoch);
      if (info != null && info.isNewerThan(kAppVersion)) {
        available = info;
      } else {
        available = null;
      }
    } catch (e) {
      // Нет сети или файл ещё не размещён — для локальной разработки это норма.
      lastError = 'Не удалось проверить обновления: ${e.toString()}';
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  void setSimulate(bool value) {
    simulateUpdate = value;
    _storage.setBool(_kSimulate, value);
    available = value ? _simulatedInfo() : null;
    notifyListeners();
  }

  void setCustomUrl(String url) {
    customUrl = url;
    _storage.setString(_kCustomUrl, url);
    notifyListeners();
  }

  void clearAvailable() {
    available = null;
    notifyListeners();
  }
}
