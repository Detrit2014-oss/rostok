import 'dart:ui';

import '../models/pet.dart';

/// Мультяшный движок «Ростка» v2.2.0 «Мультяшные звери».
///
/// Все 30 видов нарисованы кодом в едином мультяшном стиле: плотный
/// контур тёплого тёмного оттенка, плоские сочные заливки, округлые
/// формы, большие глаза с бликом. Каждый вид описан спекой ниже —
/// одинаковые числа использует веб-демо (src/lib/ttg/cartoon.ts),
/// поэтому сцены совпадают 1:1.
///
/// Сборки (build):
///   quad  — четвероногие (лиса, кот, медведь, олень…) с походкой;
///   bird  — птицы (сова, утка, цыплёнок, пингвин), вперевалку;
///   hop   — прыгуны (зайчик, лягушонок);
///   pond  — водные жители пруда;
///   plant — растения на грядке (качаются, но не ходят).
class CartoonSpec {
  const CartoonSpec({
    required this.build,
    required this.heightF,
    required this.aspect,
    required this.body,
    required this.belly,
    this.accent,
    this.dark,
    this.ear = 'none',
    this.tail = 'none',
    this.muzzle = 'none',
    this.extras = const <String>{},
  });

  /// quad | bird | hop | pond | plant.
  final String build;

  /// Высота взрослого питомца как доля высоты сцены.
  final double heightF;

  /// Отношение ширины к высоте (для бокса отрисовки).
  final double aspect;

  /// Основной цвет тела.
  final Color body;

  /// Животик / мордочка / светлые пятна.
  final Color belly;

  /// Акцент: внутреннее ухо, клюв, нос, цветок, грива.
  final Color? accent;

  /// Тёмные зоны (маска енота, лапы панды, плавники). null — производная body.
  final Color? dark;

  /// Уши: pointy острые | round круглые | floppy висячие | long длинные |
  /// tuft хохолок | tufts совиные | stalk стебельки (краб).
  final String ear;

  /// Хвост: bushy пушистый | cat изгиб | puff помпон | long прямой |
  /// flat утиный | curl свиной | plume веер | fluke китовый | none.
  final String tail;

  /// Морда: fox клин | cat кошачья | bear округлая | long вытянутая |
  /// snout пятачок | beak клюв | flat широкая.
  final String muzzle;

  /// Доп. детали: antlers рога | horn рог | mane грива | spikes шипы на спине |
  /// wings крылья | shell панцирь | mask маска | spots пятна | stripes полосы |
  /// fin плавник | suckers присоски | claws клешни | paddles ласты |
  /// flower цветок | arms ручки кактуса.
  final Set<String> extras;
}

const Color kInkCartoon = Color(0xFF46362A); // тёплый тёмный контур

/// Обводка = тело, затемнённое на 45% (мягкий мультяшный контур).
Color cartoonInk(Color body) => Color.lerp(body, kInkCartoon, 0.45)!;

/// Затемнение для дальних лап/теней внутри силуэта.
Color cartoonShade(Color body) => Color.lerp(body, kInkCartoon, 0.28)!;

