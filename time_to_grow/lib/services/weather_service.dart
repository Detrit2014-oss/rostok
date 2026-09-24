import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

/// Погодные состояния сцены (v1.7.0) — 7 состояний по кодам WMO.
enum WeatherCondition { clear, partly, cloudy, fog, rain, snow, thunder }

WeatherCondition weatherFromWmo(int code) {
  if (code == 0) return WeatherCondition.clear;
  if (code == 1 || code == 2) return WeatherCondition.partly;
  if (code == 3 || code == 45 || code == 48) {
    return code == 45 || code == 48
        ? WeatherCondition.fog
        : WeatherCondition.cloudy;
  }
  if (code >= 51 && code <= 67) return WeatherCondition.rain;
  if (code >= 71 && code <= 77) return WeatherCondition.snow;
  if (code >= 80 && code <= 82) return WeatherCondition.rain;
  if (code == 85 || code == 86) return WeatherCondition.snow;
  if (code >= 95) return WeatherCondition.thunder;
  return WeatherCondition.partly;
}

/// Ключ сцены для PetCanvas.weather: null = ясно.
String? sceneWeatherKey(WeatherCondition c) => switch (c) {
      WeatherCondition.clear => null,
      WeatherCondition.partly => 'partly',
      WeatherCondition.cloudy => 'cloudy',
      WeatherCondition.fog => 'fog',
      WeatherCondition.rain => 'rain',
      WeatherCondition.snow => 'snow',
      WeatherCondition.thunder => 'thunder',
    };

/// Детерминированная «демо-погода» по дате (без GPS/сети).
WeatherCondition deterministicWeather(String dayKey) {
  int h = 7;
  for (int i = 0; i < dayKey.length; i++) {
    h = (h * 31 + dayKey.codeUnitAt(i)) & 0x7fffffff;
  }
  const List<WeatherCondition> wheel = <WeatherCondition>[
    WeatherCondition.clear,
    WeatherCondition.clear,
    WeatherCondition.partly,
    WeatherCondition.partly,
    WeatherCondition.cloudy,
    WeatherCondition.rain,
    WeatherCondition.snow,
    WeatherCondition.fog,
    WeatherCondition.thunder,
  ];
  return wheel[h % wheel.length];
}

/// Сервис погоды: Open-Meteo без API-ключа + geolocator.
/// На вебе (kIsWeb) GPS не запрашиваем — берём демо-погоду по дате.
class WeatherService extends ChangeNotifier {
  WeatherService(this._storage);

  final StorageService _storage;

  WeatherCondition condition = WeatherCondition.clear;
  String? cityLabel;
  bool loading = false;
  String? error;

  static const String _kMode = 'weather_mode'; // auto|date
  String mode = 'auto';

  String get dayKey {
    final DateTime d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Ключ сцены для PetCanvas (null = ясно).
  String? get sceneKey =>
      sceneWeatherKey(condition) ??
      (mode == 'date' ? null : null);

  void load() {
    final String m = _storage.getString(_kMode);
    if (m == 'auto' || m == 'date') mode = m;
    // Мгновенный ответ — по дате, сеть догонит фоном.
    condition = deterministicWeather(dayKey);
  }

  void setMode(String m) {
    mode = m;
    _storage.setString(_kMode, m);
    if (m == 'date') {
      condition = deterministicWeather(dayKey);
      notifyListeners();
    } else {
      refresh();
    }
  }

  /// Обновить погоду: GPS → Open-Meteo. Ошибки мягкие — остаётся демо.
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        condition = deterministicWeather(dayKey);
        cityLabel = null;
      } else {
        final LocationPermission perm =
            await Geolocator.checkPermission();
        LocationPermission p = perm;
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
        }
        if (p == LocationPermission.denied ||
            p == LocationPermission.deniedForever) {
          condition = deterministicWeather(dayKey);
          error = 'Нет доступа к геолокации — показываем погоду по дате';
        } else {
          final Position pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.low),
          );
          final Uri uri = Uri.parse(
            'https://api.open-meteo.com/v1/forecast'
            '?latitude=${pos.latitude.toStringAsFixed(3)}'
            '&longitude=${pos.longitude.toStringAsFixed(3)}'
            '&current=weather_code',
          );
          final http.Response resp =
              await http.get(uri).timeout(const Duration(seconds: 8));
          if (resp.statusCode == 200) {
            final dynamic data = jsonDecode(resp.body);
            final int code =
                (data['current']?['weather_code'] as num?)?.toInt() ?? 0;
            condition = weatherFromWmo(code);
            cityLabel = 'по GPS';
          } else {
            condition = deterministicWeather(dayKey);
            error = 'Сервис погоды недоступен — погода по дате';
          }
        }
      }
    } catch (_) {
      condition = deterministicWeather(dayKey);
      error = 'Погода по дате (нет сети или доступа)';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
