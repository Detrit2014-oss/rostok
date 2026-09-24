/// Тип питомца — влияет на внешность в процедурной отрисовке.
/// С v1.5.0 видов тридцать: 24 зверя + 6 комнатных растений.
/// Все нарисованы кодом (CustomPaint), ни одной картинки-ассета.
enum PetType {
  // ── Звери (24) ──
  fox, cat, owl, dragon, duck, bunny, penguin, hedgehog, panda, bear,
  dog, deer, seal, whale, turtle, frog, squirrel, raccoon, koala,
  pig, chick, unicorn, octopus, crab,
  // ── Комнатные растения (6) ──
  cactus, bonsai, succulent, sunflower, clover, sprout,
}

/// Водные жители — на главном экране живут в пруду по центру лужайки.
const Set<PetType> kAquaticPets = <PetType>{
  PetType.whale, PetType.seal, PetType.octopus, PetType.crab, PetType.turtle,
};

/// Пороги уровней XP: уровень N+1 открывается при xp >= kXpLevels[N].
const List<int> kXpLevels = <int>[0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700];

/// Уровень питомца по накопленному XP (после 10-го — +550 XP за уровень).
int petLevelFromXp(int xp) {
  int level = 1;
  for (int i = 0; i < kXpLevels.length; i++) {
    if (xp >= kXpLevels[i]) level = i + 1;
  }
  if (xp >= kXpLevels.last) {
    level += ((xp - kXpLevels.last) / 550).floor();
  }
  return level;
}

/// Прогресс 0..1 внутри текущего уровня питомца.
double petLevelProgress(int xp) {
  final int level = petLevelFromXp(xp);
  if (level <= 1) return (xp / 100).clamp(0.0, 1.0);
  final int prev;
  final int next;
  if (level <= kXpLevels.length) {
    prev = kXpLevels[level - 2];
    next = kXpLevels[level - 1];
  } else {
    final int base = kXpLevels.last + (level - kXpLevels.length - 1) * 550;
    prev = base;
    next = base + 550;
  }
  return ((xp - prev) / (next - prev)).clamp(0.0, 1.0);
}

/// Питомец — сердце приложения. Растёт от минут, проведённых
/// «вдали от телефона» (сессии цифрового детокса).
class Pet {
  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.bornAt,
    this.growthMinutes = 0,
    this.xp = 0,
  });

  final String id;

  /// Имя можно менять (карандаш на карточке питомца).
  String name;
  final PetType type;
  final int bornAt;

  /// Минуты «вдали от телефона», накопленные питомцем.
  int growthMinutes;

  /// Опыт питомца (v1.5.0): сессии, кормление, задания. Уровень — petLevel.
  int xp;

  /// Название декоративной рамки из магазина (v1.5.0): none|gold|neon|flower.
  String frame = 'none';

  int get level => petLevelFromXp(xp);
  double get levelProgress => petLevelProgress(xp);

  /// Пороги стадий в минутах: яйцо → малыш → подросток → взрослый.
  static const List<int> stageThresholds = <int>[0, 5, 15, 30];

  int get stage {
    if (growthMinutes >= stageThresholds[3]) return 3;
    if (growthMinutes >= stageThresholds[2]) return 2;
    if (growthMinutes >= stageThresholds[1]) return 1;
    return 0;
  }

  String get stageName {
    switch (stage) {
      case 0:
        return 'Яйцо';
      case 1:
        return 'Малыш';
      case 2:
        return 'Подросток';
      default:
        return 'Взрослый';
    }
  }

  /// Прогресс внутри текущей стадии: 0..1.
  double get stageProgress {
    if (stage >= 3) return 1;
    final int next = stageThresholds[stage + 1];
    final int prev = stageThresholds[stage];
    return ((growthMinutes - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  /// Сколько минут осталось до следующей стадии.
  int minutesToNextStage() {
    if (stage >= 3) return 0;
    return stageThresholds[stage + 1] - growthMinutes;
  }

  bool get isAdult => stage >= 3;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type.name,
        'bornAt': bornAt,
        'growthMinutes': growthMinutes,
        'xp': xp,
        'frame': frame,
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String? ?? 'p0',
        name: json['name'] as String? ?? 'Питомец',
        type: PetType.values.firstWhere(
          (PetType e) => e.name == (json['type'] as String? ?? 'fox'),
          orElse: () => PetType.fox,
        ),
        bornAt: (json['bornAt'] as num?)?.toInt() ?? 0,
        growthMinutes: (json['growthMinutes'] as num?)?.toInt() ?? 0,
      )
        ..xp = (json['xp'] as num?)?.toInt() ?? 0
        ..frame = json['frame'] as String? ?? 'none';
}
