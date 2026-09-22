import '../models/challenge.dart';
import 'storage_service.dart';

/// ─────────────────────────────────────────────────────────────────────
/// Точка подключения бэкенда челленджей.
///
/// v1.0.0 — DemoChallengeBackend: локальное хранилище, друзья-боты,
///          ваш реальный прогресс из сессий детокса. Работает сразу,
///          включая тест в Chrome.
/// v2.0   — FirestoreChallengeBackend: готовый код и пошаговая инструкция
///          в docs/FIREBASE.md (реальные друзья, код комнаты, живой лидерборд).
/// ─────────────────────────────────────────────────────────────────────
abstract class ChallengeBackend {
  Future<Challenge?> load();
  Future<void> save(Challenge challenge);
}

class DemoChallengeBackend implements ChallengeBackend {
  DemoChallengeBackend(this._storage);

  final StorageService _storage;

  static const String _kWeekly = 'challenge_weekly';

  @override
  Future<Challenge?> load() async {
    final String raw = _storage.getString(_kWeekly);
    if (raw.isEmpty) return null;
    try {
      final dynamic decoded = _storage.decodeJson(raw);
      if (decoded is Map<String, dynamic>) {
        return Challenge.fromJson(decoded);
      }
    } catch (_) {
      // Повреждённые данные — создадим новый челлендж.
    }
    return null;
  }

  @override
  Future<void> save(Challenge challenge) async {
    _storage.setString(_kWeekly, _storage.encodeJson(challenge.toJson()));
  }
}
