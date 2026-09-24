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

/// Растения — растут из СЕМЕЧКА (v1.9.0), а не из яйца.
const Set<PetType> kPlantPets = <PetType>{
  PetType.cactus, PetType.bonsai, PetType.succulent,
  PetType.sunflower, PetType.clover, PetType.sprout,
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
    this.fromSeed = false,
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

  /// Растения (v1.9.0) выращены из семечка — у них нет стадии «Яйцо».
  bool fromSeed;

  /// Название декоративной рамки из магазина (v1.5.0): none|gold|neon|flower.
  String frame = 'none';

  // ── Гардероб (v1.9.0): аксессуары и окрас ──
  /// Шапка: none|cap|beanie|crown.
  String hat = 'none';
  /// Шея: none|scarf|bow.
  String neck = 'none';
  /// Лицо: none|glasses|shades.
  String face = 'none';
  /// Окрас-скин: classic|golden|mint|rose.
  String skin = 'classic';

  /// Уже забранные возрастные подарки (дни): [1, 3, 7...].
  List<int> claimedAges = <int>[];

  int get level => petLevelFromXp(xp);
  double get levelProgress => petLevelProgress(xp);

  /// Пороги стадий в минутах: яйцо/семечко → малыш → подросток → взрослый.
  /// v1.9.0: рост замедлен в 20 раз (раньше взрослый был через 30 минут).
  static const List<int> stageThresholds = <int>[0, 100, 300, 600];

  int get stage {
    if (growthMinutes >= stageThresholds[3]) return 3;
    if (growthMinutes >= stageThresholds[2]) return 2;
    if (growthMinutes >= stageThresholds[1]) return 1;
    return 0;
  }

  /// Название первой стадии: у зверей — «Яйцо», у растений — «Семечко».
  String get stage0Name =>
      kPlantPets.contains(type) ? 'Семечко' : 'Яйцо';

  String get stageName {
    switch (stage) {
      case 0:
        return stage0Name;
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

  // ── Возраст (v1.9.0) ──

  /// Полных дней с момента появления питомца (яйцо/семечко).
  int ageDays([int? nowMs]) {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final int days = ((now - bornAt) / 86400000).floor();
    if (days < 0) return 0;
    return days;
  }

  /// Возрастные вехи: день → подарок (монетки; столько же XP).
  static const Map<int, int> ageBonuses = <int, int>{
    1: 30, 3: 60, 7: 120, 14: 250, 30: 500, 60: 900, 100: 1500,
  };

  /// Вехи, которые уже можно забрать, но ещё не забрали.
  List<int> pendingAgeBonuses([int? nowMs]) {
    final int days = ageDays(nowMs);
    return ageBonuses.keys
        .where((int d) => d <= days && !claimedAges.contains(d))
        .toList()
      ..sort();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type.name,
        'bornAt': bornAt,
        'growthMinutes': growthMinutes,
        'xp': xp,
        'frame': frame,
        'fromSeed': fromSeed,
        'hat': hat,
        'neck': neck,
        'face': face,
        'skin': skin,
        'claimedAges': claimedAges,
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
        fromSeed: json['fromSeed'] as bool? ?? false,
      )
        ..xp = (json['xp'] as num?)?.toInt() ?? 0
        ..frame = json['frame'] as String? ?? 'none'
        ..hat = json['hat'] as String? ?? 'none'
        ..neck = json['neck'] as String? ?? 'none'
        ..face = json['face'] as String? ?? 'none'
        ..skin = json['skin'] as String? ?? 'classic'
        ..claimedAges = ((json['claimedAges'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<num>()
            .map((num e) => e.toInt())
            .toList();
}
