import '../data/pet_catalog.dart';
import '../data/species_style.dart';
import '../models/pet.dart';

/// Достижение «Ростка» (v1.5.0): открывается автоматически,
/// когда выполнено условие. Всего 23 — как медалей в шкафу.
class Achievement {
  const Achievement(
    this.id,
    this.emoji,
    this.title,
    this.description,
    this.check,
  );

  final String id;
  final String emoji;
  final String title;
  final String description;

  /// Статистика снапшота для проверки условий.
  final bool Function(AchievementStats s) check;

  static const List<Achievement> kAchievements = <Achievement>[
    // Первые шаги
    Achievement('first_egg', '🥚', 'Первое яйцо',
        'Завести своего первого питомца', (AchievementStats s) => s.petsTotal >= 1),
    Achievement('first_hatch', '🐣', 'Здравствуй, мир!',
        'Питомец вылупился из яйца', (AchievementStats s) => s.petsAdult >= 0 && s.petsTotal >= 1 && s.anyHatched),
    Achievement('first_adult', '🦊', 'Совсем большой',
        'Вырастить питомца до взрослого', (AchievementStats s) => s.petsAdult >= 1),
    Achievement('first_session', '⏱️', 'Первая пауза',
        'Провести первую сессию детокса', (AchievementStats s) => s.totalMinutes >= 1),
    Achievement('ten_sessions', '🌱', 'Десять минут тишины',
        'Накопить 10 минут детокса', (AchievementStats s) => s.totalMinutes >= 10),
    // Время и серии
    Achievement('hour', '🕐', 'Час без телефона',
        'Накопить 60 минут детокса', (AchievementStats s) => s.totalMinutes >= 60),
    Achievement('five_hours', '🌿', 'Пять часов свободы',
        'Накопить 300 минут детокса', (AchievementStats s) => s.totalMinutes >= 300),
    Achievement('day_total', '🌳', 'Сутки тишины',
        'Накопить 24 часа детокса', (AchievementStats s) => s.totalMinutes >= 1440),
    Achievement('streak_3', '🔥', 'Три дня подряд',
        'Серия из 3 дней', (AchievementStats s) => s.streakDays >= 3),
    Achievement('streak_7', '⚡', 'Неделя огня',
        'Серия из 7 дней', (AchievementStats s) => s.streakDays >= 7),
    Achievement('streak_30', '🌟', 'Месяц дисциплины',
        'Серия из 30 дней', (AchievementStats s) => s.streakDays >= 30),
    // Коллекция
    Achievement('collect_3', '🧺', 'Маленькая семья',
        'Три питомца в коллекции', (AchievementStats s) => s.petsTotal >= 3),
    Achievement('collect_5', '🏡', 'Уютный домик',
        'Пять питомцев в коллекции', (AchievementStats s) => s.petsTotal >= 5),
    Achievement('plants_lover', '🪴', 'Садовник',
        'Завести комнатное растение', (AchievementStats s) => s.hasPlant),
    Achievement('sea_lover', '🌊', 'Морская душа',
        'Завести водного питомца', (AchievementStats s) => s.hasAquatic),
    Achievement('zoo_10', '🎪', 'Зоопарк',
        'Десять разных видов в коллекции', (AchievementStats s) => s.uniqueSpecies >= 10),
    // Экономика
    Achievement('rich_100', '💰', 'Первая сотня',
        'Накопить 100 монет', (AchievementStats s) => s.coins >= 100),
    Achievement('rich_500', '💰', 'Капиталец',
        'Накопить 500 монет', (AchievementStats s) => s.coins >= 500),
    Achievement('shopper', '🛍️', 'Модный питомец',
        'Купить рамку в магазине', (AchievementStats s) => s.hasFrame),
    Achievement('level_5', '🎖️', 'Пятый уровень',
        'Прокачать питомца до 5 уровня', (AchievementStats s) => s.maxLevel >= 5),
    Achievement('level_10', '🏆', 'Десятый уровень',
        'Прокачать питомца до 10 уровня', (AchievementStats s) => s.maxLevel >= 10),
    // Дневник и забота
    Achievement('diary_5', '📓', 'Летописец',
        'Пять записей в дневнике', (AchievementStats s) => s.diaryCount >= 5),
    Achievement('diary_20', '📚', 'Хроника тишины',
        'Двадцать записей в дневнике', (AchievementStats s) => s.diaryCount >= 20),
  ];
}

/// Снимок статистики для проверки достижений.
class AchievementStats {
  const AchievementStats({
    required this.petsTotal,
    required this.petsAdult,
    required this.anyHatched,
    required this.totalMinutes,
    required this.streakDays,
    required this.uniqueSpecies,
    required this.hasPlant,
    required this.hasAquatic,
    required this.hasFrame,
    required this.maxLevel,
    required this.coins,
    required this.diaryCount,
  });

  final int petsTotal;
  final int petsAdult;
  final bool anyHatched;
  final int totalMinutes;
  final int streakDays;
  final int uniqueSpecies;
  final bool hasPlant;
  final bool hasAquatic;
  final bool hasFrame;
  final int maxLevel;
  final int coins;
  final int diaryCount;

  factory AchievementStats.fromData({
    required List<Pet> pets,
    required int totalMinutes,
    required int streakDays,
    required int coins,
    required int diaryCount,
  }) {
    final Set<PetType> kinds = pets.map((Pet p) => p.type).toSet();
    return AchievementStats(
      petsTotal: pets.length,
      petsAdult: pets.where((Pet p) => p.isAdult).length,
      anyHatched: pets.isNotEmpty,
      totalMinutes: totalMinutes,
      streakDays: streakDays,
      uniqueSpecies: kinds.length,
      hasPlant: kinds.any(isPlant),
      hasAquatic: kinds.any(isAquatic),
      hasFrame: pets.any((Pet p) => p.frame != 'none'),
      maxLevel: pets.fold<int>(0, (int m, Pet p) => math_max(m, p.level)),
      coins: coins,
      diaryCount: diaryCount,
    );
  }

  static int math_max(int a, int b) => a > b ? a : b;
}
