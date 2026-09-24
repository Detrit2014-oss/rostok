import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/species_style.dart';
import '../models/pet.dart';

/// Анимированная сцена «Ростка»: небо, солнце, облака, лужайка, погода
/// (v1.7.0) и питомцы, нарисованные полностью процедурно (CustomPaint).
///
/// v2.0.0 «Настоящие звери»: анатомия в профиль — силуэт тела с грудью,
/// холкой и крупом, лопатка/бедро, лапы с коленом, шея с углом наклона,
/// один глаз как у настоящего зверя. И НАСТОЯЩИЕ ПОВАДКИ: зверь гуляет,
/// потом останавливается принюхаться, пощипать траву, сесть или
/// поклевать зёрнышки. Птицы клюют, зайчик прыгает, бабочки порхают.
/// Растения всходят из семечка (грядки), а не из яйца.
/// Гардероб: шапки, шарфы, очки и окрасы рисуются прямо на питомце.
class PetCanvas extends StatefulWidget {
  const PetCanvas({
    super.key,
    required this.pets,
    this.sleeping = false,
    this.weather,
    this.frame = 'none',
  });

  final List<Pet> pets;

  /// true — идёт сессия детокса: питомцы спят ЛЁЖА и «копят» рост (zzz).
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
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
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
          ),
        );
      },
    );
  }
}

