import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Простая обёртка над SharedPreferences: единое хранилище для Android,
/// iOS и Web — один и тот же API на всех платформах.
class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String getString(String key, {String defaultValue = ''}) =>
      _prefs.getString(key) ?? defaultValue;

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  String encodeJson(Object? value) => jsonEncode(value);

  dynamic decodeJson(String raw) => jsonDecode(raw);

  /// Безопасный разбор строкового JSON-списка (например, гардероб).
  List<String> decodeJsonList(String raw) {
    if (raw.isEmpty) return <String>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {
      // Повреждённые данные игнорируем.
    }
    return <String>[];
  }
}
