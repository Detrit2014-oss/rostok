import 'package:flutter/material.dart';

import '../models/pet.dart';

/// Единая таблица внешности видов «Росток» (v1.5.0+).
/// Данные используются процедурной отрисовкой: главный экран (PetCanvas),
/// мини-игра кормления и карточки выбора. Меняя таблицу, меняем всех.
class SpeciesStyle {
  const SpeciesStyle({
    required this.body,
    this.belly,
    this.ear = 'none',
    this.tail = 'none',
    this.muzzle = 'smile',
    this.extra = 'none',
    this.whiteBelly = false,
  });

  /// Основной цвет тела.
  final Color body;

  /// Цвет животика; null — смесь body с белым.
  final Color? belly;

  /// Уши: none|triangle|round|long|tuft|horns|pom|leaf|crest|antler.
  final String ear;

  /// Хвост: none|bushy|thin|curl|puff|fin.
  final String tail;

  /// Морда: smile|beak|duckBeak|bearMuzzle|buckteeth|whaleMouth|topEyes|snout.
  final String muzzle;

  /// Особые детали: none|spikes|patches|shell|wings|mask|horn|mane|
  /// cactusSpines|flowerHead|leafPair|petals|clover|spots|claws|tentacles.
  final String extra;

  /// Белый животик (пингвин, панда, единорог).
  final bool whiteBelly;
}

const Color kInk = Color(0xFF3A3A3A);
const Color kBeakOrange = Color(0xFFFF9500);
const Color kSpike = Color(0xFF8B5E34);
const Color kPot = Color(0xFFCB7B4E);
const Color kPotDark = Color(0xFFA85F38);
const Color kSoil = Color(0xFF7A4E2D);
const Color kStem = Color(0xFF5FA052);

const Map<PetType, SpeciesStyle> kSpeciesStyles = <PetType, SpeciesStyle>{
  // ── Звери ──────────────────────────────────────────────────────────
  PetType.fox: SpeciesStyle(
      body: Color(0xFFFF9F45),
      ear: 'triangle',
      tail: 'bushy',
      muzzle: 'smile',
      extra: 'spots'),
  PetType.cat: SpeciesStyle(
      body: Color(0xFFA8B8C8), ear: 'triangle', tail: 'thin'),
  PetType.owl: SpeciesStyle(
      body: Color(0xFFA97FE0),
      belly: Color(0xFFEFE3FB),
      ear: 'tuft',
      muzzle: 'beak'),
  PetType.dragon: SpeciesStyle(
      body: Color(0xFF62C46A),
      belly: Color(0xFFD9F2DC),
      ear: 'horns',
      extra: 'wings'),
  PetType.duck: SpeciesStyle(
      body: Color(0xFFFFD24C), ear: 'tuft', muzzle: 'duckBeak'),
  PetType.bunny: SpeciesStyle(
      body: Color(0xFFD9CFC4),
      belly: Color(0xFFF7F1EA),
      ear: 'long',
      muzzle: 'buckteeth'),
  PetType.penguin: SpeciesStyle(
      body: Color(0xFF56789A),
      ear: 'none',
      muzzle: 'beak',
      whiteBelly: true),
  PetType.hedgehog: SpeciesStyle(
      body: Color(0xFFC08552),
      belly: Color(0xFFF0DCBE),
      ear: 'round',
      extra: 'spikes'),
  PetType.panda: SpeciesStyle(
      body: Color(0xFFF2EEE4),
      ear: 'pom',
      extra: 'patches',
      whiteBelly: true),
  PetType.bear: SpeciesStyle(
      body: Color(0xFFA9744F),
      ear: 'round',
      muzzle: 'bearMuzzle'),
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
      muzzle: 'smile'),
  PetType.seal: SpeciesStyle(
      body: Color(0xFFB8C9D9),
      belly: Color(0xFFE8EFF5),
      ear: 'none',
      muzzle: 'smile'),
  PetType.whale: SpeciesStyle(
      body: Color(0xFF5FA8D3),
      belly: Color(0xFFDCEFF9),
      ear: 'none',
      muzzle: 'whaleMouth'),
  PetType.turtle: SpeciesStyle(
      body: Color(0xFF8FBF6A),
      belly: Color(0xFFE5F0D5),
      ear: 'none',
      extra: 'shell'),
  PetType.frog: SpeciesStyle(
      body: Color(0xFF7CC46B),
      belly: Color(0xFFE2F4DC),
      ear: 'none',
      muzzle: 'topEyes'),
  PetType.squirrel: SpeciesStyle(
      body: Color(0xFFC97B4A),
      belly: Color(0xFFF4E3D2),
      ear: 'tuft',
      tail: 'bushy'),
  PetType.raccoon: SpeciesStyle(
      body: Color(0xFF9AA3AC),
      belly: Color(0xFFE5E9ED),
      ear: 'triangle',
      extra: 'mask'),
  PetType.koala: SpeciesStyle(
      body: Color(0xFFB5C4CE),
      belly: Color(0xFFE9EFF3),
      ear: 'pom',
      muzzle: 'bearMuzzle'),
  PetType.pig: SpeciesStyle(
      body: Color(0xFFF5A8B8),
      belly: Color(0xFFFDE3E9),
      ear: 'triangle',
      tail: 'curl',
      muzzle: 'snout'),
  PetType.chick: SpeciesStyle(
      body: Color(0xFFFFD94C),
      ear: 'tuft',
      muzzle: 'beak'),
  PetType.unicorn: SpeciesStyle(
      body: Color(0xFFF3EAFB),
      ear: 'triangle',
      extra: 'mane',
      whiteBelly: true),
  PetType.octopus: SpeciesStyle(
      body: Color(0xFFD98AC2),
      belly: Color(0xFFF7E4F0),
      ear: 'none',
      extra: 'tentacles'),
  PetType.crab: SpeciesStyle(
      body: Color(0xFFE86A5C),
      belly: Color(0xFFF9DAD5),
      ear: 'none',
      extra: 'claws'),
  // ── Растения ───────────────────────────────────────────────────────
  PetType.cactus: SpeciesStyle(
      body: Color(0xFF5FA052), extra: 'cactusSpines'),
  PetType.bonsai: SpeciesStyle(body: Color(0xFF6FBF4E), belly: kPot),
  PetType.succulent: SpeciesStyle(body: Color(0xFF9BC98F), belly: kPot),
  PetType.sunflower: SpeciesStyle(body: Color(0xFFFFC800), belly: kPot),
  PetType.clover: SpeciesStyle(body: Color(0xFF5FA052), belly: kPot),
  PetType.sprout: SpeciesStyle(body: Color(0xFF7FC45C), belly: kPot),
};

/// Растения рисуются в горшочке, а не с лапами.
bool isPlant(PetType t) =>
    t == PetType.cactus ||
    t == PetType.bonsai ||
    t == PetType.succulent ||
    t == PetType.sunflower ||
    t == PetType.clover ||
    t == PetType.sprout;

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
