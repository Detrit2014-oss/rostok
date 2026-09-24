import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/species_style.dart';
import '../data/sprite_meta.dart';
import '../models/pet.dart';
import 'sprite_cache.dart';

/// Анимированная сцена «Ростка» v2.1.0 «Настоящие звери».
///
/// Питомцы больше не рисуются фигурами вручную: каждый вид — реалистичная
/// иллюстрация-спрайт (assets/sprites/<вид>.webp) в едином стиле, а сцена
/// оживляет её повадками: зверь гуляет по лужайке, принюхивается, щиплет
/// траву, садится; птицы клюют зёрнышки; зайчик прыгает; водные жители
/// плавают в пруду; растения качаются на грядке. Спящие звери ЛЕЖАТ —
/// отдельная поза сна в том же стиле. Яйцо и семечко остались процедурными.
class PetCanvas extends StatefulWidget {
  const PetCanvas({
    super.key,
    required this.pets,
    this.sleeping = false,
    this.weather,
    this.frame = 'none',
  });

  final List<Pet> pets;

  /// true — идёт сессия детокса: питомцы спят в своих позах и «копят» рост.
  final bool sleeping;

  /// Погодное состояние сцены: null|partly|cloudy|fog|rain|snow|thunder.
  final String? weather;

  /// Декоративная рамка из магазина: none|gold|neon|flower.
  final String frame;

  @override
  State<PetCanvas> createState() => _PetCanvasState();
}

