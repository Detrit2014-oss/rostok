import '../models/pet.dart';

/// Спрайтовая система «Ростка» v2.1.0 «Настоящие звери».
///
/// Вместо процедурных фигур каждый вид — реалистичная иллюстрация
/// (assets/sprites/<вид>.webp), сгенерированная в едином стиле: профиль
/// вправо, естественные пропорции и окрас. Поза сна — отдельный спрайт
/// <вид>_sleep.webp (звери спят, как настоящие: свернувшись, спрятав
/// клюв и т.д.). Яйцо остаётся процедурным.
///
/// Файл также содержит константы сцены, одинаковые для Flutter и веб-демо:
/// размеры видов, полосы глубины на лужайке, якоря аксессуаров.
class SpriteMeta {
  const SpriteMeta({
    required this.heightF,
    this.sleep = true,
  });

  /// Высота взрослого питомца как доля высоты сцены.
  /// Ширина берётся из пропорций самого спрайта.
  final double heightF;

  /// Есть ли отдельный спрайт сна (у растений нет).
  final bool sleep;
}

const Map<PetType, SpriteMeta> kSpriteMeta = <PetType, SpriteMeta>{
  // ── Звери: четвероногие ходоки ─────────────────────────────────────
  PetType.fox: SpriteMeta(heightF: 0.165),
  PetType.cat: SpriteMeta(heightF: 0.150),
  PetType.dragon: SpriteMeta(heightF: 0.190),
  PetType.bunny: SpriteMeta(heightF: 0.150),
  PetType.hedgehog: SpriteMeta(heightF: 0.125),
  PetType.panda: SpriteMeta(heightF: 0.180),
  PetType.bear: SpriteMeta(heightF: 0.185),
  PetType.dog: SpriteMeta(heightF: 0.170),
  PetType.deer: SpriteMeta(heightF: 0.215),
  PetType.squirrel: SpriteMeta(heightF: 0.150),
  PetType.raccoon: SpriteMeta(heightF: 0.155),
  PetType.koala: SpriteMeta(heightF: 0.155),
  PetType.pig: SpriteMeta(heightF: 0.160),
  PetType.unicorn: SpriteMeta(heightF: 0.215),
  // ── Птицы ──────────────────────────────────────────────────────────
  PetType.owl: SpriteMeta(heightF: 0.165),
  PetType.duck: SpriteMeta(heightF: 0.130),
  PetType.chick: SpriteMeta(heightF: 0.105),
  PetType.penguin: SpriteMeta(heightF: 0.155),
  // ── Прыгуны ────────────────────────────────────────────────────────
  PetType.frog: SpriteMeta(heightF: 0.095),
  // ── Водные жители пруда ────────────────────────────────────────────
  PetType.seal: SpriteMeta(heightF: 0.115),
  PetType.whale: SpriteMeta(heightF: 0.125),
  PetType.turtle: SpriteMeta(heightF: 0.085),
  PetType.octopus: SpriteMeta(heightF: 0.130),
  PetType.crab: SpriteMeta(heightF: 0.075),
  // ── Растения (спят «как есть», без отдельной позы) ─────────────────
  PetType.cactus: SpriteMeta(heightF: 0.155, sleep: false),
  PetType.bonsai: SpriteMeta(heightF: 0.200, sleep: false),
  PetType.succulent: SpriteMeta(heightF: 0.115, sleep: false),
  PetType.sunflower: SpriteMeta(heightF: 0.205, sleep: false),
  PetType.clover: SpriteMeta(heightF: 0.115, sleep: false),
  PetType.sprout: SpriteMeta(heightF: 0.120, sleep: false),
};

/// Путь к спрайту вида (sleep — поза сна).
String spriteAsset(PetType type, {bool sleep = false}) {
  final SpriteMeta m = kSpriteMeta[type] ??
      const SpriteMeta(heightF: 0.16);
  final bool useSleep = sleep && m.sleep;
  return 'assets/sprites/${type.name}${useSleep ? '_sleep' : ''}.webp';
}