const Map<PetType, CartoonSpec> kCartoon = <PetType, CartoonSpec>{
  // ── Звери: четвероногие ходоки ─────────────────────────────
  PetType.fox: CartoonSpec(
    build: 'quad', heightF: 0.165, aspect: 1.12,
    body: Color(0xFFFF9F45), belly: Color(0xFFFFF3E2), accent: Color(0xFFE07B2A),
    ear: 'pointy', tail: 'bushy', muzzle: 'fox',
  ),
  PetType.cat: CartoonSpec(
    build: 'quad', heightF: 0.150, aspect: 1.12,
    body: Color(0xFFA8B8C8), belly: Color(0xFFE8EEF4), accent: Color(0xFFFFB8C9),
    ear: 'pointy', tail: 'cat', muzzle: 'cat',
  ),
  PetType.dog: CartoonSpec(
    build: 'quad', heightF: 0.170, aspect: 1.15,
    body: Color(0xFFF2C078), belly: Color(0xFFFBE8C8), accent: Color(0xFFC98850),
    ear: 'floppy', tail: 'long', muzzle: 'bear',
  ),
  PetType.bear: CartoonSpec(
    build: 'quad', heightF: 0.185, aspect: 1.1,
    body: Color(0xFFA9744F), belly: Color(0xFFE8C9A8),
    ear: 'round', tail: 'puff', muzzle: 'bear',
  ),
  PetType.panda: CartoonSpec(
    build: 'quad', heightF: 0.180, aspect: 1.1,
    body: Color(0xFFF7F4EC), belly: Color(0xFFFCFAF4), dark: Color(0xFF3B3B44),
    ear: 'round', tail: 'puff', muzzle: 'bear',
    extras: <String>{'mask'},
  ),
  PetType.raccoon: CartoonSpec(
    build: 'quad', heightF: 0.155, aspect: 1.2,
    body: Color(0xFF9AA3AC), belly: Color(0xFFE5E9ED), dark: Color(0xFF4E5560),
    ear: 'pointy', tail: 'bushy', muzzle: 'fox',
    extras: <String>{'mask', 'rings'},
  ),
  PetType.hedgehog: CartoonSpec(
    build: 'quad', heightF: 0.125, aspect: 1.25,
    body: Color(0xFFC08552), belly: Color(0xFFF0DCBE), dark: Color(0xFF8A6642),
    ear: 'pointy', tail: 'puff', muzzle: 'fox',
    extras: <String>{'spikesBack'},
  ),
  PetType.squirrel: CartoonSpec(
    build: 'quad', heightF: 0.150, aspect: 1.2,
    body: Color(0xFFC97B4A), belly: Color(0xFFF4E3D2), accent: Color(0xFFA85E34),
    ear: 'tufts', tail: 'bushy', muzzle: 'fox',
  ),
  PetType.pig: CartoonSpec(
    build: 'quad', heightF: 0.160, aspect: 1.15,
    body: Color(0xFFF5A8B8), belly: Color(0xFFFDE3E9), accent: Color(0xFFE98CA1),
    ear: 'floppy', tail: 'curl', muzzle: 'snout',
  ),
  PetType.koala: CartoonSpec(
    build: 'quad', heightF: 0.155, aspect: 1.05,
    body: Color(0xFFB5C4CE), belly: Color(0xFFE9EFF3), accent: Color(0xFFF7F1EA),
    ear: 'round', tail: 'none', muzzle: 'flat',
  ),
  PetType.deer: CartoonSpec(
    build: 'quad', heightF: 0.215, aspect: 1.2,
    body: Color(0xFFD9A06C), belly: Color(0xFFF7E7D2), accent: Color(0xFFA87A4F),
    ear: 'long', tail: 'puff', muzzle: 'long',
    extras: <String>{'antlers', 'spots'},
  ),
  PetType.unicorn: CartoonSpec(
    build: 'quad', heightF: 0.215, aspect: 1.2,
    body: Color(0xFFF3EAFB), belly: Color(0xFFFCF7FE), accent: Color(0xFFFF9FCE),
    ear: 'long', tail: 'mane', muzzle: 'long',
    extras: <String>{'horn', 'mane'},
  ),
  PetType.dragon: CartoonSpec(
    build: 'quad', heightF: 0.190, aspect: 1.4,
    body: Color(0xFF62C46A), belly: Color(0xFFD9F2DC), accent: Color(0xFF4CA95A),
    ear: 'pointy', tail: 'long', muzzle: 'cat',
    extras: <String>{'wings', 'spikesBack'},
  ),
  // ── Птицы ──────────────────────────────────────────────
  PetType.owl: CartoonSpec(
    build: 'bird', heightF: 0.165, aspect: 0.65,
    body: Color(0xFFA97FE0), belly: Color(0xFFEFE3FB), accent: Color(0xFFFFB84C),
    ear: 'tufts', tail: 'plume', muzzle: 'beak',
  ),
  PetType.duck: CartoonSpec(
    build: 'bird', heightF: 0.130, aspect: 0.65,
    body: Color(0xFFFFD24C), belly: Color(0xFFFFE9A0), accent: Color(0xFFFF9F45),
    ear: 'none', tail: 'flat', muzzle: 'beak',
  ),
  PetType.chick: CartoonSpec(
    build: 'bird', heightF: 0.105, aspect: 0.6,
    body: Color(0xFFFFD94C), belly: Color(0xFFFFE9A0), accent: Color(0xFFFF9F45),
    ear: 'tuft', tail: 'none', muzzle: 'beak',
  ),
  PetType.penguin: CartoonSpec(
    build: 'bird', heightF: 0.155, aspect: 0.65,
    body: Color(0xFF56789A), belly: Color(0xFFF4F8FB), accent: Color(0xFFFFB84C),
    ear: 'none', tail: 'none', muzzle: 'beak',
  ),
  // ── Прыгуны ────────────────────────────────────────────
  PetType.bunny: CartoonSpec(
    build: 'hop', heightF: 0.150, aspect: 0.78,
    body: Color(0xFFD9CFC4), belly: Color(0xFFF7F1EA), accent: Color(0xFFFFB8C9),
    ear: 'long', tail: 'puff', muzzle: 'flat',
  ),
  PetType.frog: CartoonSpec(
    build: 'hop', heightF: 0.095, aspect: 1.43,
    body: Color(0xFF7CC46B), belly: Color(0xFFE2F4DC), accent: Color(0xFFFF8FB1),
    ear: 'none', tail: 'none', muzzle: 'wide',
  ),
  // ── Водные жители пруда ────────────────────────────────
  PetType.whale: CartoonSpec(
    build: 'pond', heightF: 0.125, aspect: 2.8,
    body: Color(0xFF5FA8D3), belly: Color(0xFFDCEFF9), accent: Color(0xFF4A8FB8),
    ear: 'none', tail: 'fluke', muzzle: 'flat',
    extras: <String>{'fin'},
  ),
  PetType.seal: CartoonSpec(
    build: 'pond', heightF: 0.115, aspect: 2.4,
    body: Color(0xFFB8C9D9), belly: Color(0xFFE8EFF5), accent: Color(0xFF8FA8BD),
    ear: 'none', tail: 'fluke', muzzle: 'flat',
    extras: <String>{'paddles'},
  ),
  PetType.turtle: CartoonSpec(
    build: 'pond', heightF: 0.085, aspect: 2.2,
    body: Color(0xFF8FBF6A), belly: Color(0xFFE5F0D5), dark: Color(0xFF5C9245),
    ear: 'none', tail: 'puff', muzzle: 'flat',
    extras: <String>{'shell'},
  ),
  PetType.octopus: CartoonSpec(
    build: 'pond', heightF: 0.130, aspect: 1.35,
    body: Color(0xFFD98AC2), belly: Color(0xFFF7E4F0), accent: Color(0xFFC06BA6),
    ear: 'none', tail: 'none', muzzle: 'flat',
    extras: <String>{'suckers'},
  ),
  PetType.crab: CartoonSpec(
    build: 'pond', heightF: 0.075, aspect: 1.75,
    body: Color(0xFFE86A5C), belly: Color(0xFFF9DAD5), accent: Color(0xFFC94F43),
    ear: 'stalk', tail: 'none', muzzle: 'flat',
    extras: <String>{'claws'},
  ),
  // ── Растения на грядке ────────────────────────────────
  PetType.cactus: CartoonSpec(
    build: 'plant', heightF: 0.155, aspect: 0.55,
    body: Color(0xFF5FA052), belly: Color(0xFF7FB86E), accent: Color(0xFFFF8FB1),
    extras: <String>{'flower', 'arms'},
  ),
  PetType.bonsai: CartoonSpec(
    build: 'plant', heightF: 0.200, aspect: 0.9,
    body: Color(0xFF6FBF4E), belly: Color(0xFF8FCF6A), accent: Color(0xFF8A6642),
  ),
  PetType.succulent: CartoonSpec(
    build: 'plant', heightF: 0.115, aspect: 0.6,
    body: Color(0xFF9BC98F), belly: Color(0xFFB5D9A8), accent: Color(0xFFE8A8C8),
  ),
  PetType.sunflower: CartoonSpec(
    build: 'plant', heightF: 0.205, aspect: 0.57,
    body: Color(0xFFFFC800), belly: Color(0xFF8A5A32), accent: Color(0xFF5FA052),
  ),
  PetType.clover: CartoonSpec(
    build: 'plant', heightF: 0.115, aspect: 0.74,
    body: Color(0xFF5FA052), belly: Color(0xFF7FC45C), accent: Color(0xFFF7F1EA),
  ),
  PetType.sprout: CartoonSpec(
    build: 'plant', heightF: 0.120, aspect: 0.53,
    body: Color(0xFF7FC45C), belly: Color(0xFF9BD878), accent: Color(0xFF5FA052),
  ),
};

