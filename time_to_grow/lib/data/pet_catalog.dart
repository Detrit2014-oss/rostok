import '../models/pet.dart';

/// Каталог видов питомцев: новые яйца выдаются по кругу,
/// чтобы коллекция была разнообразной.
class PetSpecies {
  const PetSpecies(this.name, this.type);
  final String name;
  final PetType type;
}

const List<PetSpecies> kPetCatalog = <PetSpecies>[
  PetSpecies('Лисёнок', PetType.fox),
  PetSpecies('Котик', PetType.cat),
  PetSpecies('Совёнок', PetType.owl),
  PetSpecies('Дракончик', PetType.dragon),
];
