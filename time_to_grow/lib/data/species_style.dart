import 'package:flutter/material.dart';

import '../models/pet.dart';

/// Единая таблица внешности видов «Ростка» (v1.5.0+).
/// Данные используются процедурной отрисовкой: главный экран (PetCanvas),
/// мини-игра кормления и карточки выбора. Меняя таблицу, меняем всех.
///
/// v2.0.0: звери выглядят как настоящие — профильный силуэт, один глаз,
/// видовы морды (лисья, кошачья, оленья), лапы с коленом, повадки.
class SpeciesStyle {
  const SpeciesStyle({
    required this.body,
    this.belly,
    this.ear = 'none',
    this.tail = 'none',
    this.muzzle = 'smile',
    this.extra = 'none',
    this.whiteBelly = false,
    this.build = 'quad',
    this.neck = 0.30,
    this.headScale = 1.0,
    this.bodyLen = 1.0,
    this.legLen = 1.0,
  });

  /// Основной цвет тела.
  final Color body;

  /// Цвет животика; null — смесь body с белым.
  final Color? belly;

  /// Уши: none|triangle|round|long|tuft|horns|pom|leaf|crest|antler.
  final String ear;

  /// Хвост: none|bushy|thin|curl|puff|fin.
  final String tail;

  /// Морда: smile|beak|duckBeak|bearMuzzle|buckteeth|whaleMouth|topEyes|
  /// snout|foxMuzzle|catMuzzle|longMuzzle.
  final String muzzle;

  /// Особые детали: none|spikes|patches|shell|wings|mask|horn|mane|
  /// cactusSpines|flowerHead|leafPair|petals|clover|spots|claws|tentacles.
  final String extra;

  /// Белый животик (пингвин, панда, единорог).
  final bool whiteBelly;

  /// Телосложение (v1.9.0):
  ///  quad — четыре лапы, горизонтальное тело, голова на шее;
  ///  bird — две лапы, вертикальное тело, голова сверху;
  ///  hop  — прыгает (зайчик, лягушонок);
  ///  pond — водный житель пруда.
  final String build;

  /// Длина шеи (доля высоты тела): олень/единорог — длинная.
  final double neck;

  /// Размер головы относительно базового.
  final double headScale;

  /// Множитель длины тела (медведь/свинья длиннее, кот короче).
  final double bodyLen;

  /// Множитель длины лап.
  final double legLen;
}

const Color kInk = Color(0xFF3A3A3A);
const Color kBeakOrange = Color(0xFFFF9500);
const Color kSpike = Color(0xFF8B5E34);
const Color kPot = Color(0xFFCB7B4E);
const Color kPotDark = Color(0xFFA85F38);
const Color kSoil = Color(0xFF7A4E2D);
const Color kStem = Color(0xFF5FA052);