CartoonSpec cartoonSpec(PetType type) =>
    kCartoon[type] ??
    const CartoonSpec(
      build: 'quad', heightF: 0.16, aspect: 1.4,
      body: Color(0xFF9BC98F), belly: Color(0xFFE5F0D5),
    );

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

/// Стадии меняют только размер: малыш 55%, подросток 78%, взрослый 100%.
double cartoonStageScale(int stage) =>
    const <double>[0.55, 0.78, 1.0, 1.0][stage.clamp(0, 3)];

/// Ширина бокса вида при заданной высоте.
double cartoonWidth(PetType type, double h) => h * cartoonSpec(type).aspect;

/// ── Якорь рта (мини-игра «Покорми питомца») ────────────────────────────
/// Локальные координаты: x — от центра бокса (вперёд, к морде),
/// y — от земли (вверх = отрицательный), в долях высоты h.
/// Числа совпадают с геометрией cartoon_pet.dart и его TS-портом.
Offset cartoonMouthLocal(PetType type, double h) {
  final CartoonSpec s = cartoonSpec(type);
  switch (s.build) {
    case 'bird':
      return Offset(h * 0.18, -h * 0.66);
    case 'hop':
      if (type == PetType.frog) return Offset(h * 0.45, -h * 0.43);
      return Offset(h * 0.32, -h * 0.63);
    case 'pond':
      switch (type) {
        case PetType.whale:
          return Offset(h * 1.0, -h * 0.5);
        case PetType.seal:
          return Offset(h * 1.05, -h * 0.48);
        case PetType.turtle:
          return Offset(h * 1.05, -h * 0.33);
        case PetType.octopus:
          return Offset(0, -h * 0.54);
        default:
          return Offset(0, -h * 0.4); // краб
      }
    case 'plant':
      return Offset(0, -h * 0.85);
    default: // quad
      return Offset(h * 0.5, -h * 0.66);
  }
}
