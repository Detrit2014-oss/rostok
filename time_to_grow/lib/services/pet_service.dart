import 'package:flutter/foundation.dart';

import '../data/pet_catalog.dart';
import '../models/pet.dart';
import 'storage_service.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Состояние питомцев и глобальной статистики детокса.
/// Минуты «вдали от телефона» = еда для роста питомца.
class PetService extends ChangeNotifier {
  PetService(this._storage);

  final StorageService _storage;

  final List<Pet> pets = <Pet>[];

  int totalMinutes = 0;
  int todayMinutes = 0;
  int streakDays = 0;
  int weekMinutes = 0;

  /// Монетки (v1.5.0): капают за сессии, кормление и задания.
  /// Тратятся в магазине на рамки, еду и заморозку серии 🧊 (v1.7.0).
  int coins = 0;

  /// Заморозки серии 🧊 (v1.7.0): спасают streak при пропуске дня.
  int freezes = 0;

  String _todayKey = '';
  String _lastSessionDayKey = '';
  String _weekKey = '';

  /// Имя питомца, выросшего в ходе последней сессии (для поздравления).
  String? lastEvolvedPetName;

  static const String _kPets = 'pet_list';
  static const String _kTotal = 'stats_total_minutes';
  static const String _kTodayMinutes = 'stats_today_minutes';
  static const String _kTodayKey = 'stats_today_key';
  static const String _kStreak = 'stats_streak';
  static const String _kLastDay = 'stats_last_session_day';
  static const String _kWeekMinutes = 'stats_week_minutes';
  static const String _kWeekKey = 'stats_week_key';
  static const String _kCoins = 'economy_coins';
  static const String _kFreezes = 'economy_freezes';

  /// Цена заморозки серии в магазине (v1.7.0).
  static const int kFreezePrice = 200;

  /// Текущий питомец — тот, что ещё не вырос.
  Pet? get activePet {
    for (final Pet p in pets) {
      if (!p.isAdult) return p;
    }
    return null;
  }

  int get adultCount => pets.where((Pet p) => p.isAdult).length;

  void load() {
    final String raw = _storage.getString(_kPets);
    if (raw.isNotEmpty) {
      try {
        final dynamic decoded = _storage.decodeJson(raw);
        if (decoded is List) {
          pets
            ..clear()
            ..addAll(decoded
                .whereType<Map<String, dynamic>>()
                .map((Map<String, dynamic> e) => Pet.fromJson(e)));
        }
      } catch (_) {
        // Повреждённые данные игнорируем — начнём с нового яйца.
      }
    }
    totalMinutes = _storage.getInt(_kTotal);
    todayMinutes = _storage.getInt(_kTodayMinutes);
    streakDays = _storage.getInt(_kStreak);
    weekMinutes = _storage.getInt(_kWeekMinutes);
    coins = _storage.getInt(_kCoins);
    freezes = _storage.getInt(_kFreezes);
    _todayKey = _storage.getString(_kTodayKey);
    _lastSessionDayKey = _storage.getString(_kLastDay);
    _weekKey = _storage.getString(_kWeekKey);

    _rollDateCounters();
    // С v1.1.0 первого питомца НЕ создаём автоматически:
    // при пустой коллекции приложение показывает большой экран
    // выбора питомца (см. PetSelectionScreen / _PetGate в app.dart).
    notifyListeners();
  }

  void _rollDateCounters() {
    final DateTime now = DateTime.now();
    final String today = _dayKey(now);
    if (today != _todayKey) {
      _todayKey = today;
      todayMinutes = 0;
      _storage.setString(_kTodayKey, today);
      _storage.setInt(_kTodayMinutes, 0);
    }
    final DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    final String week =
        _dayKey(DateTime(monday.year, monday.month, monday.day));
    if (week != _weekKey) {
      _weekKey = week;
      weekMinutes = 0;
      _storage.setString(_kWeekKey, week);
      _storage.setInt(_kWeekMinutes, 0);
    }
  }

