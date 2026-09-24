import 'package:flutter/foundation.dart';

import '../models/quest.dart';
import 'pet_service.dart';
import 'storage_service.dart';

/// Сервис заданий (v1.7.0): 3 ежедневных задания, детерминированно по дате.
/// Прогресс капает от событий (сессия, кормление, дневник, сон, магазин).
class QuestService extends ChangeNotifier {
  QuestService(this._storage, this._pets) {
    // Минуты сессий детокса автоматически капают в задания session_*.
    _lastTotal = _pets.totalMinutes;
    _pets.addListener(_onPetsChanged);
  }

  final StorageService _storage;
  final PetService _pets;
  int _lastTotal = 0;

  void _onPetsChanged() {
    final int delta = _pets.totalMinutes - _lastTotal;
    if (delta > 0) {
      _lastTotal = _pets.totalMinutes;
      addProgress('session_10', delta);
      addProgress('session_30', delta);
    } else {
      _lastTotal = _pets.totalMinutes;
    }
  }

  @override
  void dispose() {
    _pets.removeListener(_onPetsChanged);
    super.dispose();
  }

  /// Прогресс по id задания за сегодня.
  final Map<String, int> progress = <String, int>{};

  /// Уже полученные награды сегодня.
  final Set<String> claimed = <String>[];

  /// Всего выполненных заданий (для открыток).
  int questsDoneTotal = 0;

  String _dayKey = '';

  static const String _kDay = 'quests_day';
  static const String _kProgress = 'quests_progress';
  static const String _kClaimed = 'quests_claimed';
  static const String _kTotal = 'quests_total_done';

  List<Quest> get todayQuests => dailyQuests(_dayKey.isEmpty ? currentDayKey : _dayKey);

  String get currentDayKey {
    final DateTime d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void load() {
    _dayKey = _storage.getString(_kDay);
    final String rawP = _storage.getString(_kProgress);
    final String rawC = _storage.getString(_kClaimed);
    questsDoneTotal = _storage.getInt(_kTotal);

    if (_dayKey != currentDayKey) {
      // Новый день — задания обновляются.
      _rollDay();
    } else {
      try {
        if (rawP.isNotEmpty) {
          final dynamic d = _storage.decodeJson(rawP);
          if (d is Map) {
            d.forEach((dynamic k, dynamic v) =>
                progress[k.toString()] = (v as num?)?.toInt() ?? 0);
          }
        }
        if (rawC.isNotEmpty) {
          final dynamic d = _storage.decodeJson(rawC);
          if (d is List) claimed.addAll(d.whereType<String>());
        }
      } catch (_) {
        progress.clear();
        claimed.clear();
      }
    }
  }

  void _rollDay() {
    _dayKey = currentDayKey;
    progress.clear();
    claimed.clear();
    _storage.setString(_kDay, _dayKey);
    _persist();
    _storage.setInt(_kTotal, questsDoneTotal);
  }

  /// Вызывается при каждом открытии главного экрана — перекатывает день.
  void ensureToday() {
    if (_dayKey != currentDayKey) {
      _rollDay();
      notifyListeners();
    }
  }

  void addProgress(String questId, int amount) {
    ensureToday();
    if (claimed.contains(questId)) return;
    final int cur = progress[questId] ?? 0;
    if (cur >= _targetOf(questId)) return;
    progress[questId] = cur + amount;
    _persist();
    notifyListeners();
  }

  int _targetOf(String questId) {
    for (final Quest q in kQuestPool) {
      if (q.id == questId) return q.target;
    }
    return 1;
  }

  bool isComplete(Quest q) => (progress[q.id] ?? 0) >= q.target;
  bool isClaimed(Quest q) => claimed.contains(q.id);

  /// Забрать награду за выполненное задание.
  bool claim(Quest q) {
    ensureToday();
    if (!isComplete(q) || isClaimed(q)) return false;
    claimed.add(q.id);
    questsDoneTotal += 1;
    _pets.earnCoins(q.rewardCoins);
    final Pet? active = _pets.activePet;
    if (active != null) _pets.addXp(active, q.rewardXp);
    _persist();
    _storage.setInt(_kTotal, questsDoneTotal);
    notifyListeners();
    return true;
  }

  void _persist() {
    _storage.setString(_kProgress, _storage.encodeJson(progress));
    _storage.setString(_kClaimed, _storage.encodeJson(claimed.toList()));
  }

  void reset() {
    progress.clear();
    claimed.clear();
    questsDoneTotal = 0;
    _dayKey = '';
    _storage.setString(_kDay, '');
    _storage.setInt(_kTotal, 0);
    _persist();
    notifyListeners();
  }
}
