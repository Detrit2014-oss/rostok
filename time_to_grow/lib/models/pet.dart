/// Тип питомца — влияет на внешность в процедурной отрисовке.
/// С v1.2.0 видов десять — все нарисованы кодом (CustomPaint).
enum PetType {
  fox,
  cat,
  owl,
  dragon,
  duck,
  bunny,
  penguin,
  hedgehog,
  panda,
  bear,
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
  });

  final String id;

  /// Имя можно менять (карандаш на карточке питомца).
  String name;
  final PetType type;
  final int bornAt;

  /// Минуты «вдали от телефона», накопленные питомцем.
  int growthMinutes;

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
      );
}