  Pet _createEgg() {
    final PetSpecies species = kPetCatalog[pets.length % kPetCatalog.length];
    return Pet(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: species.name,
      type: species.type,
      bornAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Создать питомца выбранного вида — результат большого экрана выбора.
  /// Первый питомец (коллекция пуста) или новый — когда предыдущий вырос.
  Pet? createPet(PetType type) {
    if (activePet != null) return null;
    final PetSpecies species = speciesOfType(type);
    final Pet pet = Pet(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: species.name,
      type: species.type,
      bornAt: DateTime.now().millisecondsSinceEpoch,
    );
    pets.add(pet);
    _persistPets();
    notifyListeners();
    return pet;
  }

  void renamePet(String id, String name) {
    final String clean = name.trim();
    if (clean.isEmpty) return;
    for (final Pet p in pets) {
      if (p.id == id) {
        p.name = clean;
        break;
      }
    }
    _persistPets();
    notifyListeners();
  }

  /// Начислить минуты детокса активному питомцу и общей статистике.
  void addDetoxMinutes(int minutes) {
    if (minutes <= 0) return;
    _rollDateCounters();

    Pet? target = activePet;
    if (target == null) {
      final Pet egg = _createEgg();
      pets.add(egg);
      target = egg;
    }
    final bool wasAdult = target.isAdult;
    target.growthMinutes += minutes;
    if (!wasAdult && target.isAdult) {
      lastEvolvedPetName = target.name;
    }

    totalMinutes += minutes;
    todayMinutes += minutes;
    weekMinutes += minutes;
    // XP-экономика (v1.5.0): 1 минута детокса = 1 XP питомцу и 1 монетка.
    target.xp += minutes;
    coins += minutes;
    _storage.setInt(_kCoins, coins);

    final String today = _dayKey(DateTime.now());
    if (_lastSessionDayKey != today) {
      final String yesterday =
          _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      if (_lastSessionDayKey == yesterday) {
        streakDays += 1;
      } else if (freezes > 0) {
        // 🧊 Заморозка спасает серию (v1.7.0).
        freezes -= 1;
        _storage.setInt(_kFreezes, freezes);
        streakDays += 1;
      } else {
        streakDays = 1;
      }
      _lastSessionDayKey = today;
      _storage.setString(_kLastDay, today);
      _storage.setInt(_kStreak, streakDays);
    }

    _persistPets();
    _storage.setInt(_kTotal, totalMinutes);
    _storage.setInt(_kTodayMinutes, todayMinutes);
    _storage.setInt(_kWeekMinutes, weekMinutes);
    notifyListeners();
  }

  void ackEvolution() {
    lastEvolvedPetName = null;
  }

  /// Начислить питомцу XP (кормление, задания, укладывание спать).
  void addXp(Pet pet, int amount) {
    if (amount <= 0) return;
    pet.xp += amount;
    _persistPets();
    notifyListeners();
  }

  void earnCoins(int amount) {
    if (amount <= 0) return;
    coins += amount;
    _storage.setInt(_kCoins, coins);
    notifyListeners();
  }

  /// Списать монеты; false — если не хватает.
  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (coins < amount) return false;
    coins -= amount;
    _storage.setInt(_kCoins, coins);
    notifyListeners();
    return true;
  }

  /// Купить декоративную рамку питомцу из магазина (v1.5.0).
  bool buyFrame(Pet pet, String frameId, int price) {
    if (pet.frame == frameId) return true;
    if (!spendCoins(price)) return false;
    pet.frame = frameId;
    _persistPets();
    notifyListeners();
    return true;
  }

  /// Купить заморозку серии 🧊 (v1.7.0) — максимум 2 в запасе.
  bool buyFreeze() {
    if (freezes >= 2) return false;
    if (!spendCoins(kFreezePrice)) return false;
    freezes += 1;
    _storage.setInt(_kFreezes, freezes);
    notifyListeners();
    return true;
  }

  void _persistPets() {
    _storage.setString(
      _kPets,
      _storage.encodeJson(pets.map((Pet p) => p.toJson()).toList()),
    );
  }

  void reset() {
    pets.clear();
    totalMinutes = 0;
    todayMinutes = 0;
    streakDays = 0;
    weekMinutes = 0;
    coins = 0;
    freezes = 0;
    lastEvolvedPetName = null;
    _lastSessionDayKey = '';
    _storage.setInt(_kTotal, 0);
    _storage.setInt(_kTodayMinutes, 0);
    _storage.setInt(_kStreak, 0);
    _storage.setInt(_kWeekMinutes, 0);
    _storage.setInt(_kCoins, 0);
    _storage.setInt(_kFreezes, 0);
    _storage.setString(_kLastDay, '');
    // Коллекция пуста → приложение снова покажет экран выбора питомца.
    _persistPets();
    notifyListeners();
  }
}
