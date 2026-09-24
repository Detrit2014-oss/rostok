import 'package:flutter/foundation.dart';

import '../models/achievement.dart';
import 'pet_service.dart';
import 'storage_service.dart';

/// Сервис достижений (v1.5.0): пересчитывает разблокировки по статистике
/// и хранит список открытых id. Возвращает новые ачивки для тостов.
class AchievementService extends ChangeNotifier {
  AchievementService(this._storage, this._pets);

  final StorageService _storage;
  final PetService _pets;

  final Set<String> unlocked = <String>[];

  static const String _kUnlocked = 'achievements_unlocked';

  /// Дневник нужен для diary-ачивок (ленивая зависимость — цикла нет,
  /// т.к. DiaryService не ссылается на достижения).
  int Function() diaryCountProvider = () => 0;

  void load() {
    final String raw = _storage.getString(_kUnlocked);
    if (raw.isNotEmpty) {
      try {
        final dynamic decoded = _storage.decodeJson(raw);
        if (decoded is List) {
          unlocked
            ..clear()
            ..addAll(decoded.whereType<String>());
        }
      } catch (_) {
        unlocked.clear();
      }
    }
  }

  /// Пересчитать достижения. Возвращает только что открытые.
  List<Achievement> recompute() {
    final AchievementStats stats = AchievementStats.fromData(
      pets: _pets.pets,
      totalMinutes: _pets.totalMinutes,
      streakDays: _pets.streakDays,
      coins: _pets.coins,
      diaryCount: diaryCountProvider(),
    );
    final List<Achievement> fresh = <Achievement>[];
    for (final Achievement a in Achievement.kAchievements) {
      if (!unlocked.contains(a.id) && a.check(stats)) {
        unlocked.add(a.id);
        fresh.add(a);
      }
    }
    if (fresh.isNotEmpty) {
      _storage.setString(_kUnlocked, _storage.encodeJson(unlocked.toList()));
      notifyListeners();
    }
    return fresh;
  }

  int get count => unlocked.length;
  int get total => Achievement.kAchievements.length;
}
