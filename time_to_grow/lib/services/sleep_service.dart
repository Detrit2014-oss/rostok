import 'package:flutter/foundation.dart';

import '../models/quest.dart';
import 'pet_service.dart';
import 'storage_service.dart';

/// Сервис сна (v1.7.0): «Уложить питомца спать» — раз в день,
/// +20 XP. Питомец при этом спит ЛЕЖА (рисует PetCanvas).
class SleepService extends ChangeNotifier {
  SleepService(this._storage, this._pets);

  final StorageService _storage;
  final PetService _pets;

  String _lastTuckInDay = '';

  static const String _kDay = 'sleep_tuck_in_day';

  String get currentDayKey {
    final DateTime d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool get tuckedInToday => _lastTuckInDay == currentDayKey;

  void load() {
    _lastTuckInDay = _storage.getString(_kDay);
  }

  /// Уложить спать. true — если сегодня ещё не укладывали.
  bool tuckIn() {
    if (tuckedInToday) return false;
    _lastTuckInDay = currentDayKey;
    _storage.setString(_kDay, _lastTuckInDay);
    final Pet? pet = _pets.activePet;
    if (pet != null) _pets.addXp(pet, kXpPerTuckIn);
    notifyListeners();
    return true;
  }

  void reset() {
    _lastTuckInDay = '';
    _storage.setString(_kDay, '');
    notifyListeners();
  }
}
