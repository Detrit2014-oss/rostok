import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_update.dart';

/// ─────────────────────────────────────────────────────────────────────
/// Источники информации об обновлениях (гибридная схема):
///
///  • JsonHttpUpdateSource — АКТИВЕН: статический version.json по URL
///    (GitHub Pages / любой хостинг). Инструкция: docs/UPDATE_FLOW.md
///  • RemoteConfigUpdateSource — заготовка под Firebase Remote Config (v2),
///    активируется после подключения Firebase (docs/FIREBASE.md).
/// ─────────────────────────────────────────────────────────────────────
abstract class UpdateSource {
  Future<AppUpdateInfo?> fetchLatest();
}

class JsonHttpUpdateSource implements UpdateSource {
  JsonHttpUpdateSource(this.uri);

  final Uri uri;

  @override
  Future<AppUpdateInfo?> fetchLatest() async {
    final http.Response response =
        await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    return AppUpdateInfo.fromJson(data);
  }
}

/// Заготовка под Firebase Remote Config.
/// Активация: подключите firebase_remote_config (см. docs/FIREBASE.md),
/// затем реализуйте метод ниже: ключ version_info хранит JSON
/// той же структуры, что и version.json.
class RemoteConfigUpdateSource implements UpdateSource {
  const RemoteConfigUpdateSource();

  @override
  Future<AppUpdateInfo?> fetchLatest() async {
    // TODO(v2): FirebaseRemoteConfig.instance.getString('version_info')
    //  → AppUpdateInfo.fromJson(jsonDecode(raw));
    return null;
  }
}
