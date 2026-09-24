import 'package:flutter/material.dart';

import '../models/pet.dart';

/// Таблица фирменных цветов видов «Ростка».
/// С v2.1.0 внешность видов — реалистичные спрайты (см. sprite_meta.dart),
/// а отсюда берутся только акцентные цвета: точки на яйце, пятнышки
/// в интерфейсе, оттенки карточек.
class SpeciesStyle {
  const SpeciesStyle({required this.body, this.belly});

  /// Основной цвет тела.
  final Color body;

  /// Цвет животика; null — смесь body с белым.
  final Color? belly;
}

const Color kInk = Color(0xFF3A3A3A);
const Color kSoil = Color(0xFF7A4E2D);
const Color kStem = Color(0xFF5FA052);

const Map<PetType, SpeciesStyle> kSpeciesStyles = <PetType, SpeciesStyle>{
  // ── Звери: четвероногие ходоки ─────────────────────────────────────
  PetType.fox: SpeciesStyle(body: Color(0xFFFF9F45)),
  PetType.cat: SpeciesStyle(body: Color(0xFFA8B8C8)),
  PetType.dragon: SpeciesStyle(
      body: Color(0xFF62C46A), belly: Color(0xFFD9F2DC)),
  PetType.bunny: SpeciesStyle(
      body: Color(0xFFD9CFC4), belly: Color(0xFFF7F1EA)),
  PetType.hedgehog: SpeciesStyle(
      body: Color(0xFFC08552), belly: Color(0xFFF0DCBE)),
  PetType.panda: SpeciesStyle(body: Color(0xFFF2EEE4)),
  PetType.bear: SpeciesStyle(body: Color(0xFFA9744F)),
  PetType.dog: SpeciesStyle(
      body: Color(0xFFF2C078), belly: Color(0xFFFBE8C8)),
  PetType.deer: SpeciesStyle(
      body: Color(0xFFD9A06C), belly: Color(0xFFF7E7D2)),
  PetType.squirrel: SpeciesStyle(
      body: Color(0xFFC97B4A), belly: Color(0xFFF4E3D2)),
  PetType.raccoon: SpeciesStyle(
      body: Color(0xFF9AA3AC), belly: Color(0xFFE5E9ED)),
  PetType.koala: SpeciesStyle(
      body: Color(0xFFB5C4CE), belly: Color(0xFFE9EFF3)),
  PetType.pig: SpeciesStyle(
      body: Color(0xFFF5A8B8), belly: Color(0xFFFDE3E9)),
  PetType.unicorn: SpeciesStyle(body: Color(0xFFF3EAFB)),
  // ── Звери: птицы ───────────────────────────────────────────────────
  PetType.owl: SpeciesStyle(
      body: Color(0xFFA97FE0), belly: Color(0xFFEFE3FB)),
  PetType.duck: SpeciesStyle(body: Color(0xFFFFD24C)),
  PetType.chick: SpeciesStyle(body: Color(0xFFFFD94C)),
  PetType.penguin: SpeciesStyle(body: Color(0xFF56789A)),
  // ── Прыгуны ────────────────────────────────────────────────────────
  PetType.frog: SpeciesStyle(
      body: Color(0xFF7CC46B), belly: Color(0xFFE2F4DC)),
  // ── Водные жители пруда ────────────────────────────────────────────
  PetType.seal: SpeciesStyle(
      body: Color(0xFFB8C9D9), belly: Color(0xFFE8EFF5)),
  PetType.whale: SpeciesStyle(
      body: Color(0xFF5FA8D3), belly: Color(0xFFDCEFF9)),
  PetType.turtle: SpeciesStyle(
      body: Color(0xFF8FBF6A), belly: Color(0xFFE5F0D5)),
  PetType.octopus: SpeciesStyle(
      body: Color(0xFFD98AC2), belly: Color(0xFFF7E4F0)),
  PetType.crab: SpeciesStyle(
      body: Color(0xFFE86A5C), belly: Color(0xFFF9DAD5)),
  // ── Растения на грядке ─────────────────────────────────────────────
  PetType.cactus: SpeciesStyle(body: Color(0xFF5FA052)),
  PetType.bonsai: SpeciesStyle(body: Color(0xFF6FBF4E)),
  PetType.succulent: SpeciesStyle(body: Color(0xFF9BC98F)),
  PetType.sunflower: SpeciesStyle(body: Color(0xFFFFC800)),
  PetType.clover: SpeciesStyle(body: Color(0xFF5FA052)),
  PetType.sprout: SpeciesStyle(body: Color(0xFF7FC45C)),
};

/// Растения — комнатные питомцы на грядке (v1.9.0).
bool isPlant(PetType t) => kPlantPets.contains(t);

/// Водные жители — живут в пруду (v1.8.0, пруд справа с v2.1.0).
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