class _PetCanvasState extends State<PetCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();
  int _cycle = 0;

  @override
  void initState() {
    super.initState();
    _phase.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _cycle++;
    });
    _loadMissing();
  }

  @override
  void didUpdateWidget(PetCanvas old) {
    super.didUpdateWidget(old);
    _loadMissing();
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  /// Запрашивает недостающие спрайты: idle + поза сна для всех видов сцены.
  void _loadMissing() {
    for (final Pet pet in widget.pets) {
      final bool sleepPose = widget.sleeping && !isPlant(pet.type);
      if (pet.stage > 0) {
        SpriteCache.ensure(spriteAsset(pet.type, sleep: sleepPose),
            () => mounted ? setState(() {}) : null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phase,
      builder: (BuildContext context, Widget? _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _PetScenePainter(
            pets: widget.pets,
            phase: _phase.value,
            tSec: (_cycle + _phase.value) * 4.0,
            sleeping: widget.sleeping,
            weather: widget.weather,
            frame: widget.frame,
            images: SpriteCache.snapshot(),
          ),
        );
      },
    );
  }
}

/// ── Повадки настоящих зверей ────────────────────────────────────────────
/// Зверь гуляет по лужайке, а каждые ~21 с останавливается и ведёт себя
/// как живой: принюхивается, щиплет траву, сидит или клюёт зёрнышки.
/// Всё детерминировано (tSec + id питомца), поэтому Flutter и демо
/// рисуют одинаковые сцены.
class PetBehavior {
  const PetBehavior({
    required this.x,
    required this.facing,
    required this.kind,
    required this.headPitch,
    required this.stride,
    required this.poseEase,
  });

  /// Позиция на лужайке, 0..1.
  final double x;

  /// 1 — идёт вправо, -1 — влево.
  final double facing;

  /// walk | sniff | graze | sit | peck | look.
  final String kind;

  /// Наклон головы вниз, рад (0 — смотрит вперёд).
  final double headPitch;

  /// Фаза шага, рад — на паузе замирает вместе с лапами.
  final double stride;

  /// 0..1 — насколько зверь «вошёл» в позу (плавный вход/выход).
  final double poseEase;

  /// Амплитуда покачивания корпуса (на паузе зверь стоит смирно).
  double get bob => 1.0 - poseEase * 0.8;
}

const double _kStrollPeriod = 21.0; // цикл «прогулка + пауза», с
const double _kPauseAt = 13.5; // начало паузы внутри цикла
const double _kPauseLen = 3.8; // длительность паузы, с
const double _kCrossSec = 8.2; // полпути через лужайку, с

double _pbHash(int a, int b) {
  int h = (a * 374761393 + b * 668265263) & 0x7fffffff;
  h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff;
  return ((h ^ (h >> 16)) & 0x7fffffff) / 0x7fffffff;
}

bool _pbIsGrazer(PetType t) => const <PetType>{
      PetType.deer,
      PetType.unicorn,
      PetType.bunny,
      PetType.squirrel,
      PetType.pig,
      PetType.koala,
      PetType.panda,
      PetType.dragon,
      PetType.hedgehog,
    }.contains(t);

bool _pbIsPercher(PetType t) => const <PetType>{
      PetType.fox,
      PetType.cat,
      PetType.dog,
      PetType.raccoon,
      PetType.bear,
    }.contains(t);

bool _pbIsPecker(PetType t) => const <PetType>{
      PetType.owl,
      PetType.duck,
      PetType.chick,
      PetType.penguin,
    }.contains(t);

PetBehavior _petBehavior(Pet pet, int index, double tSec) {
  final int seed = pet.id.hashCode & 0x7fffffff;
  final double off = (seed % 1900) / 100.0; // 0..19 с — у каждого своё
  final double total = tSec + off;
  final double local = total % _kStrollPeriod;
  final int cycle = total ~/ _kStrollPeriod;

  // «Чистое» время шага: паузы не двигают зверя и не качают лапы.
  final double pauseDone = (total ~/ _kStrollPeriod) * _kPauseLen +
      (local >= _kPauseAt
          ? math.min(local - _kPauseAt, _kPauseLen)
          : 0.0);
  final double walkT = tSec - pauseDone;

  final double tri = ((walkT + off) / _kCrossSec) % 2.0;
  final double x = tri < 1.0 ? tri : 2.0 - tri;
  final double facing = tri < 1.0 ? 1.0 : -1.0;
  final double stride = (walkT + off) * 2 * math.pi / 0.8;

  if (local < _kPauseAt || local >= _kPauseAt + _kPauseLen) {
    return PetBehavior(
      x: x,
      facing: facing,
      kind: 'walk',
      headPitch: 0.05 + math.sin(stride * 2) * 0.03,
      stride: stride,
      poseEase: 0,
    );
  }

  // Пауза: выбор повадки стабилен на весь цикл.
  final double r = _pbHash(seed, cycle);
  final String kind;
  if (_pbIsPecker(pet.type)) {
    kind = r < 0.62 ? 'peck' : 'look';
  } else if (_pbIsPercher(pet.type)) {
    kind = r < 0.40 ? 'sniff' : (r < 0.78 ? 'sit' : 'look');
  } else if (_pbIsGrazer(pet.type)) {
    kind = r < 0.55 ? 'graze' : (r < 0.85 ? 'sniff' : 'look');
  } else {
    kind = r < 0.5 ? 'sniff' : 'look';
  }

  // Плавный вход в позу и выход из неё.
  final double tin = ((local - _kPauseAt) / 0.7).clamp(0.0, 1.0);
  final double tout =
      ((_kPauseAt + _kPauseLen - local) / 0.7).clamp(0.0, 1.0);
  final double e = math.min(tin, tout);
  final double ease = e * e * (3 - 2 * e); // smoothstep

  double target;
  switch (kind) {
    case 'graze':
      target = 1.0 + math.sin(tSec * 8.5) * 0.06; // щиплет траву
      break;
    case 'sniff':
      target = 0.62 + math.sin(tSec * 7.0) * 0.07; // принюхивается
      break;
    case 'peck':
      final double pp = ((local - _kPauseAt) / _kPauseLen * 3.0) % 1.0;
      target = math.sin(pp * math.pi) * 0.85; // три клюочка
      break;
    default:
      target = 0.10 + math.sin(tSec * 1.6) * 0.12; // осматривается
  }
  return PetBehavior(
    x: x,
    facing: facing,
    kind: kind,
    headPitch: target * ease,
    stride: stride,
    poseEase: ease,
  );
}

class _PetScenePainter extends CustomPainter {
  _PetScenePainter({
    required this.pets,
    required this.phase,
    required this.tSec,
    required this.sleeping,
    required this.weather,
    required this.frame,
    required this.images,
  });

  final List<Pet> pets;
  final double phase;

  /// Абсолютное время сцены, с — на нём построены повадки и покачивания.
  final double tSec;
  final bool sleeping;
  final String? weather;
  final String frame;
  final Map<String, ui.Image> images;

  bool get _dimSky =>
      weather == 'cloudy' || weather == 'rain' || weather == 'thunder';
  bool get _hasPond => pets.any((Pet p) => isAquatic(p.type));
  bool get _hasPlants => pets.any((Pet p) => isPlant(p.type));

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintGround(canvas, size);
    if (_hasPlants) _paintBed(canvas, size);
    if (_hasPond) _paintPond(canvas, size);
    _paintPets(canvas, size);
    _paintWeather(canvas, size);
    if (frame != 'none') _paintFrame(canvas, size);
  }

  // ── Небо и погода ────────────────────────────────────────────────────
  void _paintSky(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final List<Color> colors = switch (weather) {
      'thunder' => const <Color>[Color(0xFF6B7B95), Color(0xFFB9C6A8)],
      'rain' => const <Color>[Color(0xFF8FB8CF), Color(0xFFCBE3C8)],
      'cloudy' => const <Color>[Color(0xFFAFC6D6), Color(0xFFE2EFD8)],
      'snow' => const <Color>[Color(0xFFBAD8EE), Color(0xFFEFF7EF)],
      _ => const <Color>[Color(0xFFA6E4FF), Color(0xFFEAF9E0)],
    };
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    // Солнце с гало — прячется при непогоде.
    if (!_dimSky) {
      final Offset sun = Offset(size.width * 0.16, size.height * 0.14);
      canvas.drawCircle(sun, size.width * 0.085,
          Paint()..color = const Color(0xFFFFC800).withOpacity(0.25));
      canvas.drawCircle(sun, size.width * 0.055,
          Paint()..color = const Color(0xFFFFC800));
    }

    // Облака: обычные две + доп. при частичной/пасмурной погоде.
    _paintCloud(canvas, Offset(size.width * 0.55, size.height * 0.14),
        size.width * 0.045);
    _paintCloud(canvas, Offset(size.width * 0.78, size.height * 0.24),
        size.width * 0.035);
    if (weather == 'partly' || weather == 'cloudy' || weather == 'rain') {
      _paintCloud(canvas, Offset(size.width * 0.32, size.height * 0.10),
          size.width * 0.038);
      _paintCloud(canvas, Offset(size.width * 0.92, size.height * 0.09),
          size.width * 0.03);
    }
  }

  void _paintCloud(Canvas canvas, Offset center, double r) {
    final Paint p = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(center + Offset(-r * 0.8, r * 0.25), r * 0.65, p);
    canvas.drawCircle(center, r, p);
    canvas.drawCircle(center + Offset(r * 0.8, r * 0.25), r * 0.6, p);
  }

  void _paintWeather(Canvas canvas, Size size) {
    switch (weather) {
      case 'fog':
        for (int i = 0; i < 3; i++) {
          final double y =
              size.height * (0.45 + 0.16 * i) + math.sin(phase * 6.28 + i) * 8;
          final Rect band =
              Rect.fromLTWH(-20 + math.sin(phase * 6.28 + i * 2) * 14, y,
                  size.width + 40, size.height * 0.075);
          canvas.drawRRect(
            RRect.fromRectAndRadius(band, const Radius.circular(20)),
            Paint()..color = Colors.white.withOpacity(0.38 - i * 0.07),
          );
        }
        break;
      case 'rain':
        final Paint drop = Paint()
          ..color = const Color(0xFF9FD4EF).withOpacity(0.75)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 34; i++) {
          final double fx = ((i * 97) % 100) / 100;
          final double fall = ((phase * 2.2 + fx * 3.0) % 1.0);
          final double x = size.width * fx + fall * 18;
          final double y = size.height * (fall - 0.08);
          canvas.drawLine(Offset(x, y), Offset(x - 5, y + 16), drop);
        }
        break;
      case 'snow':
        final Paint flake = Paint()..color = Colors.white.withOpacity(0.9);
        for (int i = 0; i < 26; i++) {
          final double fx = ((i * 61) % 100) / 100;
          final double fall = ((phase * 0.9 + fx * 2.4) % 1.0);
          final double x = size.width * fx + math.sin(fall * 9 + i) * 14;
          final double y = size.height * fall;
          canvas.drawCircle(Offset(x, y), 2.4 + (i % 3), flake);
        }
        break;
      case 'thunder':
        // Тёмная вуаль.
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFF2E3A55).withOpacity(0.22),
        );
        // Вспышка молнии в узком окне цикла.
        final double cyc = (phase * 1.35) % 1.0;
        if (cyc < 0.09) {
          final double flash = (1 - cyc / 0.09).clamp(0.0, 1.0);
          canvas.drawRect(
            Offset.zero & size,
            Paint()..color = Colors.white.withOpacity(0.30 * flash),
          );
          final Paint bolt = Paint()
            ..color = const Color(0xFFFFE45C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round;
          final double bx = size.width * 0.68;
          final Path p = Path()
            ..moveTo(bx, size.height * 0.06)
            ..lineTo(bx - 26, size.height * 0.30)
            ..lineTo(bx + 6, size.height * 0.32)
            ..lineTo(bx - 20, size.height * 0.62);
          canvas.drawPath(p, bolt);
        }
        break;
      default:
        break;
    }
  }

  // ── Земля ────────────────────────────────────────────────────────────
  void _paintGround(Canvas canvas, Size size) {
    final double groundY = size.height * SceneGeom.groundYF;
    final Rect rect =
        Rect.fromLTWH(0, groundY, size.width, size.height - groundY);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(28),
        topRight: const Radius.circular(28),
      ),
      Paint()..color = const Color(0xFF90D26D),
    );

    // Кустики для объёма
    final Paint bush = Paint()..color = const Color(0xFF7FC45C);
    canvas.drawCircle(
        Offset(size.width * 0.12, groundY + size.height * 0.09), 22, bush);
    canvas.drawCircle(
        Offset(size.width * 0.90, groundY + size.height * 0.07), 18, bush);

    // Цветочки
    final List<Offset> flowers = <Offset>[
      Offset(size.width * 0.06, groundY + size.height * 0.14),
      Offset(size.width * 0.36, groundY + size.height * 0.10),
      Offset(size.width * 0.72, groundY + size.height * 0.16),
      Offset(size.width * 0.95, groundY + size.height * 0.12),
    ];
    final List<Color> fColors = <Color>[
      const Color(0xFFFF8FB1),
      const Color(0xFFFFD166),
      const Color(0xFFEF476F),
      const Color(0xFFFFD166),
    ];
    for (int i = 0; i < flowers.length; i++) {
      canvas.drawCircle(
          flowers[i], 4, Paint()..color = fColors[i % fColors.length]);
      canvas.drawCircle(flowers[i], 1.6, Paint()..color = Colors.white);
    }

    // Трава пучками — лужайка живая.
    for (int i = 0; i < 7; i++) {
      final double fx = size.width * (0.05 + 0.135 * i);
      final double fy =
          groundY + size.height * (0.035 + 0.05 * ((i * 7) % 3) / 3);
      _paintGrassTuft(
        canvas,
        Offset(fx, fy),
        13.0 + (i % 3) * 5.0,
        math.sin(tSec * 1.8 + i * 1.7) * 2.6,
        i.isEven ? const Color(0xFF5FA852) : const Color(0xFF6FBC5E),
      );
    }
  }

  /// Пучок травы, качается на ветру.
  void _paintGrassTuft(
      Canvas canvas, Offset base, double h, double sway, Color color) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final double dx in <double>[-5.0, -1.5, 2.5, 6.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(base.dx + dx, base.dy)
          ..quadraticBezierTo(base.dx + dx + sway, base.dy - h * 0.6,
              base.dx + dx + sway * 1.8 + dx * 0.35, base.dy - h),
        p,
      );
    }
  }

  /// Грядка растений слева сзади: тёплая земля в деревянной рамке.
  void _paintBed(Canvas canvas, Size size) {
    final double x0 = size.width * SceneGeom.bedX0F;
    final double x1 = size.width * SceneGeom.bedX1F;
    final double y = size.height * SceneGeom.bedYF;
    final Rect soil = Rect.fromLTRB(x0, y - size.height * 0.055, x1, y + 6);
    final RRect rrect = RRect.fromRectAndRadius(soil, const Radius.circular(12));

    // Деревянный бортик.
    canvas.drawRRect(
      rrect.inflate(4),
      Paint()..color = const Color(0xFFA9744F),
    );
    // Земля.
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF7A4E2D));
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()..color = const Color(0xFF96683F),
    );
    // Крапинки-камушки.
    final Paint pebble = Paint()..color = const Color(0xFF7A4E2D);
    for (int i = 0; i < 6; i++) {
      final double px = x0 + 10 + ((i * 53) % 90) / 90 * (x1 - x0 - 20);
      final double py = y - 8 + ((i * 31) % 10) - 4;
      canvas.drawCircle(Offset(px, py), 2.0 + (i % 2), pebble);
    }
  }

  /// Пруд — дом водных питомцев (справа сзади).
  void _paintPond(Canvas canvas, Size size) {
    final Offset c = _pondCenter(size);
    final (double rw, double rh) = _pondRadii(size);

    // Песчаный берег.
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rw * 2.16, height: rh * 2.16),
      Paint()..color = const Color(0xFFE8D8A8),
    );
    // Вода.
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rw * 2, height: rh * 2),
      Paint()..color = const Color(0xFF6EC1E4),
    );
    // Блики-волны.
    final Paint wave = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double wy = c.dy - rh * 0.4 + i * rh * 0.42;
      final Rect wr = Rect.fromCenter(
        center: Offset(c.dx + (i - 1) * rw * 0.18, wy),
        width: rw * 0.5,
        height: rh * 0.2,
      );
      canvas.drawArc(wr, 0.15 * math.pi, 0.7 * math.pi, false, wave);
    }
  }

  Offset _pondCenter(Size size) => Offset(
      size.width * SceneGeom.pondCXF,
      size.height * SceneGeom.pondCYF);

  (double, double) _pondRadii(Size size) => (
      size.width * SceneGeom.pondRWF,
      size.height * SceneGeom.pondRHF
    );

  /// Передняя кромка воды — перекрывает нижнюю часть тела водного питомца.
  void _paintWaterFront(Canvas canvas, Size size) {
    final Offset pondC = _pondCenter(size);
    final (double rw, double rh) = _pondRadii(size);
    canvas.drawOval(
      Rect.fromCenter(center: pondC, width: rw * 2, height: rh * 2),
      Paint()..color = const Color(0xFF6EC1E4).withOpacity(0.45),
    );
    // Круги на воде.
    final Paint ripple = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 2; i++) {
      final double t = ((phase * 1.2 + i * 0.5) % 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: pondC + Offset(0, rh * 0.3),
          width: rw * (0.7 + t * 0.9),
          height: rh * (0.7 + t * 0.9) * 0.42,
        ),
        ripple..color = Colors.white.withOpacity(0.55 * (1 - t)),
      );
    }
  }

  // ── Питомцы ──────────────────────────────────────────────────────────
  void _paintPets(Canvas canvas, Size size) {
    if (pets.isEmpty) return;

    final List<Pet> plants =
        pets.where((Pet p) => isPlant(p.type)).toList();
    final List<Pet> water =
        pets.where((Pet p) => isAquatic(p.type)).toList();
    final List<Pet> land = pets
        .where((Pet p) => !isAquatic(p.type) && !isPlant(p.type))
        .toList();

    // Растения на грядке (задний план).
    if (plants.isNotEmpty) _paintPlants(canvas, size, plants);

    // Водные в пруду.
    if (water.isNotEmpty) {
      _paintAquatic(canvas, size, water);
      _paintWaterFront(canvas, size);
    }

    // Сухопутные по полосам глубины (передний план).
    if (land.isNotEmpty) _paintLandPets(canvas, size, land);

    // Бабочки порхают над лужайкой.
    _paintButterflies(canvas, size);
  }

  /// Растения на грядке: семечко (стадия 0) или спрайт с лёгким покачиванием.
  void _paintPlants(Canvas canvas, Size size, List<Pet> plants) {
    final double bedY = size.height * SceneGeom.bedYF;
    final double x0 = size.width * SceneGeom.bedX0F;
    final double x1 = size.width * SceneGeom.bedX1F;
    for (int i = 0; i < plants.length; i++) {
      final Pet pet = plants[i];
      final double slotX =
          x0 + (x1 - x0) * (plants.length == 1 ? 0.5 : i / (plants.length - 1));
      final Offset base = Offset(slotX, bedY - 2);
      if (pet.stage == 0) {
        _paintSeedBed(canvas, base, pet);
        continue;
      }
      final ui.Image? img = images[spriteAsset(pet.type)];
      if (img == null) continue;

      final SpriteMeta m = kSpriteMeta[pet.type] ??
          const SpriteMeta(heightF: 0.14);
      final double boxH = size.height * m.heightF * spriteStageScale(pet.stage);
      final double aspect = img.width / img.height;
      final double boxW = boxH * aspect;
      // Покачивание от «ветра» + во сне чуть притушены.
      final double sway =
          math.sin(tSec * 1.5 + i * 1.9) * 0.035 * (sleeping ? 0.4 : 1.0);
      _drawSprite(
        canvas,
        img,
        ground: base,
        boxW: boxW,
        boxH: boxH,
        facing: 1,
        tilt: sway,
        alpha: sleeping ? 0.88 : 1.0,
        pet: pet,
      );
      if (sleeping) {
        _paintZzz(canvas, base + Offset(boxW * 0.42, -boxH * 0.95), 1.0);
      }
    }
  }

  /// Водные жители патрулируют пруд, у кита — фонтанчик.
  void _paintAquatic(Canvas canvas, Size size, List<Pet> water) {
    final Offset pondC = _pondCenter(size);
    final (double rw, double rh) = _pondRadii(size);
    for (int i = 0; i < water.length; i++) {
      final Pet pet = water[i];
      final ui.Image? img =
          images[spriteAsset(pet.type, sleep: sleeping)];
      if (img == null) continue;
      final SpriteMeta m = kSpriteMeta[pet.type] ??
          const SpriteMeta(heightF: 0.12);
      final double boxH = size.height * m.heightF * spriteStageScale(pet.stage);
      final double aspect = img.width / img.height;
      double boxW = boxH * aspect;
      if (boxW > rw * 1.25) {
        boxW = rw * 1.25;
        boxH = boxW / aspect;
      }

      final int seed = pet.id.hashCode & 0x7fffffff;
      final double off = (seed % 1000) / 100.0;
      // Медленное патрулирование взад-вперёд + лёгкая качка.
      final double swimT = tSec * (pet.type == PetType.crab ? 0.14 : 0.22) + off;
      final double swim = math.sin(swimT);
      final double dx = swim * rw * 0.45;
      final double dy = math.sin(tSec * 1.2 + off * 2) * rh * 0.10;
      final bool goingRight = math.cos(swimT) > 0;
      // Краб ходит по дну, остальные плавают в толще воды.
      final double baseY = pet.type == PetType.crab
          ? pondC.dy + rh * 0.42 + dy
          : pondC.dy - rh * 0.22 + dy;

      _drawSprite(
        canvas,
        img,
        ground: Offset(pondC.dx + dx, baseY),
        boxW: boxW,
        boxH: boxH,
        facing: goingRight ? 1 : -1,
        tilt: math.sin(tSec * 1.1 + off) * 0.03,
        alpha: 1.0,
        pet: pet,
        inWater: true,
      );

      // Фонтанчик у кита: каждые ~7 с выдыхает вверх струйку.
      if (pet.type == PetType.whale && !sleeping) {
        final double cyc = (tSec + off) % 7.0;
        if (cyc < 1.4) {
          _paintWhaleFountain(
            canvas,
            Offset(
              pondC.dx + dx - boxW * 0.28 * (goingRight ? 1 : -1),
              baseY - boxH * 0.86,
            ),
            boxH,
            cyc / 1.4,
          );
        }
      }
      if (sleeping) {
        _paintZzz(canvas,
            Offset(pondC.dx + dx + boxW * 0.4, baseY - boxH * 1.0), 1.0);
      }
    }
  }

  /// Струйка-выдох кита: дуги капель вверх и вниз.
  void _paintWhaleFountain(Canvas canvas, Offset top, double boxH, double t) {
    final double h = boxH * (0.16 + 0.14 * math.sin(t * math.pi));
    final Paint jet = Paint()
      ..color = const Color(0xFFBFE6F7).withOpacity(0.85 * (1 - t * 0.6))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(top, top - Offset(0, h), jet);
    final Paint drop = Paint()..color = const Color(0xFF9FD4EF);
    for (int i = 0; i < 4; i++) {
      final double dt = (t * 1.3 + i * 0.22) % 1.0;
      final double ang = -0.5 + i * 0.34;
      final Offset d =
          top - Offset(math.sin(ang) * h * 0.5 * dt, h * 0.9 * dt);
      canvas.drawCircle(d, 1.6, drop..color = drop.color.withOpacity(0.8 * (1 - dt)));
    }
  }

  /// Сухопутные звери: полосы глубины, яйцо, повадки, сон.
  void _paintLandPets(Canvas canvas, Size size, List<Pet> land) {
    final List<double> ys = SceneGeom.laneYs(land.length);
    final List<double> scales = SceneGeom.laneScales(land.length);
    int eggIdx = 0;
    for (int i = 0; i < land.length; i++) {
      final Pet pet = land[i];
      final double laneY = size.height * ys[i];
      final double depthScale = scales[i];

      if (pet.stage == 0) {
        // Яйцо стоит на месте слева и покачивается.
        final Offset base =
            Offset(size.width * (0.12 + 0.09 * eggIdx++), laneY);
        _paintEgg(canvas, base, speciesBody(pet.type), pet.stageProgress);
        continue;
      }

      final bool hasSleep = kSpriteMeta[pet.type]?.sleep ?? true;
      final ui.Image? img = images[spriteAsset(pet.type, sleep: sleeping && hasSleep)] ??
          images[spriteAsset(pet.type)];
      if (img == null) continue;

      final SpriteMeta m = kSpriteMeta[pet.type] ??
          const SpriteMeta(heightF: 0.16);
      final double boxH = size.height *
          m.heightF *
          spriteStageScale(pet.stage) *
          depthScale;
      final double aspect = img.width / img.height;
      final double boxW = boxH * aspect;

      if (sleeping) {
        // Спит на своём месте: поза сна, zzz, дыхание — лёгкое сжатие.
        final double breath =
            1.0 + math.sin(tSec * 1.1 + i * 2.0) * 0.012;
        final Offset spot = Offset(
            size.width * (land.length == 1 ? 0.5 : 0.14 + 0.72 * i / (land.length - 1)),
            laneY);
        _drawSprite(
          canvas,
          img,
          ground: spot,
          boxW: boxW * breath,
          boxH: boxH,
          facing: 1,
          tilt: 0,
          alpha: 1.0,
          pet: pet,
        );
        _paintZzz(canvas, spot + Offset(boxW * 0.44, -boxH * 0.92), depthScale);
        continue;
      }

      // Повадки: гуляет с паузами (walk/sniff/graze/sit/peck/look).
      final PetBehavior bhv = _petBehavior(pet, i, tSec);
      final double baseX = size.width * (0.13 + 0.74 * bhv.x);
      final Offset ground = Offset(baseX, laneY);

      double tilt = 0;
      double yLift = 0;
      if (kHopPets.contains(pet.type)) {
        // Прыгуны: во время ходьбы перескакивают.
        final double hopP = (tSec * 2 * math.pi / 0.85) % (2 * math.pi);
        final double hop = bhv.kind == 'walk' ? math.sin(hopP).abs() : 0;
        yLift = -hop * boxH * 0.28;
        tilt = math.sin(hopP + 0.6) * 0.10 * (bhv.kind == 'walk' ? 1 : 0);
      } else if (bhv.kind == 'walk') {
        tilt = math.sin(bhv.stride) * 0.035; // перекат с шага на шаг
        yLift = -math.sin(bhv.stride * 2).abs() * boxH * 0.02;
      } else {
        switch (bhv.kind) {
          case 'graze':
            tilt = 0.14 + math.sin(tSec * 8.5) * 0.03; // нос к траве
            break;
          case 'sniff':
            tilt = 0.07 + math.sin(tSec * 7.0) * 0.02;
            break;
          case 'peck':
            tilt = 0.24 + math.sin(tSec * 9.0) * 0.05;
            break;
          case 'look':
            tilt = -0.02 + math.sin(tSec * 1.6) * 0.025;
            break;
          default:
            tilt = math.sin(tSec * 1.2 + i) * 0.012; // сидит смирно
        }
      }

      // Мягкая тень.
      _paintShadow(canvas, ground, boxW * 0.62);

      _drawSprite(
        canvas,
        img,
        ground: ground.translate(0, yLift),
        boxW: boxW,
        boxH: boxH,
        facing: bhv.facing,
        tilt: tilt,
        alpha: 1.0,
        pet: pet,
      );
    }
  }

  void _paintShadow(Canvas canvas, Offset ground, double w) {
    canvas.drawOval(
      Rect.fromCenter(center: ground + const Offset(0, 2), width: w, height: w * 0.16),
      Paint()..color = const Color(0xFF2E7D32).withOpacity(0.18),
    );
  }

  /// Спрайт: разворот по направлению, наклон, аксессуары поверх.
  /// Точка опоры — низ по центру (контакт с землёй).
  void _drawSprite(
    Canvas canvas,
    ui.Image img, {
    required Offset ground,
    required double boxW,
    required double boxH,
    required double facing,
    required double tilt,
    required double alpha,
    required Pet pet,
    bool inWater = false,
  }) {
    canvas.save();
    canvas.translate(ground.dx, ground.dy);
    canvas.scale(facing, 1);
    canvas.rotate(tilt);
    final Rect dst = Rect.fromLTWH(-boxW / 2, -boxH, boxW, boxH);
    final Paint p = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white.withOpacity(alpha);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      dst,
      p,
    );
    if (!sleeping || isPlant(pet.type)) _paintAccessories(canvas, dst, pet);
    canvas.restore();
  }

  // ── Аксессуары гардероба поверх спрайта ──────────────────────────────
  /// Локальное пространство: спрайт смотрит вправо, dst — его прямоугольник.
  void _paintAccessories(Canvas canvas, Rect dst, Pet pet) {
    final Anchors a = anchorsFor(pet.type);
    final double u = dst.width / 100; // единица = 1% ширины спрайта
    Offset at((double, double) p) =>
        dst.topLeft + Offset(p.$1 * dst.width, p.$2 * dst.height);

    switch (pet.hat) {
      case 'cap':
        _accCap(canvas, at(a.hat), u);
        break;
      case 'beanie':
        _accBeanie(canvas, at(a.hat), u);
        break;
      case 'crown':
        _accCrown(canvas, at(a.hat), u);
        break;
      case 'flowerPin':
        _accFlower(canvas, at(a.hat), u);
        break;
      default:
        break;
    }
    switch (pet.neck) {
      case 'scarf':
        _accScarf(canvas, at(a.neck), u);
        break;
      case 'bow':
        _accBow(canvas, at(a.neck), u);
        break;
      case 'bandana':
        _accBandana(canvas, at(a.neck), u);
        break;
      case 'bell':
        _accBell(canvas, at(a.neck), u);
        break;
      default:
        break;
    }
    switch (pet.face) {
      case 'glasses':
        _accGlasses(canvas, at(a.eye), u);
        break;
      case 'shades':
        _accShades(canvas, at(a.eye), u);
        break;
      default:
        break;
    }
  }

  void _accCap(Canvas canvas, Offset c, double u) {
    final Paint red = Paint()..color = const Color(0xFFEF476F);
    final Path dome = Path()
      ..moveTo(-14 * u, 0)
      ..quadraticBezierTo(0, -22 * u, 14 * u, 0)
      ..close();
    canvas.drawPath(dome, red);
    // Козырёк вперёд (морда справа).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(6 * u, -2 * u, 14 * u, 4 * u), const Radius.circular(3)),
      Paint()..color = const Color(0xFFD63860),
    );
    canvas.drawCircle(Offset(0, -12 * u), 2.2 * u, Paint()..color = Colors.white);
  }

  void _accBeanie(Canvas canvas, Offset c, double u) {
    canvas.drawPath(
      Path()
        ..moveTo(-14 * u, 0)
        ..quadraticBezierTo(0, -20 * u, 14 * u, 0)
        ..close(),
      Paint()..color = const Color(0xFFB892E0),
    );
    canvas.drawRect(
        Rect.fromLTWH(-14 * u, -2 * u, 28 * u, 4.4 * u),
        Paint()..color = const Color(0xFF9A77C9));
    canvas.drawCircle(Offset(0, -20 * u), 3.4 * u,
        Paint()..color = const Color(0xFFF7F1EA));
  }

  void _accCrown(Canvas canvas, Offset c, double u) {
    final Paint gold = Paint()
      ..color = const Color(0xFFFFC800)
      ..style = PaintingStyle.fill;
    final Path crown = Path()
      ..moveTo(-11 * u, 0)
      ..lineTo(-11 * u, -10 * u)
      ..lineTo(-5.5 * u, -5 * u)
      ..lineTo(0, -12 * u)
      ..lineTo(5.5 * u, -5 * u)
      ..lineTo(11 * u, -10 * u)
      ..lineTo(11 * u, 0)
      ..close();
    canvas.drawPath(crown, gold);
    canvas.drawCircle(Offset(0, -3 * u), 1.8 * u,
        Paint()..color = const Color(0xFFEF476F));
  }

  void _accFlower(Canvas canvas, Offset c, double u) {
    final Paint petal = Paint()..color = const Color(0xFFFF8FB1);
    for (int i = 0; i < 5; i++) {
      final double ang = i * 2 * math.pi / 5 - math.pi / 2;
      canvas.drawCircle(
          c + Offset(math.cos(ang), math.sin(ang)) * 3.4 * u, 2.4 * u, petal);
    }
    canvas.drawCircle(c, 2.2 * u, Paint()..color = const Color(0xFFFFD166));
  }

  void _accScarf(Canvas canvas, Offset c, double u) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 26 * u, height: 7 * u),
          const Radius.circular(3.5 * u)),
      Paint()..color = const Color(0xFFEF6461),
    );
    // Свисающий кончик.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-12 * u, c.dy, 7 * u, 15 * u),
          const Radius.circular(3 * u)),
      Paint()..color = const Color(0xFFD63860),
    );
  }

  void _accBow(Canvas canvas, Offset c, double u) {
    final Paint pink = Paint()..color = const Color(0xFFFF6FA5);
    canvas.drawCircle(c, 2.6 * u, Paint()..color = const Color(0xFFE85D8A));
    final Path l = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx - 12 * u, c.dy - 7 * u)
      ..quadraticBezierTo(c.dx - 15 * u, c.dy, c.dx - 12 * u, c.dy + 7 * u)
      ..close();
    final Path r = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx + 12 * u, c.dy - 7 * u)
      ..quadraticBezierTo(c.dx + 15 * u, c.dy, c.dx + 12 * u, c.dy + 7 * u)
      ..close();
    canvas.drawPath(l, pink);
    canvas.drawPath(r, pink);
  }

  void _accBandana(Canvas canvas, Offset c, double u) {
    final Paint blue = Paint()..color = const Color(0xFF3E7BFA);
    final Path kerchief = Path()
      ..moveTo(-13 * u, c.dy - 3 * u)
      ..lineTo(13 * u, c.dy - 3 * u)
      ..lineTo(0, c.dy + 11 * u)
      ..close();
    canvas.drawPath(kerchief, blue);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(c.dx, c.dy - 3 * u), width: 26 * u, height: 5 * u),
          const Radius.circular(2.5 * u)),
      Paint()..color = const Color(0xFF2F63D6),
    );
  }

  void _accBell(Canvas canvas, Offset c, double u) {
    final Paint gold = Paint()..color = const Color(0xFFFFC800);
    canvas.drawCircle(c + Offset(0, 5 * u), 4.6 * u, gold);
    canvas.drawCircle(
        c + Offset(0, 5 * u), 2.1 * u, Paint()..color = const Color(0xFFE09E00));
    canvas.drawCircle(c + Offset(0, 3.4 * u), 1.1 * u, Paint()..color = Colors.white);
    // Ремешок.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 24 * u, height: 3.6 * u),
          const Radius.circular(2 * u)),
      Paint()..color = const Color(0xFFD63860),
    );
  }

  void _accGlasses(Canvas canvas, Offset c, double u) {
    final Paint rim = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * u;
    canvas.drawCircle(c, 5.2 * u, rim);
    canvas.drawLine(
        c + Offset(5.2 * u, 0), c + Offset(11 * u, -1.5 * u), rim);
  }

  void _accShades(Canvas canvas, Offset c, double u) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 11 * u, height: 8 * u),
          const Radius.circular(3 * u)),
      Paint()..color = const Color(0xFF23262B),
    );
    canvas.drawLine(
        c + Offset(5.5 * u, -1 * u),
        c + Offset(11 * u, -2.5 * u),
        Paint()
          ..color = const Color(0xFF23262B)
          ..strokeWidth = 1.8 * u);
  }

  // ── Яйцо (звери) и семечко (растения) ────────────────────────────────
  void _paintEgg(Canvas canvas, Offset base, Color spotColor, double progress) {
    final double eggS = 0.95 + 0.45 * progress;
    final double w = 34 * eggS;
    final double h = 44 * eggS;
    final double wobble =
        math.sin(phase * 2 * math.pi * 1.6) * 0.06 * (0.35 + progress);

    canvas.drawOval(
      Rect.fromCenter(
          center: base + const Offset(0, 2), width: w * 1.15, height: h * 0.14),
      Paint()..color = const Color(0xFF2E7D32).withOpacity(0.15),
    );

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(wobble);

    final Rect r =
        Rect.fromCenter(center: Offset(0, -h / 2), width: w, height: h);
    canvas.drawOval(r, Paint()..color = const Color(0xFFFFF6E3));
    canvas.drawOval(
        r.deflate(w * 0.12), Paint()..color = const Color(0xFFFFFBF0));

    final Paint spots = Paint()..color = spotColor.withOpacity(0.65);
    canvas.drawCircle(Offset(-w * 0.18, -h * 0.55), 3.5 * eggS, spots);
    canvas.drawCircle(Offset(w * 0.15, -h * 0.35), 2.6 * eggS, spots);
    canvas.drawCircle(Offset(-w * 0.05, -h * 0.75), 2.0 * eggS, spots);

    final Paint crack = Paint()
      ..color = const Color(0xFFC9A96E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (progress > 0.45) {
      canvas.drawPath(
        Path()
          ..moveTo(0, -h * 0.78)
          ..lineTo(w * 0.14, -h * 0.66)
          ..lineTo(-w * 0.07, -h * 0.54)
          ..lineTo(w * 0.1, -h * 0.44),
        crack,
      );
    }
    if (progress > 0.75) {
      canvas.drawPath(
        Path()
          ..moveTo(-w * 0.05, -h * 0.52)
          ..lineTo(-w * 0.2, -h * 0.4)
          ..lineTo(w * 0.02, -h * 0.28),
        crack,
      );
    }

    canvas.restore();
  }

  /// Семечко на грядке (растения, стадия 0).
  void _paintSeedBed(Canvas canvas, Offset base, Pet pet) {
    const double s = 1.0;
    final double progress = pet.stageProgress;

    // Холмик земли.
    canvas.drawOval(
      Rect.fromCenter(
          center: base - Offset(0, 6 * s), width: 52 * s, height: 18 * s),
      Paint()..color = kSoil,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: base - Offset(0, 9 * s), width: 44 * s, height: 12 * s),
      Paint()..color = const Color(0xFF96683F),
    );

    // Семечко, выглядывающее из земли.
    canvas.save();
    canvas.translate(base.dx + 2 * s, base.dy - 12 * s);
    canvas.rotate(-0.35 + math.sin(phase * 2 * math.pi) * 0.04);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, 0), width: 9 * s, height: 13 * s),
      Paint()..color = const Color(0xFFC89B62),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(-1.6 * s, -2.4 * s), width: 3.4 * s, height: 5 * s),
      Paint()..color = const Color(0xFFE5C793),
    );
    canvas.restore();

    // Трещинка в земле ближе к всходу.
    if (progress > 0.4) {
      final Paint crack = Paint()
        ..color = const Color(0xFF5E3D22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - 14 * s, base.dy - 4 * s)
          ..lineTo(base.dx - 8 * s, base.dy - 8 * s)
          ..lineTo(base.dx - 11 * s, base.dy - 13 * s),
        crack,
      );
    }

    // Проклюнувшийся росточек.
    if (progress > 0.62) {
      final double h = 8 * s + 8 * s * (progress - 0.62) / 0.38;
      canvas.drawRect(
        Rect.fromLTWH(base.dx - 1.3 * s, base.dy - 12 * s - h, 2.6 * s, h),
        Paint()..color = kStem,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx - 5 * s, base.dy - 12 * s - h + 1),
          width: 8 * s,
          height: 3.6 * s,
        ),
        Paint()..color = const Color(0xFF7FC45C),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx + 5 * s, base.dy - 12 * s - h + 3),
          width: 8 * s,
          height: 3.6 * s,
        ),
        Paint()..color = const Color(0xFF7FC45C).withOpacity(0.85),
      );
    }

    // Блеск «скоро вырасту!».
    if (progress > 0.85) {
      final Paint star = Paint()..color = const Color(0xFFFFD166);
      final Offset c = base - Offset(16 * s, 26 * s + math.sin(phase * 6.28) * 2);
      canvas.drawCircle(c, 2.2 * s, star);
      canvas.drawCircle(c, 0.9 * s, Paint()..color = Colors.white);
    }

    if (sleeping) {
      _paintZzz(canvas, base + Offset(22 * s, -26 * s), s);
    }
  }

  void _paintZzz(Canvas canvas, Offset origin, double scale) {
    final List<String> zs = <String>['z', 'z', 'Z'];
    for (int i = 0; i < zs.length; i++) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: zs[i],
          style: TextStyle(
            color: const Color(0xFF6B7B8C).withOpacity(0.9 - i * 0.2),
            fontSize: (11 + i * 3) * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, origin + Offset(i * 9 * scale, -i * 10 * scale));
    }
  }

  /// Две бабочки — поле живёт даже вокруг питомцев.
  void _paintButterflies(Canvas canvas, Size size) {
    if (sleeping || weather == 'thunder' || weather == 'rain') return;
    for (int i = 0; i < 2; i++) {
      final double speed = 0.10 + i * 0.05;
      final double t = (phase * speed + i * 0.45) % 2.0;
      final double tri = t < 1.0 ? t : 2.0 - t;
      final double px = size.width * (0.14 + 0.72 * tri);
      final double py = size.height *
          (0.34 + 0.07 * math.sin(tSec * (1.4 + i) + i * 2.4));
      final double flap = math.sin(tSec * (7 + i * 2)).abs().clamp(0.3, 1.0);
      final Offset c = Offset(px, py);
      final double sz = 7.0 + i * 1.5;
      final Color wingA =
          i == 0 ? const Color(0xFFFF9F45) : const Color(0xFFB892E0);
      final Color wingB =
          i == 0 ? const Color(0xFFFFD166) : const Color(0xFF8FBFF2);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(flap, 1);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-sz * 0.55, -sz * 0.2),
            width: sz,
            height: sz * 0.7),
        Paint()..color = wingA,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(sz * 0.55, -sz * 0.2), width: sz, height: sz * 0.7),
        Paint()..color = wingA,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-sz * 0.42, sz * 0.28),
            width: sz * 0.62,
            height: sz * 0.46),
        Paint()..color = wingB,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(sz * 0.42, sz * 0.28),
            width: sz * 0.62,
            height: sz * 0.46),
        Paint()..color = wingB,
      );
      canvas.restore();
      canvas.drawLine(
        c + Offset(0, -sz * 0.35),
        c + Offset(0, sz * 0.45),
        Paint()
          ..color = const Color(0xFF5A4632)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Декоративные рамки магазина ─────────────────────────────────────
  void _paintFrame(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    switch (frame) {
      case 'gold':
        canvas.drawRRect(
          r.deflate(5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..color = const Color(0xFFFFC800),
        );
        canvas.drawRRect(
          r.deflate(11),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = const Color(0xFFE09E00),
        );
        break;
      case 'neon':
        canvas.drawRRect(
          r.deflate(5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..color = const Color(0xFF3E7BFA).withOpacity(0.85),
        );
        canvas.drawRRect(
          r.deflate(11),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0xFF7FE7FF),
        );
        break;
      case 'flower':
        canvas.drawRRect(
          r.deflate(5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..color = const Color(0xFF7FC45C),
        );
        // Цветочки по углам.
        final List<Offset> corners = <Offset>[
          Offset(13, 13),
          Offset(size.width - 13, 13),
          Offset(13, size.height - 13),
          Offset(size.width - 13, size.height - 13),
        ];
        for (final Offset c in corners) {
          final Paint petal = Paint()..color = const Color(0xFFFF8FB1);
          for (int i = 0; i < 5; i++) {
            final double ang = i * 2 * math.pi / 5;
            canvas.drawCircle(
                c + Offset(math.cos(ang), math.sin(ang)) * 5, 3.4, petal);
          }
          canvas.drawCircle(c, 3, Paint()..color = const Color(0xFFFFD166));
        }
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_PetScenePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.tSec != tSec ||
      oldDelegate.pets.length != pets.length ||
      oldDelegate.sleeping != sleeping ||
      oldDelegate.weather != weather ||
      oldDelegate.frame != frame ||
      !identical(oldDelegate.images, images);
}

