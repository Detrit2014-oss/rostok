import '../models/pet.dart';

/// Каталог видов питомцев. С v1.1.0 вид выбирает сам пользователь
/// на большом экране выбора (появляется при первом запуске и когда
/// предыдущий питомец вырос) — вращение по кругу осталось только
/// как страховка для автоматических яиц.
class PetSpecies {
  const PetSpecies(
    this.name,
    this.type,
    this.emoji,
    this.description,
    this.accusative,
  );
  final String name;
  final PetType type;

  /// Эмодзи для карточек и списков.
  final String emoji;

  /// Короткий характер — подпись на карточке выбора.
  final String description;

  /// Имя в винительном падеже: «Встречаем «Котика»!».
  final String accusative;
}

const List<PetSpecies> kPetCatalog = <PetSpecies>[
  PetSpecies('Лисёнок', PetType.fox, '🦊',
      'Энергичный непоседа — любит быстрые прогулки', 'Лисёнка'),
  PetSpecies('Котик', PetType.cat, '🐱',
      'Спокойный и мягкий — ценит долгую тишину', 'Котика'),
  PetSpecies('Совёнок', PetType.owl, '🦉',
      'Мудрый хранитель тихих вечеров', 'Совёнка'),
  PetSpecies('Дракончик', PetType.dragon, '🐲',
      'Весёлый смельчак — растёт от каждой передышки', 'Дракончика'),
  PetSpecies('Утёнок', PetType.duck, '🦆',
      'Весёлый плескун — обожает тихие лужи и покой', 'Утёнка'),
  PetSpecies('Зайчик', PetType.bunny, '🐰',
      'Прыгучий сладкоежка — оживает на свежем воздухе', 'Зайчика'),
  PetSpecies('Пингвинёнок', PetType.penguin, '🐧',
      'Неуклюжий милаха — верный друг долгих пауз', 'Пингвинёнка'),
  PetSpecies('Ёжик', PetType.hedgehog, '🦔',
      'Колючий снаружи, добрый внутри — любит уединение', 'Ёжика'),
  PetSpecies('Панда', PetType.panda, '🐼',
      'Неторопливый философ — мастер спокойствия', 'Панду'),
  PetSpecies('Медвежонок', PetType.bear, '🐻',
      'Тёплый обнимашка — сладко спит, пока вы отдыхаете', 'Медвежонка'),
];

PetSpecies speciesOfType(PetType type) => kPetCatalog.firstWhere(
      (PetSpecies s) => s.type == type,
      orElse: () => kPetCatalog.first,
    );