/// ── Повадки настоящих зверей (v2.0.0) ─────────────────────────────────
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
  });

  final List<Pet> pets;
  final double phase;

  /// Абсолютное время сцены, с — на нём построены повадки и мигание.
  final double tSec;
  final bool sleeping;
  final String? weather;
  final String frame;

  bool get _dimSky =>
      weather == 'cloudy' || weather == 'rain' || weather == 'thunder';
  bool get _hasPond => pets.any((Pet p) => isAquatic(p.type));

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintGround(canvas, size);
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

  // ── Земля и пруд ─────────────────────────────────────────────────────
  void _paintGround(Canvas canvas, Size size) {
    final double groundY = size.height * 0.74;
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
      Offset(size.width * 0.28, groundY + size.height * 0.10),
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

    // Трава пучками — лужайка живая (v2.0.0).
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

  /// Пруд по центру лужайки (v1.8.0) — дом водных питомцев.
  void _paintPond(Canvas canvas, Size size) {
    final double groundY = size.height * 0.74;
    final Offset c = Offset(size.width * 0.5, groundY + size.height * 0.10);
    final double rw = size.width * 0.30;
    final double rh = size.height * 0.115;

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

  /// Передняя кромка воды — перекрывает нижнюю часть тела водного питомца.
  void _paintWaterFront(Canvas canvas, Offset pondC, double rw, double rh) {
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
    final double groundY = size.height * 0.76;

    final Offset pondC =
        Offset(size.width * 0.5, size.height * 0.74 + size.height * 0.10);
    final double prw = size.width * 0.30;
    final double prh = size.height * 0.115;

    final List<Pet> land =
        pets.where((Pet p) => !isAquatic(p.type)).toList();
    final List<Pet> water = pets.where((Pet p) => isAquatic(p.type)).toList();

    for (int i = 0; i < land.length; i++) {
      final Pet pet = land[i];
      if (sleeping) {
        // Спят на своих местах.
        final double baseX = size.width *
            (land.length == 1 ? 0.5 : 0.14 + 0.72 * i / (land.length - 1));
        _paintLandPet(canvas, Offset(baseX, groundY), pet, i, 1, null);
      } else {
        // v2.0.0: повадки — гуляет, потом пауза (принюхивается/щиплет
        // траву/сидит/клюёт) по детерминированному расписанию.
        final PetBehavior bhv = _petBehavior(pet, i, tSec);
        final double baseX = size.width * (0.16 + 0.68 * bhv.x);
        _paintLandPet(
            canvas, Offset(baseX, groundY), pet, i, bhv.facing, bhv);
      }
    }

    for (int i = 0; i < water.length; i++) {
      final Pet pet = water[i];
      final double bounce = math.sin(phase * 2 * math.pi * 0.6 + i * 2.1) * 3;
      final double dx =
          water.length == 1 ? 0 : (i - (water.length - 1) / 2) * prw * 0.55;
      final Offset base = Offset(pondC.dx + dx, pondC.dy - prh * 0.35 - bounce);
      _paintPondPet(canvas, base, pet);
    }

    // Передняя вода поверх водных питомцев — тела «погружены».
    if (water.isNotEmpty) _paintWaterFront(canvas, pondC, prw, prh);

    // Бабочки порхают над лужайкой (v2.0.0).
    _paintButterflies(canvas, size);
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

  /// Диспетчер сухопутного питомца: тень + нужный «корпус».
  void _paintLandPet(Canvas canvas, Offset base, Pet pet, int index,
      double facing, PetBehavior? bhv) {
    final Color bodyBase = speciesBody(pet.type);
    final Color body = skinnedBody(bodyBase, pet.skin);

    if (pet.stage == 0) {
      if (isPlant(pet.type)) {
        _paintSeedBed(canvas, base, pet);
      } else {
        _paintEgg(canvas, base, body, pet.stageProgress);
      }
      return;
    }
    if (isPlant(pet.type)) {
      _paintPlant(canvas, base, pet);
      return;
    }

    final SpeciesStyle st =
        kSpeciesStyles[pet.type] ?? kSpeciesStyles[PetType.fox]!;
    final Color belly = pet.skin == 'classic'
        ? speciesBelly(pet.type)
        : Color.alphaBlend(skinnedBody(bodyBase, pet.skin).withOpacity(0.35),
            Colors.white);

    // Мягкая тень под питомцем (сидящий занимает меньше места вширь).
    final bool sitting = !sleeping && (bhv?.kind ?? '') == 'sit';
    canvas.drawOval(
      Rect.fromCenter(
        center: base + const Offset(0, 3),
        width: 64 * (0.55 + pet.stage * 0.22) * (sitting ? 0.9 : 1.15),
        height: 11 * (0.55 + pet.stage * 0.22),
      ),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    switch (st.build) {
      case 'bird':
        _paintBird(canvas, base, pet, st, body, belly, facing, bhv);
        break;
      case 'hop':
        _paintHop(canvas, base, pet, st, body, belly, facing, bhv);
        break;
      default:
        _paintQuad(canvas, base, pet, st, body, belly, facing, bhv);
    }

    if (sleeping && index == pets.length - 1) {
      _paintZzz(canvas, base + Offset(26, -66 * (0.55 + pet.stage * 0.22)),
          0.55 + pet.stage * 0.22);
    }
  }

  // ── Четвероногий ходок: настоящее тело, шея, голова, повадки ────────
  void _paintQuad(Canvas canvas, Offset base, Pet pet, SpeciesStyle st,
      Color body, Color belly, double facing, PetBehavior? bhv) {
    final double s = 0.55 + pet.stage * 0.22;
    final double bw = 78 * s * st.bodyLen;
    final double bh = 46 * s;
    final double legH = 26 * s * st.legLen;
    final double hr = 15.5 * s * st.headScale;
    final String kind = sleeping ? 'sleep' : (bhv?.kind ?? 'walk');
    final double ease = sleeping ? 0 : (bhv?.poseEase ?? 0);

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(facing, 1); // морда всегда по направлению ходьбы

    final Color bodyDark =
        Color.alphaBlend(body.withOpacity(0.82), Colors.black26);
    final Color far = Color.alphaBlend(body.withOpacity(0.70), Colors.black30);

    if (kind == 'sleep') {
      // Лёжа: распластанное тело, морда на земле, глаза закрыты.
      final Offset bodyC = Offset(0, -bh * 0.34);
      _paintTail(canvas, Offset(-bw * 0.46, bodyC.dy), bw, bh, st, body, s,
          wagging: false);
      canvas.drawPath(
        _quadBodyPath(bodyC, bw, bh * 0.76),
        Paint()..color = body,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: bodyC + Offset(-bw * 0.02, bh * 0.12),
          width: bw * 0.55,
          height: bh * 0.30,
        ),
        Paint()..color = belly,
      );
      _paintBackDetails(canvas, bodyC, bw, bh, st, body, s, stage: 3);
      _paintHeadGroup(
        canvas,
        pivot: Offset(bw * 0.32, bodyC.dy - bh * 0.14),
        neckAngle: 0.62,
        reach: bh * 0.54,
        headTilt: 0.58,
        hr: hr,
        bh: bh,
        st: st,
        pet: pet,
        body: body,
        belly: belly,
        s: s,
        eyesClosed: true,
      );
      canvas.restore();
      return;
    }

    if (kind == 'sit') {
      // ── Сидит: круп на земле, грудь вверх, передние лапы прямые ──
      final Offset haunchC = Offset(-bw * 0.14, -bh * 0.40);
      _paintTail(canvas, Offset(-bw * 0.36, -bh * 0.16), bw, bh, st, body, s,
          wagging: false, wrap: true);
      // Сложенное бедро.
      canvas.drawOval(
        Rect.fromCenter(center: haunchC, width: bw * 0.54, height: bh * 0.92),
        Paint()..color = body,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: haunchC + Offset(bw * 0.12, bh * 0.20),
          width: bw * 0.30,
          height: bh * 0.34,
        ),
        Paint()..color = belly,
      );
      // Задняя лапка выглядывает из-под бедра.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-bw * 0.04, -4 * s),
          width: bw * 0.26,
          height: 8.5 * s,
        ),
        Paint()..color = bodyDark,
      );
      // Наклонённый вверх корпус.
      final double tilt = -0.66;
      final double ct = math.cos(tilt), stl = math.sin(tilt);
      final Offset chestW = haunchC +
          Offset(
            bw * 0.42 * ct - (-bh * 0.04) * stl,
            bw * 0.42 * stl + (-bh * 0.04) * ct,
          );
      canvas.save();
      canvas.translate(haunchC.dx, haunchC.dy);
      canvas.rotate(tilt);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bw * 0.20, -bh * 0.02),
          width: bw * 0.58,
          height: bh * 0.78,
        ),
        Paint()..color = body,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bw * 0.16, bh * 0.14),
          width: bw * 0.34,
          height: bh * 0.28,
        ),
        Paint()..color = belly,
      );
      canvas.restore();
      _paintBackDetails(
        canvas,
        haunchC + Offset(bw * 0.02, -bh * 0.34),
        bw * 0.6,
        bh * 0.8,
        st,
        body,
        s,
        stage: pet.stage,
      );
      // Передние лапы — прямые столбики до земли (верх прячется в груди).
      canvas.drawCircle(
        Offset(chestW.dx, chestW.dy + bh * 0.04),
        bh * 0.16,
        Paint()..color = body,
      );
      for (final double dx in <double>[-5.5 * s, 5.5 * s]) {
        final Color lc = dx < 0 ? far : body;
        final double topY = chestW.dy + bh * 0.02;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(chestW.dx + dx - 4.8 * s, topY, 9.6 * s,
                math.max(4, -topY - 1)),
            Radius.circular(4.8 * s),
          ),
          Paint()..color = lc,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(chestW.dx + dx + 3.2 * s, -2.6 * s),
            width: 13 * s,
            height: 6.5 * s,
          ),
          Paint()..color = lc,
        );
      }
      // Голова сверху груди, чуть поднята — сидит смирно.
      _paintHeadGroup(
        canvas,
        pivot: chestW + Offset(bw * 0.03, -bh * 0.24),
        neckAngle: 0.42,
        reach: bh * 0.55,
        headTilt: 0.06,
        hr: hr,
        bh: bh,
        st: st,
        pet: pet,
        body: body,
        belly: belly,
        s: s,
        eyesClosed: false,
      );
      canvas.restore();
      return;
    }

    // ── Походка / принюхивание / пастьба ──
    final double stride = bhv?.stride ?? phase * 2 * math.pi;
    final double bob = math.sin(stride * 2) * 1.7 * s * (bhv?.bob ?? 1);
    final Offset bodyC = Offset(0, -legH - bh * 0.50 + bob);

    // Лапы: диагональная походка (дальняя пара темнее), у каждой —
    // бедро, голень с коленом и лапка с пальцами.
    final double amp = 0.40;
    _paintLeg(canvas, Offset(bw * 0.30, bodyC.dy + bh * 0.42), legH,
        math.sin(stride + math.pi) * amp, far, s);
    _paintLeg(canvas, Offset(-bw * 0.28, bodyC.dy + bh * 0.40), legH,
        math.sin(stride + math.pi) * amp, far, s,
        rear: true);
    _paintLeg(canvas, Offset(bw * 0.30, bodyC.dy + bh * 0.42), legH,
        math.sin(stride) * amp, body, s);
    _paintLeg(canvas, Offset(-bw * 0.28, bodyC.dy + bh * 0.40), legH,
        math.sin(stride) * amp, body, s,
        rear: true);

    // Хвост виляет на ходу.
    _paintTail(canvas, Offset(-bw * 0.44, bodyC.dy - bh * 0.06), bw, bh, st,
        body, s,
        wagging: true);

    // Тело настоящего зверя: грудь, холка, круп, поджарый живот.
    final Path bodyPath = _quadBodyPath(bodyC, bw, bh);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[bodyDark, body],
        ).createShader(bodyPath.getBounds()),
    );
    // Бедро — объём задней половины.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-bw * 0.27, bodyC.dy + bh * 0.02),
        width: bw * 0.40,
        height: bh * 0.80,
      ),
      Paint()
        ..color = Color.alphaBlend(body.withOpacity(0.86), Colors.black12),
    );
    // Животик.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bw * 0.04, bodyC.dy + bh * 0.30),
        width: bw * 0.62,
        height: bh * 0.34,
      ),
      Paint()..color = belly,
    );
    _paintBackDetails(canvas, bodyC, bw, bh, st, body, s, stage: pet.stage);

    // Голова на шее: повадки меняют угол шеи и наклон морды.
    final double walkNeck = 0.10 + math.sin(stride * 2) * 0.03;
    double neckAngle = walkNeck;
    double reachM = 1.0;
    double headTilt = 0.03 + math.sin(stride * 2 + 1) * 0.02;
    if (ease > 0) {
      double tAng = 0.9, tReach = 0.95, tTilt = 0.35;
      if (kind == 'graze') {
        // Щиплет траву: шея вниз-вперёд, морда ко скошенной «траве».
        tAng = 1.95;
        tReach = 1.06;
        tTilt = 0.60 + math.sin(tSec * 9) * 0.05;
      } else if (kind == 'sniff') {
        // Принюхивается: нос опущен, слегка дёргается.
        tAng = 0.92 + math.sin(tSec * 7) * 0.05;
        tReach = 0.96;
        tTilt = 0.36;
      } else if (kind == 'look') {
        // Осматривается: голова чуть вскинута.
        tAng = -0.10 + math.sin(tSec * 1.5) * 0.07;
        tReach = 1.0;
        tTilt = -0.04;
      }
      neckAngle = walkNeck + (tAng - walkNeck) * ease;
      reachM = 1.0 + (tReach - 1.0) * ease;
      headTilt = headTilt + (tTilt - headTilt) * ease;
    }

    final double neckLen = bh * (0.22 + st.neck * 0.55);
    final Offset pivot = Offset(bw * 0.30, bodyC.dy - bh * 0.06);
    if (st.extra == 'mane') {
      final Offset headW = pivot +
          Offset(math.sin(neckAngle), -math.cos(neckAngle)) *
              (neckLen * reachM);
      _paintMane(canvas, pivot, headW, bw, bh, s);
    }
    _paintHeadGroup(
      canvas,
      pivot: pivot,
      neckAngle: neckAngle,
      reach: neckLen * reachM,
      headTilt: headTilt,
      hr: hr,
      bh: bh,
      st: st,
      pet: pet,
      body: body,
      belly: belly,
      s: s,
      eyesClosed: false,
    );
    canvas.restore();
  }

  /// Силуэт настоящего четвероногого: грудь, холка, прогиб спины,
  /// округлый круп и поджарый живот.
  Path _quadBodyPath(Offset c, double bw, double bh) {
    double bx(double f) => c.dx + f * bw;
    double by(double f) => c.dy + f * bh;
    return Path()
      ..moveTo(bx(0.46), by(0.00))
      ..cubicTo(bx(0.50), by(-0.22), bx(0.42), by(-0.40), bx(0.18), by(-0.48))
      ..cubicTo(bx(0.06), by(-0.52), bx(-0.04), by(-0.44), bx(-0.14), by(-0.47))
      ..cubicTo(bx(-0.26), by(-0.52), bx(-0.40), by(-0.50), bx(-0.47), by(-0.30))
      ..cubicTo(bx(-0.52), by(-0.12), bx(-0.50), by(0.12), bx(-0.42), by(0.28))
      ..cubicTo(bx(-0.32), by(0.44), bx(-0.08), by(0.47), bx(0.12), by(0.42))
      ..cubicTo(bx(0.30), by(0.38), bx(0.42), by(0.22), bx(0.46), by(0.00))
      ..close();
  }

  /// Шея и голова: угол шеи (neckAngle от вертикали), вытянутость (reach)
  /// и наклон морды (headTilt) независимы — поэтому зверь умеет и бежать
  /// с высоко поднятой головой, и принюхиваться, и щипать траву.
  void _paintHeadGroup(
    Canvas canvas, {
    required Offset pivot,
    required double neckAngle,
    required double reach,
    required double headTilt,
    required double hr,
    required double bh,
    required SpeciesStyle st,
    required Pet pet,
    required Color body,
    required Color belly,
    required double s,
    required bool eyesClosed,
  }) {
    final Offset dir = Offset(math.sin(neckAngle), -math.cos(neckAngle));
    final Offset headC = pivot + dir * reach;

    // Шея — толстая дуга от плеч к голове.
    if (reach > hr * 0.2) {
      final Offset mid =
          pivot + dir * (reach * 0.52) + Offset(bh * 0.12, 0);
      canvas.drawPath(
        Path()
          ..moveTo(pivot.dx - bh * 0.10, pivot.dy + bh * 0.04)
          ..quadraticBezierTo(
              mid.dx, mid.dy, headC.dx - hr * 0.15, headC.dy + hr * 0.05),
        Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = bh * 0.30
          ..strokeCap = StrokeCap.round,
      );
    }

    // Череп со всем содержимым поворачивается вместе с мордой.
    canvas.save();
    canvas.translate(headC.dx, headC.dy);
    canvas.rotate(neckAngle * 0.5 + headTilt);
    canvas.drawCircle(Offset.zero, hr, Paint()..color = body);
    _paintEarsOnHead(canvas, Offset.zero, hr, st, body, belly, s);
    _paintHeadDetails(canvas, Offset.zero, hr, st, body, belly, s);
    _paintFaceOnHead(canvas, Offset.zero, hr, st, pet.type, belly, s,
        closed: eyesClosed, body: body);
    _paintHat(canvas, Offset.zero, hr, pet, s);
    _paintGlasses(canvas, Offset.zero, hr, pet, s, hidden: eyesClosed);
    canvas.restore();

    // Шарф или бантик — на основании шеи.
    if (pet.neck == 'scarf' || pet.neck == 'bow') {
      final Offset anchor =
          pivot + dir * (reach * 0.22) + Offset(0, bh * 0.10);
      _paintNeckwear(canvas, anchor, hr, pet, s);
    }
  }

  // ── Птица: две лапы с коленчиком, грушевидное тело, клюв ────────────
  void _paintBird(Canvas canvas, Offset base, Pet pet, SpeciesStyle st,
      Color body, Color belly, double facing, PetBehavior? bhv) {
    final double s = 0.55 + pet.stage * 0.22;
    final double bw = 40 * s;
    final double bh = 56 * s * st.bodyLen;
    final double legH = 16 * s;
    final double hr = 14.5 * s * st.headScale;
    final String kind = sleeping ? 'sleep' : (bhv?.kind ?? 'walk');

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(facing, 1);

    final double walk = bhv?.stride ?? phase * 2 * math.pi;
    if (!sleeping && kind == 'walk') {
      canvas.rotate(math.sin(walk) * 0.05); // переваливающаяся походка
    }

    final double sit = kind == 'sleep' ? legH * 0.35 : legH;
    final Offset bodyC = Offset(0, -sit - bh * 0.44);

    // Лапки с коленчиком (шагают вразнобой).
    final Color far = Color.alphaBlend(body.withOpacity(0.72), Colors.black26);
    final Paint legPaint = Paint()
      ..color = kind == 'sleep' ? far : const Color(0xFFE8A13D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2 * s
      ..strokeCap = StrokeCap.round;
    for (final double off in <double>[0, math.pi]) {
      final double sx = off == 0 ? -bw * 0.14 : bw * 0.14;
      final double swing =
          kind == 'sleep' ? 0 : math.sin(walk + off) * 0.32;
      canvas.save();
      canvas.translate(sx, -sit);
      canvas.rotate(swing);
      canvas.drawLine(Offset(0, 0), Offset(0, sit * 0.62), legPaint);
      canvas.drawLine(Offset(0, sit * 0.62), Offset(2 * s, sit), legPaint);
      // Пальчики.
      canvas.drawLine(
          Offset(2 * s, sit), Offset(6.5 * s, sit + 0.5), legPaint);
      canvas.drawLine(
          Offset(2 * s, sit), Offset(-1.5 * s, sit + 0.5), legPaint);
      canvas.restore();
    }

    // Хвост-веер из перьев.
    final Path tail = Path()
      ..moveTo(-bw * 0.26, bodyC.dy + bh * 0.22)
      ..lineTo(-bw * 0.86, bodyC.dy + bh * 0.30)
      ..lineTo(-bw * 0.80, bodyC.dy + bh * 0.42)
      ..lineTo(-bw * 0.70, bodyC.dy + bh * 0.36)
      ..lineTo(-bw * 0.66, bodyC.dy + bh * 0.50)
      ..lineTo(-bw * 0.28, bodyC.dy + bh * 0.44)
      ..close();
    canvas.drawPath(
        tail,
        Paint()
          ..color =
              Color.alphaBlend(body.withOpacity(0.85), Colors.black12));

    // Тело-груша.
    final Path bodyPath = Path()
      ..moveTo(bw * 0.40, bodyC.dy - bh * 0.10)
      ..cubicTo(bw * 0.44, bodyC.dy - bh * 0.40, bw * 0.10,
          bodyC.dy - bh * 0.52, -bw * 0.10, bodyC.dy - bh * 0.44)
      ..cubicTo(-bw * 0.40, bodyC.dy - bh * 0.30, -bw * 0.44,
          bodyC.dy + bh * 0.16, -bw * 0.26, bodyC.dy + bh * 0.36)
      ..cubicTo(-bw * 0.10, bodyC.dy + bh * 0.52, bw * 0.20,
          bodyC.dy + bh * 0.48, bw * 0.34, bodyC.dy + bh * 0.24)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = body);
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(bw * 0.10, bh * 0.14),
        width: bw * 0.54,
        height: bh * 0.44,
      ),
      Paint()..color = belly,
    );

    // Крылышко с пёрышками.
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(-bw * 0.14, -bh * 0.02),
        width: bw * 0.46,
        height: bh * 0.42,
      ),
      Paint()
        ..color = Color.alphaBlend(body.withOpacity(0.8), Colors.black15),
    );
    final Paint feather = Paint()
      ..color = Color.alphaBlend(body.withOpacity(0.6), Colors.black25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        bodyC + Offset(-bw * 0.10, bh * 0.02),
        bodyC + Offset(-bw * 0.30, bh * 0.16),
        feather);
    canvas.drawLine(
        bodyC + Offset(-bw * 0.08, bh * 0.12),
        bodyC + Offset(-bw * 0.26, bh * 0.26),
        feather);

    // Голова с наклоном: на паузе птица клюёт зёрнышки.
    final double pitch = (bhv?.headPitch ?? 0);
    final Offset pivot = bodyC + Offset(bw * 0.10, -bh * 0.44);
    final double neckLen = bh * 0.26;
    final Offset headC = pivot +
        Offset(math.sin(pitch * 1.35), -math.cos(pitch * 1.35)) * neckLen;
    canvas.save();
    canvas.translate(headC.dx, headC.dy);
    canvas.rotate(pitch * 0.9);
    canvas.drawCircle(Offset.zero, hr, Paint()..color = body);
    _paintEarsOnHead(canvas, Offset.zero, hr, st, body, belly, s);
    _paintHeadDetails(canvas, Offset.zero, hr, st, body, belly, s);
    _paintFaceOnHead(canvas, Offset.zero, hr, st, pet.type, belly, s,
        closed: kind == 'sleep', body: body);
    _paintHat(canvas, Offset.zero, hr, pet, s);
    _paintGlasses(canvas, Offset.zero, hr, pet, s, hidden: kind == 'sleep');
    canvas.restore();
    if (pet.neck == 'scarf' || pet.neck == 'bow') {
      _paintNeckwear(
          canvas, bodyC + Offset(bw * 0.06, -bh * 0.40), hr, pet, s);
    }
    canvas.restore();
  }

  // ── Прыгуны: настоящий зайчик и лягушонок ───────────────────────────
  void _paintHop(Canvas canvas, Offset base, Pet pet, SpeciesStyle st,
      Color body, Color belly, double facing, PetBehavior? bhv) {
    final double s = 0.55 + pet.stage * 0.22;
    final double bw = 58 * s * st.bodyLen;
    final double bh = 46 * s;

    // Прыжок с паузой: 38% цикла в воздухе.
    double jump = 0;
    double airTilt = 0;
    if (!sleeping) {
      final double t =
          (tSec * 0.85 + (pet.id.hashCode.abs() % 100) / 100.0) % 1.0;
      if (t < 0.38) {
        final double k = math.sin(math.pi * t / 0.38);
        jump = -26 * s * k;
        airTilt = 0.09 * k;
      }
    }

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(facing, 1);
    canvas.translate(0, jump);
    canvas.rotate(airTilt);

    final Offset bodyC = Offset(0, -bh * 0.48 - 4 * s);
    final bool isFrog = st.muzzle == 'topEyes';

    if (isFrog) {
      // Лягушонок: глаза-фонарики на макушке + широкая улыбка.
      final double eyeY = bodyC.dy - bh * 0.5;
      final double hr = bh * 0.42;
      // Сложенные задние лапы-пружины.
      final Paint hind =
          Paint()..color = Color.alphaBlend(body.withOpacity(0.88), Colors.black15);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-bw * 0.24, -6 * s),
          width: bw * 0.34,
          height: bh * 0.24,
        ),
        hind,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-bw * 0.30, -bh * 0.2),
          width: bw * 0.42,
          height: bh * 0.3,
        ),
        hind,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bw * 0.34, -3 * s),
          width: bw * 0.16,
          height: bh * 0.14,
        ),
        Paint()..color = body,
      );
      canvas.drawOval(
        Rect.fromCenter(center: bodyC, width: bw, height: bh),
        Paint()..color = body,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: bodyC + Offset(bw * 0.06, bh * 0.18),
          width: bw * 0.52,
          height: bh * 0.44,
        ),
        Paint()..color = belly,
      );
      for (final double sx in <double>[-0.22, 0.22]) {
        canvas.drawCircle(
            Offset(bw * sx, eyeY), hr * 0.42, Paint()..color = body);
        canvas.drawCircle(Offset(bw * sx, eyeY - 2 * s), hr * 0.3,
            Paint()..color = Colors.white);
        canvas.drawCircle(Offset(bw * sx, eyeY - 1 * s), hr * 0.14,
            Paint()..color = const Color(0xFF33261A));
      }
      final Paint smile = Paint()
        ..color = const Color(0xFF4A3B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: bodyC + Offset(bw * 0.02, bh * 0.08),
          width: bw * 0.52,
          height: bh * 0.36,
        ),
        0.35,
        2.4,
        false,
        smile,
      );
      _paintHat(canvas, bodyC + Offset(0, -bh * 0.86), hr, pet, s);
      _paintGlasses(canvas, bodyC, hr, pet, s, hidden: sleeping);
      canvas.restore();
      return;
    }

    // ── Настоящий зайчик ──
    final Color far = Color.alphaBlend(body.withOpacity(0.8), Colors.black15);
    // Пушистый хвостик.
    canvas.drawCircle(
      Offset(-bw * 0.40, bodyC.dy + bh * 0.10),
      7 * s,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    // Заднее бедро и ступня.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-bw * 0.14, bodyC.dy + bh * 0.16),
        width: bw * 0.36,
        height: bh * 0.44,
      ),
      Paint()..color = far,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bw * 0.02, -6 * s),
        width: bw * 0.34,
        height: 8.5 * s,
      ),
      Paint()..color = far,
    );
    // Передние лапки.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bw * 0.30, -5 * s),
        width: bw * 0.15,
        height: 7.5 * s,
      ),
      Paint()..color = body,
    );
    // Тело-капля: круп выше, грудь вперёд.
    final Path bodyPath = Path()
      ..moveTo(bw * 0.42, bodyC.dy - bh * 0.02)
      ..cubicTo(bw * 0.46, bodyC.dy - bh * 0.34, bw * 0.16,
          bodyC.dy - bh * 0.55, -bw * 0.08, bodyC.dy - bh * 0.50)
      ..cubicTo(-bw * 0.36, bodyC.dy - bh * 0.44, -bw * 0.48,
          bodyC.dy - bh * 0.10, -bw * 0.44, bodyC.dy + bh * 0.14)
      ..cubicTo(-bw * 0.38, bodyC.dy + bh * 0.40, bw * 0.10,
          bodyC.dy + bh * 0.46, bw * 0.28, bodyC.dy + bh * 0.24)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = body);
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(bw * 0.02, bh * 0.20),
        width: bw * 0.5,
        height: bh * 0.30,
      ),
      Paint()..color = belly,
    );

    // Голова спереди-сверху; на паузе опускает её к траве.
    final double ease = sleeping ? 0 : (bhv?.poseEase ?? 0);
    final String kind = bhv?.kind ?? 'walk';
    final double drop =
        (kind == 'graze' || kind == 'sniff') ? ease * bh * 0.22 : 0;
    final Offset headC = Offset(bw * 0.40, bodyC.dy - bh * 0.40 + drop);
    final double hr = bh * 0.34;
    canvas.drawCircle(headC, hr, Paint()..color = body);
    _paintEarsOnHead(canvas, headC, hr, st, body, belly, s);
    _paintHeadDetails(canvas, headC, hr, st, body, belly, s);
    _paintFaceOnHead(canvas, headC, hr, st, pet.type, belly, s,
        closed: sleeping, body: body);
    _paintHat(canvas, headC, hr, pet, s);
    _paintGlasses(canvas, headC, hr, pet, s, hidden: sleeping);
    if (pet.neck == 'scarf' || pet.neck == 'bow') {
      _paintNeckwear(
          canvas, headC + Offset(-bh * 0.26, bh * 0.34), hr, pet, s);
    }
    canvas.restore();
  }

  // ── Лапа с коленом: бедро, голень и лапка с пальцами ───────────────
  void _paintLeg(
      Canvas canvas, Offset hip, double legH, double swing, Color color, double s,
      {bool rear = false}) {
    final double w = (rear ? 11.5 : 9.5) * s;
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(swing);
    // Бедро / плечо (прячется в теле).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, legH * 0.06),
        width: w * (rear ? 2.1 : 1.7),
        height: legH * 0.55,
      ),
      Paint()..color = color,
    );
    // Верхний сегмент.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, 0, w, legH * 0.58),
        Radius.circular(w * 0.45),
      ),
      Paint()..color = color,
    );
    // Голень с коленом.
    canvas.save();
    canvas.translate(0, legH * 0.54);
    canvas.rotate(math.max(0, -math.sin(swing)) * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.42, 0, w * 0.84, legH * 0.46),
        Radius.circular(w * 0.4),
      ),
      Paint()..color = color,
    );
    // Лапка с пальцами.
    final Offset foot = Offset(w * 0.10, legH * 0.44);
    canvas.drawOval(
      Rect.fromCenter(center: foot, width: w * 1.55, height: w * 0.95),
      Paint()..color = color,
    );
    final Paint toe = Paint()..color = Colors.white.withOpacity(0.28);
    for (int t = -1; t <= 1; t++) {
      canvas.drawCircle(
        Offset(foot.dx + t * w * 0.42, foot.dy + w * 0.12), w * 0.13, toe);
    }
    canvas.restore();
    canvas.restore();
  }

  // ── Хвосты ──────────────────────────────────────────────────────────
  void _paintTail(Canvas canvas, Offset anchor, double bw, double bh,
      SpeciesStyle st, Color body, double s,
      {required bool wagging, bool wrap = false}) {
    final double wag = wagging ? math.sin(tSec * 2 * math.pi * 1.6) * 0.16 : 0;
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    if (wrap) {
      // Сидит: хвост обёрнут вокруг крупа.
      final bool bushy = st.tail == 'bushy';
      final Paint tp = Paint()
        ..color = body
        ..style = PaintingStyle.stroke
        ..strokeWidth = bushy ? 10 * s : 5 * s
        ..strokeCap = StrokeCap.round;
      final Rect ring = Rect.fromCenter(
        center: Offset(bw * 0.10, bh * 0.12),
        width: bw * 0.44,
        height: bh * 0.54,
      );
      canvas.drawArc(ring, 0.15 * math.pi, 0.95 * math.pi, false, tp);
      if (bushy) {
        canvas.drawArc(
          ring,
          0.15 * math.pi,
          0.32 * math.pi,
          false,
          Paint()
            ..color = Colors.white.withOpacity(0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10 * s
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
      return;
    }
    canvas.rotate(wag);
    switch (st.tail) {
      case 'bushy':
        // Пышный хвост: назад с лёгким прогибом, кончик подкручен вверх.
        final Path tail = Path()
          ..moveTo(0, bh * 0.12)
          ..cubicTo(-bw * 0.30, bh * 0.30, -bw * 0.55, bh * 0.22,
              -bw * 0.70, bh * 0.00)
          ..cubicTo(-bw * 0.80, -bh * 0.14, -bw * 0.72, -bh * 0.34,
              -bw * 0.56, -bh * 0.30)
          ..cubicTo(-bw * 0.62, -bh * 0.18, -bw * 0.52, -bh * 0.02,
              -bw * 0.30, bh * 0.02)
          ..cubicTo(-bw * 0.18, bh * 0.05, -bw * 0.08, bh * 0.10, 0, bh * 0.12)
          ..close();
        canvas.drawPath(tail, Paint()..color = body);
        final Path tip = Path()
          ..moveTo(-bw * 0.70, bh * 0.00)
          ..cubicTo(-bw * 0.80, -bh * 0.14, -bw * 0.72, -bh * 0.34,
              -bw * 0.56, -bh * 0.30)
          ..cubicTo(-bw * 0.60, -bh * 0.16, -bw * 0.58, -bh * 0.06,
              -bw * 0.52, bh * 0.02)
          ..cubicTo(-bw * 0.58, bh * 0.04, -bw * 0.65, bh * 0.03,
              -bw * 0.70, bh * 0.00)
          ..close();
        canvas.drawPath(tip, Paint()..color = Colors.white.withOpacity(0.85));
        break;
      case 'thin':
        final Paint tp = Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * s
          ..strokeCap = StrokeCap.round;
        final Path t = Path()
          ..moveTo(0, bh * 0.2)
          ..cubicTo(-bw * 0.26, bh * 0.30, -bw * 0.36, bh * 0.02,
              -bw * 0.22, -bh * 0.34)
          ..quadraticBezierTo(-bw * 0.16, -bh * 0.46, -bw * 0.06, -bh * 0.40);
        canvas.drawPath(t, tp);
        break;
      case 'curl':
        final Paint tp = Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * s
          ..strokeCap = StrokeCap.round;
        canvas.drawCircle(Offset(-bw * 0.06, 0), 6.5 * s, tp);
        break;
      case 'puff':
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(-bw * 0.05, 0), width: bw * 0.2, height: bh * 0.3),
          Paint()..color = Colors.white.withOpacity(0.85),
        );
        break;
      default:
        break;
    }
    canvas.restore();
  }

  // ── Уши на голове ───────────────────────────────────────────────────
  void _paintEarsOnHead(Canvas canvas, Offset headC, double hr,
      SpeciesStyle st, Color body, Color belly, double s) {
    final Paint earPaint = Paint()..color = body;
    switch (st.ear) {
      case 'triangle':
        for (final double sx in <double>[-0.55, 0.35]) {
          final Path ear = Path()
            ..moveTo(headC.dx + hr * sx, headC.dy - hr * 0.55)
            ..lineTo(headC.dx + hr * (sx + 0.22), headC.dy - hr * 1.45)
            ..lineTo(headC.dx + hr * (sx + 0.42), headC.dy - hr * 0.5)
            ..close();
          canvas.drawPath(ear, earPaint);
        }
        break;
      case 'long':
        for (final double sx in <double>[-0.5, 0.3]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(headC.dx + hr * sx, headC.dy - hr * 1.35),
                width: hr * 0.44,
                height: hr * 1.9,
              ),
              Radius.circular(hr * 0.22),
            ),
            earPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(headC.dx + hr * sx, headC.dy - hr * 1.25),
                width: hr * 0.2,
                height: hr * 1.3,
              ),
              Radius.circular(hr * 0.1),
            ),
            Paint()..color = const Color(0xFFF5B8C4),
          );
        }
        break;
      case 'round':
        for (final double sx in <double>[-0.55, 0.55]) {
          canvas.drawCircle(
              Offset(headC.dx + hr * sx, headC.dy - hr * 0.72),
              hr * 0.42,
              earPaint);
          canvas.drawCircle(
              Offset(headC.dx + hr * sx, headC.dy - hr * 0.72),
              hr * 0.2,
              Paint()..color = belly);
        }
        break;
      case 'pom':
        for (final double sx in <double>[-0.55, 0.55]) {
          canvas.drawCircle(
              Offset(headC.dx + hr * sx, headC.dy - hr * 0.75),
              hr * 0.38,
              earPaint);
        }
        break;
      case 'tuft':
        for (final double sx in <double>[-0.2, 0.0, 0.2]) {
          canvas.drawCircle(
            Offset(headC.dx + hr * sx, headC.dy - hr * 0.95),
            hr * (sx == 0 ? 0.22 : 0.17),
            earPaint,
          );
        }
        break;
      case 'horns':
        for (final double sx in <double>[-0.4, 0.4]) {
          canvas.drawCircle(
              Offset(headC.dx + hr * sx, headC.dy - hr * 0.8),
              hr * 0.18,
              Paint()..color = const Color(0xFFF6E7C1));
        }
        break;
      case 'antler':
        final Paint antler = Paint()
          ..color = const Color(0xFF8B5E34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4 * s
          ..strokeCap = StrokeCap.round;
        for (final double sx in <double>[-0.45, 0.45]) {
          final Path a = Path()
            ..moveTo(headC.dx + hr * sx, headC.dy - hr * 0.7)
            ..lineTo(headC.dx + hr * sx * 1.5, headC.dy - hr * 1.7)
            ..moveTo(headC.dx + hr * sx * 1.28, headC.dy - hr * 1.25)
            ..lineTo(headC.dx + hr * sx * 1.85, headC.dy - hr * 1.45);
          canvas.drawPath(a, antler);
        }
        break;
      default:
        break;
    }
  }

  // ── Особые детали головы (маски, пятна, рожки) ──────────────────────
  void _paintHeadDetails(Canvas canvas, Offset headC, double hr,
      SpeciesStyle st, Color body, Color belly, double s) {
    if (st.extra == 'patches') {
      // Пятна-очки панды.
      final Paint patch = Paint()..color = kInk;
      canvas.drawOval(
        Rect.fromCenter(
            center: headC + Offset(-hr * 0.36, -hr * 0.05),
            width: hr * 0.72,
            height: hr * 0.82),
        patch,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: headC + Offset(hr * 0.36, -hr * 0.05),
            width: hr * 0.72,
            height: hr * 0.82),
        patch,
      );
    }
    if (st.extra == 'mask') {
      // Маска енота.
      final Paint mask = Paint()..color = const Color(0xFF5A5F66);
      canvas.drawOval(
        Rect.fromCenter(
            center: headC + Offset(-hr * 0.36, -hr * 0.05),
            width: hr * 0.8,
            height: hr * 0.66),
        mask,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: headC + Offset(hr * 0.36, -hr * 0.05),
            width: hr * 0.8,
            height: hr * 0.66),
        mask,
      );
    }
    if (st.extra == 'mane') {
      // Рог единорога.
      final Path horn = Path()
        ..moveTo(headC.dx - 3.6 * s, headC.dy - hr * 0.85)
        ..lineTo(headC.dx + 3.6 * s, headC.dy - hr * 0.85)
        ..lineTo(headC.dx, headC.dy - hr * 1.75)
        ..close();
      canvas.drawPath(horn, Paint()..color = const Color(0xFFFFD166));
    }
    if (st.extra == 'antler') {
      // Рога оленёнка.
      final Paint antler = Paint()
        ..color = kSpike
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4 * s
        ..strokeCap = StrokeCap.round;
      for (final double sx in <double>[-0.45, 0.45]) {
        final Path a = Path()
          ..moveTo(headC.dx + hr * sx, headC.dy - hr * 0.7)
          ..lineTo(headC.dx + hr * sx * 1.5, headC.dy - hr * 1.7)
          ..moveTo(headC.dx + hr * sx * 1.28, headC.dy - hr * 1.25)
          ..lineTo(headC.dx + hr * sx * 1.85, headC.dy - hr * 1.45);
        canvas.drawPath(a, antler);
      }
    }
  }

  // ── Морда в профиль: один глаз, нос, рот, усы ───────────────────────
  void _paintFaceOnHead(Canvas canvas, Offset headC, double hr,
      SpeciesStyle st, PetType type, Color belly, double s,
      {required bool closed, required Color body}) {
    final bool blink = !closed && ((tSec * 0.33) % 1.0) < 0.07;
    final double ex = headC.dx + hr * 0.36;
    final double ey = headC.dy - hr * 0.08;
    final Paint ink = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Глаз: белок, радужка, блик; изредка мигает.
    if (closed || blink) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(ex, ey), width: hr * 0.62, height: hr * 0.5),
        0.2 * math.pi,
        0.6 * math.pi,
        false,
        Paint()
          ..color = const Color(0xFF3A3A3A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawCircle(
          Offset(ex, ey), hr * 0.27, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(ex + hr * 0.06, ey + hr * 0.01),
        hr * 0.155,
        Paint()..color = const Color(0xFF33261A),
      );
      canvas.drawCircle(
        Offset(ex + hr * 0.13, ey - hr * 0.09),
        hr * 0.055,
        Paint()..color = Colors.white,
      );
    }

    // Румянец на щеке.
    canvas.drawCircle(
      headC + Offset(-hr * 0.30, hr * 0.36),
      hr * 0.16,
      Paint()..color = const Color(0xFFFF8FA3).withOpacity(0.45),
    );

    switch (st.muzzle) {
      case 'beak':
        canvas.drawPath(
          Path()
            ..moveTo(headC.dx + hr * 0.30, headC.dy - hr * 0.02)
            ..lineTo(headC.dx + hr * 0.30, headC.dy + hr * 0.16)
            ..quadraticBezierTo(headC.dx + hr * 0.55, headC.dy + hr * 0.30,
                headC.dx + hr * 1.02, headC.dy + hr * 0.10)
            ..close(),
          Paint()..color = kBeakOrange,
        );
        break;
      case 'duckBeak':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: headC + Offset(hr * 0.62, hr * 0.14),
              width: hr,
              height: hr * 0.42,
            ),
            Radius.circular(4 * s),
          ),
          Paint()..color = kBeakOrange,
        );
        canvas.drawLine(
          headC + Offset(hr * 0.30, hr * 0.14),
          headC + Offset(hr * 1.08, hr * 0.10),
          Paint()
            ..color = const Color(0xFF3A3A3A).withOpacity(0.6)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
        break;
      case 'bearMuzzle':
        canvas.drawOval(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.40, hr * 0.28),
            width: hr * 0.95,
            height: hr * 0.66,
          ),
          Paint()..color = belly,
        );
        canvas.drawCircle(headC + Offset(hr * 0.62, hr * 0.06), hr * 0.125,
            Paint()..color = kInk);
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.52, hr * 0.34),
            width: hr * 0.5,
            height: hr * 0.4,
          ),
          0.25,
          2.2,
          false,
          ink,
        );
        break;
      case 'buckteeth':
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.42, hr * 0.20),
            width: hr * 0.62,
            height: hr * 0.46,
          ),
          0.3,
          2.2,
          false,
          ink,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(headC.dx + hr * 0.34, headC.dy + hr * 0.26,
                hr * 0.17, hr * 0.26),
            const Radius.circular(1.6),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(headC.dx + hr * 0.55, headC.dy + hr * 0.24,
                hr * 0.17, hr * 0.26),
            const Radius.circular(1.6),
          ),
          Paint()..color = Colors.white,
        );
        break;
      case 'snout':
        canvas.drawOval(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.66, hr * 0.14),
            width: hr * 0.56,
            height: hr * 0.5,
          ),
          Paint()..color = const Color(0xFFE88AA0),
        );
        canvas.drawCircle(headC + Offset(hr * 0.58, hr * 0.14), hr * 0.065,
            Paint()..color = kInk);
        canvas.drawCircle(headC + Offset(hr * 0.76, hr * 0.14), hr * 0.065,
            Paint()..color = kInk);
        break;
      case 'foxMuzzle':
        // Острая мордочка: клин к носу + светлая щёчка.
        canvas.drawPath(
          Path()
            ..moveTo(headC.dx + hr * 0.05, headC.dy - hr * 0.30)
            ..quadraticBezierTo(headC.dx + hr * 0.55, headC.dy - hr * 0.18,
                headC.dx + hr * 1.06, headC.dy + hr * 0.10)
            ..quadraticBezierTo(headC.dx + hr * 0.55, headC.dy + hr * 0.42,
                headC.dx + hr * 0.10, headC.dy + hr * 0.34)
            ..close(),
          Paint()..color = body,
        );
        canvas.drawPath(
          Path()
            ..moveTo(headC.dx + hr * 0.30, headC.dy + hr * 0.08)
            ..quadraticBezierTo(headC.dx + hr * 0.62, headC.dy + hr * 0.12,
                headC.dx + hr * 0.96, headC.dy + hr * 0.14)
            ..quadraticBezierTo(headC.dx + hr * 0.58, headC.dy + hr * 0.34,
                headC.dx + hr * 0.22, headC.dy + hr * 0.30)
            ..close(),
          Paint()..color = Colors.white.withOpacity(0.85),
        );
        canvas.drawCircle(headC + Offset(hr * 1.0, hr * 0.06), hr * 0.085,
            Paint()..color = kInk);
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.72, hr * 0.16),
            width: hr * 0.36,
            height: hr * 0.28,
          ),
          0.3,
          1.5,
          false,
          ink,
        );
        break;
      case 'catMuzzle':
        canvas.drawOval(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.42, hr * 0.24),
            width: hr * 0.72,
            height: hr * 0.56,
          ),
          Paint()..color = belly,
        );
        // Треугольный носик + рот «w».
        canvas.drawPath(
          Path()
            ..moveTo(headC.dx + hr * 0.52, headC.dy + hr * 0.08)
            ..lineTo(headC.dx + hr * 0.66, headC.dy + hr * 0.08)
            ..lineTo(headC.dx + hr * 0.59, headC.dy + hr * 0.18)
            ..close(),
          Paint()..color = kInk,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.47, hr * 0.22),
            width: hr * 0.3,
            height: hr * 0.24,
          ),
          0.1,
          1.6,
          false,
          ink,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.71, hr * 0.22),
            width: hr * 0.3,
            height: hr * 0.24,
          ),
          1.5,
          1.6,
          false,
          ink,
        );
        // Усы.
        final Paint whisk = Paint()
          ..color = const Color(0xFF6E645A).withOpacity(0.75)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round;
        for (final double dy in <double>[-0.04, 0.08, 0.2]) {
          canvas.drawLine(
            headC + Offset(hr * 0.55, hr * (0.12 + dy)),
            headC + Offset(hr * 1.15, hr * (dy * 1.5)),
            whisk,
          );
        }
        break;
      case 'longMuzzle':
        // Вытянутая морда оленя/единорога.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(headC.dx + hr * 0.10, headC.dy - hr * 0.16,
                hr * 1.14, hr * 0.52),
            Radius.circular(hr * 0.26),
          ),
          Paint()..color = body,
        );
        canvas.drawCircle(headC + Offset(hr * 1.16, 0), hr * 0.10,
            Paint()..color = kInk);
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.78, hr * 0.14),
            width: hr * 0.5,
            height: hr * 0.4,
          ),
          0.2,
          1.9,
          false,
          ink,
        );
        break;
      case 'topEyes':
      case 'whaleMouth':
        break; // лягушонок и кит рисуются отдельно
      default:
        // Добрая улыбка с носиком.
        canvas.drawCircle(headC + Offset(hr * 0.55, hr * 0.06), hr * 0.10,
            Paint()..color = kInk);
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.45, hr * 0.20),
            width: hr * 0.56,
            height: hr * 0.4,
          ),
          0.3,
          2.2,
          false,
          ink,
        );
        break;
    }
  }

  // ── Детали спины: иголки, крылья, пятна ─────────────────────────────
  void _paintBackDetails(Canvas canvas, Offset bodyC, double bw, double bh,
      SpeciesStyle st, Color body, double s,
      {int stage = 0}) {
    switch (st.extra) {
      case 'spikes':
        final Paint spike = Paint()..color = kSpike;
        final List<double> angles = <double>[-2.6, -2.25, -1.9, -1.55, -1.2, -0.85];
        for (final double a in angles) {
          final Offset tip = Offset(
            bodyC.dx + bw * 0.5 * 1.3 * math.cos(a),
            bodyC.dy + bh * 0.5 * 1.5 * math.sin(a),
          );
          final Offset b1 = Offset(
            bodyC.dx + bw * 0.5 * math.cos(a + 0.14),
            bodyC.dy + bh * 0.5 * math.sin(a + 0.14),
          );
          final Offset b2 = Offset(
            bodyC.dx + bw * 0.5 * math.cos(a - 0.14),
            bodyC.dy + bh * 0.5 * math.sin(a - 0.14),
          );
          canvas.drawPath(
            Path()
              ..moveTo(b1.dx, b1.dy)
              ..lineTo(tip.dx, tip.dy)
              ..lineTo(b2.dx, b2.dy)
              ..close(),
            spike,
          );
        }
        break;
      case 'wings':
        if (stage >= 2) {
          final Paint wing = Paint()..color = body.withOpacity(0.7);
          final Path leftWing = Path()
            ..moveTo(bodyC.dx - bw * 0.05, bodyC.dy - bh * 0.3)
            ..quadraticBezierTo(bodyC.dx - bw * 0.5, bodyC.dy - bh * 1.15,
                bodyC.dx + bw * 0.18, bodyC.dy - bh * 0.62)
            ..close();
          final Path rightWing = Path()
            ..moveTo(bodyC.dx + bw * 0.16, bodyC.dy - bh * 0.3)
            ..quadraticBezierTo(bodyC.dx + bw * 0.55, bodyC.dy - bh * 1.0,
                bodyC.dx + bw * 0.3, bodyC.dy - bh * 0.55)
            ..close();
          canvas.drawPath(leftWing, wing);
          canvas.drawPath(rightWing, wing);
        }
        break;
      case 'spots':
        final Paint spot = Paint()..color = Colors.white.withOpacity(0.3);
        canvas.drawCircle(
            bodyC + Offset(-bw * 0.22, -bh * 0.2), 3.6 * s, spot);
        canvas.drawCircle(
            bodyC + Offset(bw * 0.08, -bh * 0.28), 2.8 * s, spot);
        break;
      default:
        break;
    }
  }

  // Грива единорога вдоль шеи.
  void _paintMane(
      Canvas canvas, Offset bodyC, Offset headC, double bw, double bh, double s) {
    final List<Color> mane = <Color>[
      const Color(0xFFEF476F),
      const Color(0xFFFF9F45),
      const Color(0xFFFFD166),
      const Color(0xFF62C46A),
      const Color(0xFF1CB0F6),
    ];
    for (int i = 0; i < mane.length; i++) {
      final double t = i / (mane.length - 1);
      final Offset c = Offset(
        bodyC.dx + (headC.dx - bodyC.dx) * t - bw * 0.06,
        bodyC.dy + (headC.dy - bodyC.dy) * t - bh * 0.04,
      );
      canvas.drawCircle(c, 5.5 * s, Paint()..color = mane[i]);
    }
  }

  // ── Гардероб (v1.9.0): шапки, шарфы, очки ───────────────────────────
  void _paintHat(Canvas canvas, Offset headC, double hr, Pet pet, double s) {
    switch (pet.hat) {
      case 'cap':
        canvas.drawArc(
          Rect.fromCenter(
              center: headC + Offset(0, -hr * 0.25),
              width: hr * 2.1,
              height: hr * 2.1),
          math.pi,
          math.pi,
          false,
          Paint()..color = const Color(0xFFEF476F),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(headC.dx + hr * 0.5, headC.dy - hr * 0.42,
                hr * 0.9, hr * 0.24),
            Radius.circular(hr * 0.12),
          ),
          Paint()..color = const Color(0xFFD63A5C),
        );
        break;
      case 'beanie':
        canvas.drawArc(
          Rect.fromCenter(
              center: headC + Offset(0, -hr * 0.3),
              width: hr * 2.2,
              height: hr * 2.3),
          math.pi,
          math.pi,
          false,
          Paint()..color = const Color(0xFF1CB0F6),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(headC.dx - hr * 1.1, headC.dy - hr * 0.5,
                hr * 2.2, hr * 0.34),
            Radius.circular(hr * 0.16),
          ),
          Paint()..color = const Color(0xFF1899D6),
        );
        canvas.drawCircle(headC + Offset(0, -hr * 1.5), hr * 0.24,
            Paint()..color = Colors.white);
        break;
      case 'crown':
        final double baseY = headC.dy - hr * 0.82;
        final Path crown = Path()
          ..moveTo(headC.dx - hr * 0.7, baseY)
          ..lineTo(headC.dx - hr * 0.7, baseY - hr * 0.5)
          ..lineTo(headC.dx - hr * 0.35, baseY - hr * 0.2)
          ..lineTo(headC.dx, baseY - hr * 0.62)
          ..lineTo(headC.dx + hr * 0.35, baseY - hr * 0.2)
          ..lineTo(headC.dx + hr * 0.7, baseY - hr * 0.5)
          ..lineTo(headC.dx + hr * 0.7, baseY)
          ..close();
        canvas.drawPath(crown, Paint()..color = const Color(0xFFFFC800));
        canvas.drawCircle(headC + Offset(0, baseY - hr * 0.16), hr * 0.1,
            Paint()..color = const Color(0xFFEF476F));
        break;
      default:
        break;
    }
  }

  void _paintNeckwear(Canvas canvas, Offset headC, double hr, Pet pet,
      double s,
      {Offset? anchor}) {
    final Offset a = anchor ?? headC + Offset(-hr * 0.2, hr * 0.95);
    switch (pet.neck) {
      case 'scarf':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: a, width: hr * 2.0, height: hr * 0.5),
            Radius.circular(hr * 0.2),
          ),
          Paint()..color = const Color(0xFFEF476F),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(a.dx - hr * 0.75, a.dy, hr * 0.5, hr * 0.95),
            Radius.circular(hr * 0.16),
          ),
          Paint()..color = const Color(0xFFEF476F),
        );
        canvas.drawLine(
          Offset(a.dx - hr * 0.68, a.dy + hr * 0.3),
          Offset(a.dx - hr * 0.35, a.dy + hr * 0.38),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(a.dx - hr * 0.68, a.dy + hr * 0.6),
          Offset(a.dx - hr * 0.35, a.dy + hr * 0.68),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
        break;
      case 'bow':
        final Paint bow = Paint()..color = const Color(0xFFFF6B6B);
        canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(a.dx - hr * 0.65, a.dy - hr * 0.34)
            ..lineTo(a.dx - hr * 0.65, a.dy + hr * 0.34)
            ..close(),
          bow,
        );
        canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(a.dx + hr * 0.65, a.dy - hr * 0.34)
            ..lineTo(a.dx + hr * 0.65, a.dy + hr * 0.34)
            ..close(),
          bow,
        );
        canvas.drawCircle(a, hr * 0.16, Paint()..color = const Color(0xFFE14C4C));
        break;
      default:
        break;
    }
  }

  void _paintGlasses(Canvas canvas, Offset headC, double hr, Pet pet,
      double s,
      {required bool hidden}) {
    if (hidden) return;
    final double eyeDX = hr * 0.38;
    final double eyeY = headC.dy - hr * 0.06;
    switch (pet.face) {
      case 'glasses':
        final Paint g = Paint()
          ..color = const Color(0xFF3A3A3A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4;
        canvas.drawCircle(headC + Offset(-eyeDX, eyeY), hr * 0.44, g);
        canvas.drawCircle(headC + Offset(eyeDX, eyeY), hr * 0.44, g);
        canvas.drawLine(
          Offset(headC.dx - eyeDX + hr * 0.44, eyeY),
          Offset(headC.dx + eyeDX - hr * 0.44, eyeY),
          g,
        );
        break;
      case 'shades':
        final Paint dark = Paint()..color = const Color(0xFF2E3A55);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: headC + Offset(-eyeDX, eyeY),
                width: hr * 0.85,
                height: hr * 0.6),
            Radius.circular(hr * 0.14),
          ),
          dark,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: headC + Offset(eyeDX, eyeY),
                width: hr * 0.85,
                height: hr * 0.6),
            Radius.circular(hr * 0.14),
          ),
          dark,
        );
        canvas.drawLine(
          Offset(headC.dx - eyeDX + hr * 0.42, eyeY - hr * 0.1),
          Offset(headC.dx + eyeDX - hr * 0.42, eyeY - hr * 0.1),
          Paint()
            ..color = const Color(0xFF2E3A55)
            ..strokeWidth = 2.6,
        );
        break;
      default:
        break;
    }
  }

  // ── Водные жители пруда (v1.8.0 стиль) ──────────────────────────────
  void _paintPondPet(Canvas canvas, Offset base, Pet pet) {
    final Color bodyBase = speciesBody(pet.type);
    final Color body = skinnedBody(bodyBase, pet.skin);
    final Color belly = pet.skin == 'classic'
        ? speciesBelly(pet.type)
        : Color.alphaBlend(body.withOpacity(0.35), Colors.white);
    final double s = 0.55 + pet.stage * 0.22;
    final double bw = 64 * s;
    final double bh = 44 * s;
    final PetType type = pet.type;
    final Offset bodyC = base - Offset(0, bh / 2);

    // Хвост-плавник кита.
    if (type == PetType.whale) {
      final Path fluke = Path()
        ..moveTo(bodyC.dx - bw * 0.46, bodyC.dy)
        ..lineTo(bodyC.dx - bw * 0.75, bodyC.dy - bh * 0.3)
        ..lineTo(bodyC.dx - bw * 0.6, bodyC.dy)
        ..lineTo(bodyC.dx - bw * 0.75, bodyC.dy + bh * 0.3)
        ..close();
      canvas.drawPath(fluke, Paint()..color = body);
    }

    canvas.drawOval(
      Rect.fromCenter(center: bodyC, width: bw, height: bh),
      Paint()..color = body,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(0, bh * 0.18),
        width: bw * 0.62,
        height: bh * 0.5,
      ),
      Paint()..color = belly,
    );

    // Особые детали.
    switch (type) {
      case PetType.turtle:
        canvas.drawOval(
          Rect.fromCenter(
            center: bodyC - Offset(0, bh * 0.08),
            width: bw * 0.94,
            height: bh * 0.78,
          ),
          Paint()..color = const Color(0xFF6B9B4E),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: bodyC - Offset(0, bh * 0.08),
            width: bw * 0.55,
            height: bh * 0.44,
          ),
          Paint()..color = const Color(0xFF8FBF6A),
        );
        break;
      case PetType.octopus:
        final Paint tent = Paint()..color = body;
        for (int i = -2; i <= 2; i++) {
          canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.17 * i, bodyC.dy + bh * 0.52),
            5.2 * s,
            tent,
          );
        }
        break;
      case PetType.crab:
        final Paint claw = Paint()..color = body;
        for (final double sx in <double>[-0.62, 0.62]) {
          final Offset c = Offset(bodyC.dx + bw * sx, bodyC.dy - bh * 0.1);
          canvas.drawCircle(c, 8.5 * s, claw);
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: 8.5 * s),
            sx < 0 ? -0.6 : 2.5,
            1.2,
            false,
            Paint()..color = belly,
          );
        }
        break;
      case PetType.whale:
        // Фонтанчик.
        final Paint spout = Paint()
          ..color = const Color(0xFF9FD4EF)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        final Offset top = bodyC - Offset(0, bh * 0.62);
        canvas.drawLine(top, top - const Offset(0, 9), spout);
        canvas.drawLine(top, top - const Offset(5, 8), spout);
        canvas.drawLine(top, top + const Offset(5, -8), spout);
        break;
      default:
        break;
    }

    // Глаза и улыбка (анфас, как раньше).
    final bool eyesClosed = sleeping || ((phase * 3) % 1.0) < 0.08;
    final double eyeDX = bw * 0.17;
    final double eyeY = bodyC.dy - bh * 0.05;
    if (eyesClosed) {
      final Paint closed = Paint()
        ..color = const Color(0xFF4A3B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(bodyC.dx - eyeDX, eyeY),
          Offset(bodyC.dx - eyeDX + 7 * s, eyeY), closed);
      canvas.drawLine(Offset(bodyC.dx + eyeDX - 7 * s, eyeY),
          Offset(bodyC.dx + eyeDX, eyeY), closed);
    } else {
      canvas.drawCircle(Offset(bodyC.dx - eyeDX, eyeY), 6.5 * s,
          Paint()..color = Colors.white);
      canvas.drawCircle(Offset(bodyC.dx + eyeDX, eyeY), 6.5 * s,
          Paint()..color = Colors.white);
      canvas.drawCircle(Offset(bodyC.dx - eyeDX + 1.5, eyeY + 1), 3.2 * s,
          Paint()..color = const Color(0xFF33261A));
      canvas.drawCircle(Offset(bodyC.dx + eyeDX + 1.5, eyeY + 1), 3.2 * s,
          Paint()..color = const Color(0xFF33261A));
    }
    if (type == PetType.whale) {
      final Paint mouth = Paint()
        ..color = const Color(0xFF3E6E8E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: bodyC + Offset(0, bh * 0.05),
          width: bw * 0.5,
          height: bh * 0.5,
        ),
        0.4,
        2.3,
        false,
        mouth,
      );
    } else {
      final Paint smile = Paint()
        ..color = const Color(0xFF4A3B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: bodyC + Offset(0, bh * 0.08),
          width: 14 * s,
          height: 10 * s,
        ),
        0.3,
        2.5,
        false,
        smile,
      );
    }

    // Гардероб в пруду тоже виден.
    _paintHat(canvas, bodyC - Offset(0, bh * 0.62), bw * 0.3, pet, s);
    _paintGlasses(canvas, bodyC, bw * 0.42, pet, s, hidden: eyesClosed);
  }

  // ── Грядка с семечком (растения, стадия 0) ──────────────────────────
  void _paintSeedBed(Canvas canvas, Offset base, Pet pet) {
    final double s = 0.55 + pet.stage * 0.22;
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

  // ── Растения в горшочках (стадии 1+) ────────────────────────────────
  void _paintPlant(Canvas canvas, Offset base, Pet pet) {
    final SpeciesStyle st =
        kSpeciesStyles[pet.type] ?? kSpeciesStyles[PetType.cactus]!;
    final double scale = 0.55 + pet.stage * 0.22;
    final Color body = st.body;

    // Горшочек с грунтом.
    final Path pot = Path()
      ..moveTo(-15 * scale, -26 * scale)
      ..lineTo(15 * scale, -26 * scale)
      ..lineTo(11 * scale, 0)
      ..lineTo(-11 * scale, 0)
      ..close();
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.drawPath(pot, Paint()..color = kPot);
    canvas.drawRect(
      Rect.fromLTWH(-16 * scale, -29 * scale, 32 * scale, 5 * scale),
      Paint()..color = kPotDark,
    );
    canvas.drawRect(
      Rect.fromLTWH(-12.5 * scale, -26 * scale, 25 * scale, 4 * scale),
      Paint()..color = kSoil,
    );

    final double topY = -30 * scale;
    switch (pet.type) {
      case PetType.cactus:
        // Столбик кактуса с ручками и колючками.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, topY - 14 * scale),
                width: 14 * scale,
                height: 30 * scale),
            Radius.circular(7 * scale),
          ),
          Paint()..color = body,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-19 * scale, topY - 22 * scale, 8 * scale,
                14 * scale),
            Radius.circular(4 * scale),
          ),
          Paint()..color = body,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                11 * scale, topY - 26 * scale, 8 * scale, 16 * scale),
            Radius.circular(4 * scale),
          ),
          Paint()..color = body,
        );
        final Paint needle = Paint()..color = Colors.white.withOpacity(0.85);
        for (int i = 0; i < 6; i++) {
          canvas.drawCircle(
            Offset(
              ((i * 13) % 12 - 6).toDouble() * scale,
              topY - 6 * scale - i * 4.4 * scale,
            ),
            1.1 * scale,
            needle,
          );
        }
        // Цветочек на макушке у взрослого.
        if (pet.stage >= 2) {
          canvas.drawCircle(Offset(0, topY - 30 * scale), 4 * scale,
              Paint()..color = const Color(0xFFFF8FB1));
          canvas.drawCircle(Offset(0, topY - 30 * scale), 1.6 * scale,
              Paint()..color = Colors.white);
        }
        break;
      case PetType.bonsai:
        // Изогнутый ствол и крона из трёх шаров.
        final Paint trunk = Paint()
          ..color = kSpike
          ..strokeWidth = 4.6 * scale
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
          Path()
            ..moveTo(0, -26 * scale)
            ..quadraticBezierTo(6 * scale, topY + 12 * scale,
                -3 * scale, topY + 2 * scale),
          trunk,
        );
        canvas.drawCircle(Offset(-4 * scale, topY - 4 * scale), 9 * scale,
            Paint()..color = body);
        canvas.drawCircle(Offset(6 * scale, topY - 8 * scale), 7.4 * scale,
            Paint()..color = body.withOpacity(0.9));
        canvas.drawCircle(Offset(0, topY - 13 * scale), 6 * scale,
            Paint()..color = body.withOpacity(0.8));
        break;
      case PetType.succulent:
        // Розетка: листья-лепестки по кругу.
        for (int i = 0; i < 6; i++) {
          final double a = -math.pi + i * math.pi / 5;
          canvas.save();
          canvas.translate(0, topY - 3 * scale);
          canvas.rotate(a + math.pi / 2);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(0, -6.2 * scale),
              width: 5.4 * scale,
              height: 11 * scale,
            ),
            Paint()
              ..color = i.isEven
                  ? body
                  : Color.alphaBlend(body.withOpacity(0.82), Colors.white),
          );
          canvas.restore();
        }
        canvas.drawCircle(
            Offset(0, topY - 3 * scale),
            4.2 * scale,
            Paint()
              ..color =
                  Color.alphaBlend(body.withOpacity(0.7), Colors.white));
        break;
      case PetType.sunflower:
        // Стебель, два листика и цветок с лицом.
        canvas.drawRect(
          Rect.fromLTWH(-1.8 * scale, topY, 3.6 * scale, 14 * scale),
          Paint()..color = kStem,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(-7 * scale, topY + 7 * scale),
              width: 9 * scale,
              height: 4.4 * scale),
          Paint()..color = kStem,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(7 * scale, topY + 10 * scale),
              width: 9 * scale,
              height: 4.4 * scale),
          Paint()..color = kStem,
        );
        final Offset fc = Offset(0, topY - 6 * scale);
        for (int i = 0; i < 8; i++) {
          final double a = i * math.pi / 4;
          canvas.drawOval(
            Rect.fromCenter(
              center: fc + Offset(math.cos(a) * 9 * scale, math.sin(a) * 9 * scale),
              width: 8 * scale,
              height: 5 * scale,
            ),
            Paint()..color = body,
          );
        }
        canvas.drawCircle(fc, 6.4 * scale, Paint()..color = kSoil);
        // Глазки и улыбка подсолнуха.
        if (pet.stage >= 1) {
          canvas.drawCircle(Offset(fc.dx - 2.4 * scale, fc.dy - 1), 1.3 * scale,
              Paint()..color = Colors.white);
          canvas.drawCircle(Offset(fc.dx + 2.4 * scale, fc.dy - 1), 1.3 * scale,
              Paint()..color = Colors.white);
        }
        break;
      case PetType.clover:
        // Три сердечка-листа на черешках.
        for (final double sx in <double>[-7, 0, 7]) {
          canvas.save();
          canvas.translate(sx * scale, topY - 2 * scale);
          canvas.rotate(sx * 0.035);
          canvas.drawCircle(Offset(0, -3.4 * scale), 4.6 * scale,
              Paint()..color = body);
          canvas.drawCircle(Offset(0, 3.4 * scale), 4.6 * scale,
              Paint()..color = body.withOpacity(0.85));
          canvas.restore();
        }
        if (pet.stage >= 2) {
          canvas.drawCircle(Offset(0, topY - 14 * scale), 2.6 * scale,
              Paint()..color = const Color(0xFFFFD166));
        }
        break;
      default:
        // sprout — символ «Ростка»: стебелёк и два листика.
        canvas.drawRect(
          Rect.fromLTWH(-1.6 * scale, topY + 4 * scale, 3.2 * scale,
              12 * scale),
          Paint()..color = kStem,
        );
        final Path leafL = Path()
          ..moveTo(0, topY + 5 * scale)
          ..quadraticBezierTo(-13 * scale, topY + 2 * scale,
              -11 * scale, topY - 7 * scale)
          ..quadraticBezierTo(-3 * scale, topY - 4 * scale, 0, topY + 5 * scale)
          ..close();
        final Path leafR = Path()
          ..moveTo(0, topY + 5 * scale)
          ..quadraticBezierTo(13 * scale, topY + 2 * scale, 11 * scale,
              topY - 7 * scale)
          ..quadraticBezierTo(3 * scale, topY - 4 * scale, 0, topY + 5 * scale)
          ..close();
        canvas.drawPath(leafL, Paint()..color = body);
        canvas.drawPath(leafR, Paint()..color = body.withOpacity(0.88));
        break;
    }

    canvas.restore();

    if (sleeping) {
      _paintZzz(canvas, Offset(base.dx + 18 * scale, base.dy - 44 * scale), scale);
    }
  }

  // ── Яйцо (звери) и zzz ───────────────────────────────────────────────
  void _paintEgg(Canvas canvas, Offset base, Color spotColor, double progress) {
    final double eggS = 0.95 + 0.45 * progress;
    final double w = 34 * eggS;
    final double h = 44 * eggS;
    final double wobble =
        math.sin(phase * 2 * math.pi * 1.6) * 0.06 * (0.35 + progress);

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

  @override
  bool shouldRepaint(_PetScenePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.tSec != tSec ||
      oldDelegate.pets.length != pets.length ||
      oldDelegate.sleeping != sleeping ||
      oldDelegate.weather != weather ||
      oldDelegate.frame != frame;
}
