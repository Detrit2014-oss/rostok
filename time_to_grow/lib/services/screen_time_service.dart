import 'package:flutter/services.dart';

/// Насколько точно платформа умеет отдавать экранное время.
enum ScreenTimeSupport {
  /// Канал недоступен (Web, iOS, десктоп или нативный код не подключён).
  unavailable,

  /// Android-канал есть, но пользователь не выдал «Доступ к использованию».
  denied,

  /// Android-канал есть и разрешение выдано — точный учёт по экрану.
  granted,
}

/// Мост к нативному экранному времени телефона (Android UsageStatsManager).
///
/// Нативная часть подключается по желанию — готовый MainActivity.kt
/// и пошаговая инструкция: docs/SCREEN_TIME.md.
///
/// Без нативного кода (или на iOS/Web) канал недоступен — сервис мягко
/// деградирует: сессия считает всё время вне приложения, приложение
/// продолжает работать как в v1.0.0.
class ScreenTimeService {
  static const MethodChannel _channel = MethodChannel(
    'time_to_grow/screen_time',
  );

  /// Проверить поддержку и статус разрешения.
  static Future<ScreenTimeSupport> checkSupport() async {
    try {
      final String? status = await _channel.invokeMethod<String>(
        'checkSupport',
      );
      switch (status) {
        case 'granted':
          return ScreenTimeSupport.granted;
        case 'denied':
          return ScreenTimeSupport.denied;
        default:
          return ScreenTimeSupport.unavailable;
      }
    } on MissingPluginException {
      return ScreenTimeSupport.unavailable;
    } catch (_) {
      return ScreenTimeSupport.unavailable;
    }
  }

  /// Открыть системные настройки «Доступ к использованию» (Android).
  static Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openUsageAccessSettings');
    } catch (_) {
      // Канала нет (Web/iOS) — тихо игнорируем.
    }
  }

  /// Сколько миллисекунд в интервале [startMs, endMs) экран телефона
  /// был ВКЛЮЧЁН (любое использование устройства).
  ///
  /// Возвращает -1, если данные недоступны (нет канала или разрешения) —
  /// вызывающий код тогда засчитывает весь период фона.
  static Future<int> screenOnMillis(int startMs, int endMs) async {
    try {
      final int? result = await _channel.invokeMethod<int>(
        'screenOnMillis',
        <String, int>{'start': startMs, 'end': endMs},
      );
      return result ?? -1;
    } on MissingPluginException {
      return -1;
    } catch (_) {
      return -1;
    }
  }
}