/// Стадии меняют только размер: малыш 55%, подросток 78%, взрослый 100%.
double spriteStageScale(int stage) =>
    const <double>[0.55, 0.78, 1.0, 1.0][stage.clamp(0, 3)];

/// Прыгуны: во время прогулки перескакивают, а не идут.
const Set<PetType> kHopPets = <PetType>{PetType.bunny, PetType.frog};

/// ── Геометрия сцены (общая с веб-демо) ─────────────────────────────────
abstract final class SceneGeom {
  /// Край лужайки.
  static const double groundYF = 0.74;

  /// Пруд (если есть водные питомцы): центр и радиусы.
  static const double pondCXF = 0.62;
  static const double pondCYF = 0.765;
  static const double pondRWF = 0.21;
  static const double pondRHF = 0.058;

  /// Грядка растений: слева сзади.
  static const double bedX0F = 0.045;
  static const double bedX1F = 0.335;
  static const double bedYF = 0.845; // базовая линия растений

  /// Полосы прогулки зверей (глубина): y-линия и масштаб.
  /// Все полосы НИЖЕ пруда — звери проходят перед ним, а не по воде.
  static List<double> laneYs(int n) {
    if (n <= 1) return const <double>[0.935];
    return List<double>.generate(
        n, (int i) => 0.915 + 0.0675 * i / (n - 1));
  }

  static List<double> laneScales(int n) {
    if (n <= 1) return const <double>[1.05];
    return List<double>.generate(
        n, (int i) => 0.9 + 0.2 * i / (n - 1));
  }
}

/// ── Якоря аксессуаров (в долях прямоугольника спрайта) ─────────────────
/// Спрайт смотрит вправо: x растёт вперёд (к морде), y — вниз от верха.
/// Кепки/цветочки сидят на голове, шарф/бантик/бандана/колокольчик — на шее,
/// очки — на глазу. Значения подобраны для классов тел.
class Anchors {
  const Anchors(this.hat, this.neck, this.eye, this.mouth);

  /// (dx, dy) точки макушки.
  final (double, double) hat;

  /// (dx, dy) точки шеи/воротника.
  final (double, double) neck;

  /// (dx, dy) точки глаза.
  final (double, double) eye;

  /// (dx, dy) точки рта/клюва (у растений — бутона).
  final (double, double) mouth;

  static const Anchors quad = Anchors(
    (0.665, 0.085),
    (0.585, 0.360),
    (0.705, 0.215),
    (0.880, 0.330),
  );
  static const Anchors bird = Anchors(
    (0.510, 0.075),
    (0.455, 0.420),
    (0.575, 0.240),
    (0.760, 0.290),
  );
  static const Anchors hop = Anchors(
    (0.660, 0.090),
    (0.570, 0.400),
    (0.710, 0.240),
    (0.860, 0.360),
  );
  static const Anchors pond = Anchors(
    (0.480, 0.090),
    (0.420, 0.420),
    (0.560, 0.260),
    (0.830, 0.520),
  );
  static const Anchors plant = Anchors(
    (0.500, 0.060),
    (0.500, 0.340),
    (0.560, 0.220),
    (0.500, 0.100),
  );
}

Anchors anchorsFor(PetType type) {
  if (kPlantPets.contains(type)) return Anchors.plant;
  if (kAquaticPets.contains(type)) return Anchors.pond;
  if (kHopPets.contains(type)) return Anchors.hop;
  final String build = _birdLike.contains(type) ? 'bird' : 'quad';
  return build == 'bird' ? Anchors.bird : Anchors.quad;
}

const Set<PetType> _birdLike = <PetType>{
  PetType.owl, PetType.duck, PetType.chick, PetType.penguin,
};

/// Место выдоха-фонтанчика у кита (доля спрайта).
const (double, double) kWhaleBlow = (0.38, 0.06);
