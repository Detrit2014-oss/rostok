import '../data/species_style.dart';
import '../models/pet.dart';

/// ─────────────────────────────────────────────────────────────────────
/// Ежедневные задания «Ростка» (v1.7.0). Каждый день детерминированно
/// (хеш даты) выпадают 3 задания из пула — у всех одинаково, без
/// сервера. Сезонные события и открытки — тоже отсюда.
/// ─────────────────────────────────────────────────────────────────────

class Quest {
  const Quest(
    this.id,
    this.emoji,
    this.title,
    this.hint,
    this.target,
    this.rewardCoins,
    this.rewardXp,
  );

  final String id;
  final String emoji;
  final String title;

  /// Что нужно делать.
  final String hint;

  /// Сколько единиц прогресса нужно (минуты, разы…).
  final int target;
  final int rewardCoins;
  final int rewardXp;
}

const List<Quest> kQuestPool = <Quest>[
  Quest('session_10', '⏱️', 'Десять минут тишины',
      'Провести 10 минут в сессии детокса', 10, 15, 10),
  Quest('session_30', '🌿', 'Полчаса без телефона',
      'Провести 30 минут в сессии детокса', 30, 30, 20),
  Quest('feed_5', '🍽️', 'Сытный обед',
      'Поймать 5 едой в мини-игре «Покорми питомца»', 5, 20, 15),
  Quest('diary_1', '📓', 'Вечерняя заметка',
      'Написать запись в дневнике', 1, 15, 10),
  Quest('tuck_in', '🌙', 'Спокойной ночи',
      'Уложить питомца спать', 1, 10, 5),
  Quest('shop_1', '🛍️', 'Заглянуть в магазин',
      'Купить что-нибудь за монетки', 1, 10, 5),
];

/// Сезонное событие — по месяцу определяем оформление и бонус-задание.
class SeasonEvent {
  const SeasonEvent(this.id, this.title, this.emoji, this.description);
  final String id;
  final String title;
  final String emoji;
  final String description;
}

const List<SeasonEvent> kSeasonEvents = <SeasonEvent>[
  SeasonEvent('spring', 'Весенний сад', '🌸',
      'Всё цветёт! Питомцы получают +10% XP в этом сезоне.'),
  SeasonEvent('summer', 'Летний пикник', '☀️',
      'Яркое солнце! Еда в мини-игре падает чуть быстрее.'),
  SeasonEvent('autumn', 'Осенний листопад', '🍂',
      'Время открыток: собирайте осенние виды!'),
  SeasonEvent('winter', 'Зимняя ярмарка', '❄️',
      'Снежные вечера: серии дней растут быстрее.'),
];

SeasonEvent seasonOf(DateTime now) {
  if (now.month >= 3 && now.month <= 5) return kSeasonEvents[0];
  if (now.month >= 6 && now.month <= 8) return kSeasonEvents[1];
  if (now.month >= 9 && now.month <= 11) return kSeasonEvents[2];
  return kSeasonEvents[3];
}

/// ── Детерминированный хеш (lehmer-подобный) ──────────────────────────
int questHash(String input) {
  int h = 2166136261;
  for (int i = 0; i < input.length; i++) {
    h ^= input.codeUnitAt(i);
    h = (h * 16777619) & 0x7fffffff;
    h = (h * 48271) & 0x7fffffff;
  }
  return h;
}

/// Три задания дня — одинаково для всех в этот день.
List<Quest> dailyQuests(String dayKey) {
  final int seed = questHash('rostok-quests-$dayKey');
  final List<int> idx = <int>[0, 1, 2, 3, 4, 5];
  // Простое перемешивание по сиду.
  int s = seed;
  for (int i = idx.length - 1; i > 0; i--) {
    s = (s * 48271) & 0x7fffffff;
    final int j = s % (i + 1);
    final int tmp = idx[i];
    idx[i] = idx[j];
    idx[j] = tmp;
  }
  return <Quest>[kQuestPool[idx[0]], kQuestPool[idx[1]], kQuestPool[idx[2]]];
}

/// XP за укладывание спать (v1.7.0).
const int kXpPerTuckIn = 20;

/// ── Открытки (10 штук) ───────────────────────────────────────────────
class Postcard {
  const Postcard(this.id, this.emoji, this.title, this.howTo);
  final String id;
  final String emoji;
  final String title;
  final String howTo;
}

const List<Postcard> kPostcards = <Postcard>[
  Postcard('pc_first', '🐣', 'Первый друг', 'Вылупите первого питомца'),
  Postcard('pc_streak3', '🔥', 'Три дня подряд', 'Серия из 3 дней'),
  Postcard('pc_streak7', '⚡', 'Неделя огня', 'Серия из 7 дней'),
  Postcard('pc_300', '🌿', 'Пять часов', '300 минут детокса всего'),
  Postcard('pc_adult', '🦊', 'Совсем большой', 'Вырастите взрослого питомца'),
  Postcard('pc_coins', '🪙', 'Запасливый', 'Накопите 500 монеток'),
  Postcard('pc_quests5', '📋', 'Исполнитель', 'Выполните 5 заданий'),
  Postcard('pc_quests15', '🏆', 'Мастер пауз', 'Выполните 15 заданий'),
  Postcard('pc_diary10', '📓', 'Летописец', '10 записей в дневнике'),
  Postcard('pc_zoo', '🎪', 'Зоопарк', '10 разных видов в коллекции'),
];

/// Условие открытки по статистике (зеркалится в демо).
bool postcardUnlocked(Postcard pc, PostcardStats st) {
  switch (pc.id) {
    case 'pc_first':
      return st.petsTotal >= 1;
    case 'pc_streak3':
      return st.streakDays >= 3;
    case 'pc_streak7':
      return st.streakDays >= 7;
    case 'pc_300':
      return st.totalMinutes >= 300;
    case 'pc_adult':
      return st.petsAdult >= 1;
    case 'pc_coins':
      return st.coins >= 500;
    case 'pc_quests5':
      return st.questsDone >= 5;
    case 'pc_quests15':
      return st.questsDone >= 15;
    case 'pc_diary10':
      return st.diaryCount >= 10;
    case 'pc_zoo':
      return st.uniqueSpecies >= 10;
    default:
      return false;
  }
}

class PostcardStats {
  const PostcardStats({
    required this.petsTotal,
    required this.petsAdult,
    required this.totalMinutes,
    required this.streakDays,
    required this.coins,
    required this.questsDone,
    required this.diaryCount,
    required this.uniqueSpecies,
  });

  final int petsTotal;
  final int petsAdult;
  final int totalMinutes;
  final int streakDays;
  final int coins;
  final int questsDone;
  final int diaryCount;
  final int uniqueSpecies;

  factory PostcardStats.fromPets({
    required List<Pet> pets,
    required int totalMinutes,
    required int streakDays,
    required int coins,
    required int questsDone,
    required int diaryCount,
  }) {
    final Set<PetType> kinds = pets.map((Pet p) => p.type).toSet();
    return PostcardStats(
      petsTotal: pets.length,
      petsAdult: pets.where((Pet p) => p.isAdult).length,
      totalMinutes: totalMinutes,
      streakDays: streakDays,
      coins: coins,
      questsDone: questsDone,
      diaryCount: diaryCount,
      uniqueSpecies: kinds.length,
    );
  }
}