const Map<PetType, SpeciesStyle> kSpeciesStyles = <PetType, SpeciesStyle>{
  // ── Звери: четвероногие ходоки ─────────────────────────────────────
  PetType.fox: SpeciesStyle(
      body: Color(0xFFFF9F45),
      ear: 'triangle',
      tail: 'bushy',
      muzzle: 'foxMuzzle',
      extra: 'spots'),
  PetType.cat: SpeciesStyle(
      body: Color(0xFFA8B8C8),
      ear: 'triangle',
      tail: 'thin',
      muzzle: 'catMuzzle',
      bodyLen: 0.92),
  PetType.dragon: SpeciesStyle(
      body: Color(0xFF62C46A),
      belly: Color(0xFFD9F2DC),
      ear: 'horns',
      extra: 'wings',
      neck: 0.42),
  PetType.bunny: SpeciesStyle(
      body: Color(0xFFD9CFC4),
      belly: Color(0xFFF7F1EA),
      ear: 'long',
      muzzle: 'buckteeth',
      build: 'hop',
      bodyLen: 0.88),
  PetType.hedgehog: SpeciesStyle(
      body: Color(0xFFC08552),
      belly: Color(0xFFF0DCBE),
      ear: 'round',
      muzzle: 'foxMuzzle',
      extra: 'spikes',
      bodyLen: 0.94),
  PetType.panda: SpeciesStyle(
      body: Color(0xFFF2EEE4),
      ear: 'pom',
      extra: 'patches',
      whiteBelly: true,
      bodyLen: 1.12,
      legLen: 0.86),
  PetType.bear: SpeciesStyle(
      body: Color(0xFFA9744F),
      ear: 'round',
      muzzle: 'bearMuzzle',
      bodyLen: 1.14,
      legLen: 0.9),
  PetType.dog: SpeciesStyle(
      body: Color(0xFFF2C078),
      belly: Color(0xFFFBE8C8),
      ear: 'triangle',
      tail: 'bushy',
      muzzle: 'bearMuzzle'),
  PetType.deer: SpeciesStyle(
      body: Color(0xFFD9A06C),
      belly: Color(0xFFF7E7D2),
      ear: 'round',
      extra: 'antler',
      muzzle: 'longMuzzle',
      neck: 0.72,
      legLen: 1.18),
  PetType.squirrel: SpeciesStyle(
      body: Color(0xFFC97B4A),
      belly: Color(0xFFF4E3D2),
      ear: 'tuft',
      tail: 'bushy',
      muzzle: 'foxMuzzle',
      bodyLen: 0.9),
  PetType.raccoon: SpeciesStyle(
      body: Color(0xFF9AA3AC),
      belly: Color(0xFFE5E9ED),
      ear: 'triangle',
      muzzle: 'foxMuzzle',
      extra: 'mask'),
  PetType.koala: SpeciesStyle(
      body: Color(0xFFB5C4CE),
      belly: Color(0xFFE9EFF3),
      ear: 'pom',
      muzzle: 'bearMuzzle',
      legLen: 0.8),
  PetType.pig: SpeciesStyle(
      body: Color(0xFFF5A8B8),
      belly: Color(0xFFFDE3E9),
      ear: 'triangle',
      tail: 'curl',
      muzzle: 'snout',
      bodyLen: 1.16,
      legLen: 0.78),
  PetType.unicorn: SpeciesStyle(
      body: Color(0xFFF3EAFB),
      ear: 'triangle',
      extra: 'mane',
      muzzle: 'longMuzzle',
      whiteBelly: true,
      neck: 0.72,
      legLen: 1.15),
  // ── Звери: птицы (две лапы) ────────────────────────────────────────
  PetType.owl: SpeciesStyle(
      body: Color(0xFFA97FE0),
      belly: Color(0xFFEFE3FB),
      ear: 'tuft',
      muzzle: 'beak',
      build: 'bird',
      headScale: 1.25),
  PetType.duck: SpeciesStyle(
      body: Color(0xFFFFD24C), ear: 'tuft', muzzle: 'duckBeak', build: 'bird'),
  PetType.chick: SpeciesStyle(
      body: Color(0xFFFFD94C),
      ear: 'tuft',
      muzzle: 'beak',
      build: 'bird',
      headScale: 1.3),
  PetType.penguin: SpeciesStyle(
      body: Color(0xFF56789A),
      ear: 'none',
      muzzle: 'beak',
      whiteBelly: true,
      build: 'bird',
      bodyLen: 0.82),
  // ── Прыгуны ────────────────────────────────────────────────────────
  PetType.frog: SpeciesStyle(
      body: Color(0xFF7CC46B),
      belly: Color(0xFFE2F4DC),
      ear: 'none',
      muzzle: 'topEyes',
      build: 'hop'),
  // ── Водные жители пруда ────────────────────────────────────────────
  PetType.seal: SpeciesStyle(
      body: Color(0xFFB8C9D9),
      belly: Color(0xFFE8EFF5),
      ear: 'none',
      muzzle: 'smile',
      build: 'pond'),
  PetType.whale: SpeciesStyle(
      body: Color(0xFF5FA8D3),
      belly: Color(0xFFDCEFF9),
      ear: 'none',
      muzzle: 'whaleMouth',
      build: 'pond'),
  PetType.turtle: SpeciesStyle(
      body: Color(0xFF8FBF6A),
      belly: Color(0xFFE5F0D5),
      ear: 'none',
      extra: 'shell',
      build: 'pond'),
  PetType.octopus: SpeciesStyle(
      body: Color(0xFFD98AC2),
      belly: Color(0xFFF7E4F0),
      ear: 'none',
      extra: 'tentacles',
      build: 'pond'),
  PetType.crab: SpeciesStyle(
      body: Color(0xFFE86A5C),
      belly: Color(0xFFF9DAD5),
      ear: 'none',
      extra: 'claws',
      build: 'pond'),
  // ── Растения в горшочках ───────────────────────────────────────────
  PetType.cactus: SpeciesStyle(
      body: Color(0xFF5FA052), extra: 'cactusSpines', build: 'plant'),
  PetType.bonsai: SpeciesStyle(
      body: Color(0xFF6FBF4E), belly: kPot, build: 'plant'),
  PetType.succulent: SpeciesStyle(
      body: Color(0xFF9BC98F), belly: kPot, build: 'plant'),
  PetType.sunflower: SpeciesStyle(
      body: Color(0xFFFFC800), belly: kPot, build: 'plant'),
  PetType.clover: SpeciesStyle(
      body: Color(0xFF5FA052), belly: kPot, build: 'plant'),
  PetType.sprout: SpeciesStyle(
      body: Color(0xFF7FC45C), belly: kPot, build: 'plant'),
};

/// Растения рисуются в горшочке, а не с лапами.
bool isPlant(PetType t) => kPlantPets.contains(t);

/// Водные жители — живут в пруду по центру сцены (v1.8.0).
bool isAquatic(PetType t) => kAquaticPets.contains(t);

Color speciesBody(PetType t) =>
    kSpeciesStyles[t]?.body ?? const Color(0xFF9BC98F);

Color speciesBelly(PetType t) {
  final SpeciesStyle? s = kSpeciesStyles[t];
  if (s == null) return const Color(0xFFE5F0D5);
  if (s.belly != null) return s.belly!;
  final Color c = s.body;
  return Color.alphaBlend(c.withOpacity(0.35), Colors.white);
}

/// Окрас-скин из гардероба (v1.9.0): подкрашиваем основной цвет.
Color skinnedBody(Color base, String skin) {
  switch (skin) {
    case 'golden':
      return Color.alphaBlend(const Color(0xFFFFC800).withOpacity(0.55), base);
    case 'mint':
      return Color.alphaBlend(const Color(0xFF62D9B8).withOpacity(0.55), base);
    case 'rose':
      return Color.alphaBlend(const Color(0xFFFF8FB1).withOpacity(0.55), base);
    default:
      return base;
  }
}

/// Тёмная версия окраса (лапки, тени на теле).
Color skinnedShade(Color base, String skin) {
  final Color b = skinnedBody(base, skin);
  return Color.alphaBlend(b.withOpacity(0.78), Colors.black12);
}
