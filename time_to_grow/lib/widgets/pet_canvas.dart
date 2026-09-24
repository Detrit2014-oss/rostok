import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/species_style.dart';
import '../models/pet.dart';

/// Анимированная сцена «Ростка»: небо, солнце, облака, лужайка, погода
/// (v1.7.0) и питомцы, нарисованные полностью процедурно (CustomPaint).
///
/// v1.8.0: настоящие лапы с пальцами (не «палки»), питомцы спят ЛЁЖА,
/// водные жители живут в пруду по центру лужайки, декоративные рамки.
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
            sleeping: widget.sleeping,
            weather: widget.weather,
            frame: widget.frame,
          ),
        );
      },
    );
  }
}

class _PetScenePainter extends CustomPainter {
  _PetScenePainter({
    required this.pets,
    required this.phase,
    required this.sleeping,
    required this.weather,
    required this.frame,
  });

  final List<Pet> pets;
  final double phase;
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

    // Сначала сухопутные, затем водные (они в пруду поверх воды).
    final Offset pondC =
        Offset(size.width * 0.5, size.height * 0.74 + size.height * 0.10);
    final double prw = size.width * 0.30;
    final double prh = size.height * 0.115;

    final List<Pet> land =
        pets.where((Pet p) => !isAquatic(p.type)).toList();
    final List<Pet> water = pets.where((Pet p) => isAquatic(p.type)).toList();

    for (int i = 0; i < land.length; i++) {
      final Pet pet = land[i];
      final double t = land.length == 1 ? 0.5 : 0.14 + 0.72 * i / (land.length - 1);
      final double x = size.width * t;
      final double bounce =
          math.sin(phase * 2 * math.pi + i * 1.7) * (sleeping ? 0.5 : 2.5);
      final Offset base = Offset(x, groundY - bounce);
      _paintPet(canvas, base, pet, i, pondC: null);
    }

    for (int i = 0; i < water.length; i++) {
      final Pet pet = water[i];
      final double bounce = math.sin(phase * 2 * math.pi * 0.6 + i * 2.1) * 3;
      // Водные питомцы плавают по центру пруда (можно несколько — в ряд).
      final double dx =
          water.length == 1 ? 0 : (i - (water.length - 1) / 2) * prw * 0.55;
      final Offset base = Offset(pondC.dx + dx, pondC.dy - prh * 0.35 - bounce);
      _paintPet(canvas, base, pet, i, pondC: Offset(pondC.dx, pondC.dy));
    }

    // Передняя вода поверх водных питомцев — тела «погружены».
    if (water.isNotEmpty) _paintWaterFront(canvas, pondC, prw, prh);
  }

  Color _frameColor() => switch (frame) {
        'gold' => const Color(0xFFFFC800),
        'neon' => const Color(0xFF1CB0F6),
        'flower' => const Color(0xFFFF8FB1),
        _ => const Color(0x00000000),
      };

  void _paintFrame(Canvas canvas, Size size) {
    final Color c = _frameColor();
    if (c.a == 0) return;
    final Rect r = (Offset.zero & size).deflate(7);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..color = c;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(24)),
      p,
    );
    // Уголки-бусины.
    final Paint bead = Paint()..color = c.withOpacity(0.85);
    for (final Offset o in <Offset>[
      Offset(r.left + 10, r.top + 10),
      Offset(r.right - 10, r.top + 10),
      Offset(r.left + 10, r.bottom - 10),
      Offset(r.right - 10, r.bottom - 10),
    ]) {
      canvas.drawCircle(o, 4.5, bead);
    }
    if (frame == 'flower') {
      for (final Offset o in <Offset>[
        Offset(size.width * 0.5, r.top + 9),
        Offset(size.width * 0.5, r.bottom - 9),
      ]) {
        canvas.drawCircle(o, 4, bead);
        canvas.drawCircle(o, 1.8, Paint()..color = Colors.white);
      }
    }
  }

  /// Главный вход: рисует питомца (яйцо / зверя / растение).
  /// [pondC] — центр пруда, если питомец водный.
  void _paintPet(Canvas canvas, Offset base, Pet pet, int index,
      {Offset? pondC}) {
    final Color body = speciesBody(pet.type);
    if (pet.stage == 0) {
      _paintEgg(canvas, base, body, pet.stageProgress);
      return;
    }
    if (isPlant(pet.type)) {
      _paintPlant(canvas, base, pet);
      return;
    }

    final SpeciesStyle st =
        kSpeciesStyles[pet.type] ?? kSpeciesStyles[PetType.fox]!;
    final Color belly = speciesBelly(pet.type);
    final bool lying = sleeping; // v1.8.0: спим только ЛЁЖА.
    final double scale = 0.55 + pet.stage * 0.22;
    final double bw = 64 * scale;
    final double bh = (lying ? 44 * 0.74 : 54) * scale;
    final PetType type = pet.type;

    canvas.save();
    if (lying) {
      // Лёжа: чуть сплющиваем и присыпаем «одеялом» тишины.
      canvas.translate(base.dx, base.dy);
      canvas.scale(1.0, 0.86);
      canvas.translate(-base.dx, -base.dy);
    }

    final Offset bodyC = base - Offset(0, bh / 2 - (lying ? 2 : 0));
    final Paint earPaint = Paint()..color = body;
    final double earY = bodyC.dy - bh * 0.42;
    final double legH = bh * 0.30;

    // ── За телом: хвост, лапы (настоящие, с пальцами) ─────────────────
    _paintTail(canvas, bodyC, bw, bh, st.tail, body, scale);

    if (!lying && !isAquatic(type)) {
      _paintLegs(canvas, base, bw, legH, body, belly, scale);
    }

    // ── Тело и животик ────────────────────────────────────────────────
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

    // ── Особые детали поверх тела ─────────────────────────────────────
    _paintExtra(canvas, bodyC, bw, bh, st.extra, type, body, scale);

    // ── Уши ───────────────────────────────────────────────────────────
    _paintEars(canvas, bodyC, bw, bh, st.ear, body, belly, scale, earY);

    // ── Лицо ──────────────────────────────────────────────────────────
    _paintFace(canvas, bodyC, bw, bh, st, type, belly, scale, lying);

    canvas.restore();

    // zzz над спящим питомцем
    if (sleeping && index == pets.length - 1) {
      _paintZzz(canvas, Offset(bodyC.dx + bw * 0.55, bodyC.dy - bh * 0.7), scale);
    }
  }

  // ── Части тела ───────────────────────────────────────────────────────
  void _paintLegs(Canvas canvas, Offset base, double bw, double legH,
      Color body, Color belly, double scale) {
    final Paint leg = Paint()..color = body;
    final Paint paw = Paint()..color = Color.alphaBlend(body.withOpacity(0.72), Colors.black12);
    final Paint toe = Paint()..color = belly;
    final double legW = bw * 0.15;
    final double topY = base.dy - legH * 1.55;
    for (final double sx in <double>[-0.30, 0.30]) {
      final double x = base.dx + bw * sx;
      // Нога — скруглённый столбик с лёгким сужением.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - legW / 2, topY, legW, legH * 1.55),
          Radius.circular(legW * 0.45),
        ),
        leg,
      );
      // Ступня-лапка с пальцами.
      final Offset footC = Offset(x, base.dy - 2);
      canvas.drawOval(
        Rect.fromCenter(
            center: footC, width: legW * 1.9, height: legW * 1.15),
        paw,
      );
      for (int t = -1; t <= 1; t++) {
        canvas.drawCircle(
          Offset(footC.dx + t * legW * 0.5, footC.dy + legW * 0.18),
          legW * 0.16,
          toe,
        );
      }
    }
  }

  void _paintTail(Canvas canvas, Offset bodyC, double bw, double bh,
      String kind, Color body, double scale) {
    final Paint p = Paint()..color = body;
    switch (kind) {
      case 'bushy':
        final Path tail = Path()
          ..moveTo(bodyC.dx + bw * 0.44, bodyC.dy + bh * 0.22)
          ..quadraticBezierTo(bodyC.dx + bw * 0.95, bodyC.dy + bh * 0.05,
              bodyC.dx + bw * 0.78, bodyC.dy - bh * 0.5)
          ..quadraticBezierTo(bodyC.dx + bw * 0.62, bodyC.dy - bh * 0.05,
              bodyC.dx + bw * 0.44, bodyC.dy + bh * 0.22)
          ..close();
        canvas.drawPath(tail, p);
        break;
      case 'thin':
        final Paint tp = Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * scale
          ..strokeCap = StrokeCap.round;
        final Path t = Path()
          ..moveTo(bodyC.dx + bw * 0.46, bodyC.dy + bh * 0.2)
          ..quadraticBezierTo(bodyC.dx + bw * 0.78, bodyC.dy + bh * 0.28,
              bodyC.dx + bw * 0.72, bodyC.dy - bh * 0.12);
        canvas.drawPath(t, tp);
        break;
      case 'curl':
        final Paint tp = Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5 * scale
          ..strokeCap = StrokeCap.round;
        canvas.drawCircle(Offset(bodyC.dx + bw * 0.55, bodyC.dy + bh * 0.12),
            6.5 * scale, tp);
        break;
      case 'puff':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(bodyC.dx + bw * 0.55, bodyC.dy + bh * 0.05),
            width: bw * 0.26,
            height: bh * 0.34,
          ),
          p,
        );
        break;
      default:
        break;
    }
  }

  void _paintEars(Canvas canvas, Offset bodyC, double bw, double bh,
      String kind, Color body, Color belly, double scale, double earY) {
    final Paint earPaint = Paint()..color = body;
    switch (kind) {
      case 'triangle':
      case 'antler':
        final Path leftEar = Path()
          ..moveTo(bodyC.dx - bw * 0.32, earY + bh * 0.1)
          ..lineTo(bodyC.dx - bw * 0.18, earY - bh * 0.22)
          ..lineTo(bodyC.dx - bw * 0.05, earY + bh * 0.05)
          ..close();
        final Path rightEar = Path()
          ..moveTo(bodyC.dx + bw * 0.32, earY + bh * 0.1)
          ..lineTo(bodyC.dx + bw * 0.18, earY - bh * 0.22)
          ..lineTo(bodyC.dx + bw * 0.05, earY + bh * 0.05)
          ..close();
        canvas.drawPath(leftEar, earPaint);
        canvas.drawPath(rightEar, earPaint);
        if (kind == 'antler') {
          // Рожки оленёнка над ушами.
          final Paint antler = Paint()
            ..color = const Color(0xFF8B5E34)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.6 * scale
            ..strokeCap = StrokeCap.round;
          for (final double sx in <double>[-0.16, 0.16]) {
            final Path a = Path()
              ..moveTo(bodyC.dx + bw * sx, earY - bh * 0.16)
              ..lineTo(bodyC.dx + bw * sx * 1.5, earY - bh * 0.52)
              ..moveTo(bodyC.dx + bw * sx * 1.28, earY - bh * 0.36)
              ..lineTo(bodyC.dx + bw * sx * 1.72, earY - bh * 0.44);
            canvas.drawPath(a, antler);
          }
        }
        break;
      case 'long':
        for (final double sx in <double>[-0.16, 0.16]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(bodyC.dx + bw * sx, bodyC.dy - bh * 0.62),
                width: bw * 0.17,
                height: bh * 0.62,
              ),
              Radius.circular(bw * 0.085),
            ),
            earPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(bodyC.dx + bw * sx, bodyC.dy - bh * 0.56),
                width: bw * 0.08,
                height: bh * 0.42,
              ),
              Radius.circular(bw * 0.04),
            ),
            Paint()..color = const Color(0xFFF5B8C4),
          );
        }
        break;
      case 'round':
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.3, earY - bh * 0.06), 8 * scale, earPaint);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.3, earY - bh * 0.06), 8 * scale, earPaint);
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.3, earY - bh * 0.06),
            4 * scale,
            Paint()..color = belly);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.3, earY - bh * 0.06),
            4 * scale,
            Paint()..color = belly);
        break;
      case 'pom':
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.27, earY - bh * 0.06),
            7.5 * scale,
            earPaint);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.27, earY - bh * 0.06),
            7.5 * scale,
            earPaint);
        break;
      case 'tuft':
        canvas.drawCircle(Offset(bodyC.dx - bw * 0.22, earY - bh * 0.02),
            6 * scale, earPaint);
        canvas.drawCircle(Offset(bodyC.dx + bw * 0.22, earY - bh * 0.02),
            6 * scale, earPaint);
        break;
      case 'horns':
        final Paint horn = Paint()..color = const Color(0xFFF6E7C1);
        canvas.drawCircle(Offset(bodyC.dx - bw * 0.14, earY - bh * 0.06),
            4 * scale, horn);
        canvas.drawCircle(Offset(bodyC.dx + bw * 0.14, earY - bh * 0.06),
            4 * scale, horn);
        break;
      case 'crest':
        final Paint tuft = Paint()..color = body;
        canvas.drawCircle(Offset(bodyC.dx - bw * 0.07, bodyC.dy - bh * 0.52),
            2.6 * scale, tuft);
        canvas.drawCircle(Offset(bodyC.dx, bodyC.dy - bh * 0.58),
            2.8 * scale, tuft);
        canvas.drawCircle(Offset(bodyC.dx + bw * 0.07, bodyC.dy - bh * 0.52),
            2.6 * scale, tuft);
        break;
      default:
        break;
    }
  }

  void _paintExtra(Canvas canvas, Offset bodyC, double bw, double bh,
      String kind, PetType type, Color body, double scale) {
    switch (kind) {
      case 'spikes':
        final Paint spike = Paint()..color = kSpike;
        const List<double> angles = <double>[-2.45, -2.0, -1.57, -1.14, -0.7];
        for (final double a in angles) {
          final Offset tip = Offset(
            bodyC.dx + bw * 0.5 * 1.42 * math.cos(a),
            bodyC.dy + bh * 0.5 * 1.42 * math.sin(a),
          );
          final Offset b1 = Offset(
            bodyC.dx + bw * 0.5 * math.cos(a + 0.16),
            bodyC.dy + bh * 0.5 * math.sin(a + 0.16),
          );
          final Offset b2 = Offset(
            bodyC.dx + bw * 0.5 * math.cos(a - 0.16),
            bodyC.dy + bh * 0.5 * math.sin(a - 0.16),
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
        if (scale >= 0.55 + 2 * 0.22) {
          final Paint wing = Paint()..color = body.withOpacity(0.75);
          final Path leftWing = Path()
            ..moveTo(bodyC.dx - bw * 0.3, bodyC.dy - bh * 0.1)
            ..quadraticBezierTo(bodyC.dx - bw * 0.9, bodyC.dy - bh * 0.9,
                bodyC.dx - bw * 0.2, bodyC.dy - bh * 0.55)
            ..close();
          final Path rightWing = Path()
            ..moveTo(bodyC.dx + bw * 0.3, bodyC.dy - bh * 0.1)
            ..quadraticBezierTo(bodyC.dx + bw * 0.9, bodyC.dy - bh * 0.9,
                bodyC.dx + bw * 0.2, bodyC.dy - bh * 0.55)
            ..close();
          canvas.drawPath(leftWing, wing);
          canvas.drawPath(rightWing, wing);
        }
        break;
      case 'mane':
        // Радужная грива единорога — дуга из 5 цветных прядей.
        final List<Color> mane = <Color>[
          const Color(0xFFEF476F),
          const Color(0xFFFF9F45),
          const Color(0xFFFFD166),
          const Color(0xFF62C46A),
          const Color(0xFF1CB0F6),
        ];
        for (int i = 0; i < mane.length; i++) {
          final double a = -2.2 + i * 0.28;
          canvas.drawCircle(
            Offset(
              bodyC.dx - bw * 0.42 * math.cos(a),
              bodyC.dy - bh * 0.5 - bh * 0.12 * math.sin(a),
            ),
            5.5 * scale,
            Paint()..color = mane[i],
          );
        }
        // Рог.
        final Path horn = Path()
          ..moveTo(bodyC.dx - 4 * scale, bodyC.dy - bh * 0.52)
          ..lineTo(bodyC.dx + 4 * scale, bodyC.dy - bh * 0.52)
          ..lineTo(bodyC.dx, bodyC.dy - bh * 0.86)
          ..close();
        canvas.drawPath(horn, Paint()..color = const Color(0xFFFFD166));
        break;
      case 'shell':
        // Панцирь черепашки.
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
      case 'mask':
        // Маска енота — рисуется в _paintFace (под глазами), тут пятна боков.
        canvas.drawCircle(
          Offset(bodyC.dx + bw * 0.3, bodyC.dy + bh * 0.3),
          5 * scale,
          Paint()..color = Colors.black.withOpacity(0.08),
        );
        break;
      case 'spots':
        // Пятнышки лисёнка/оленёнка на спине.
        final Paint spot = Paint()..color = Colors.white.withOpacity(0.35);
        canvas.drawCircle(Offset(bodyC.dx - bw * 0.26, bodyC.dy - bh * 0.18),
            3.4 * scale, spot);
        canvas.drawCircle(Offset(bodyC.dx + bw * 0.1, bodyC.dy - bh * 0.26),
            2.6 * scale, spot);
        break;
      case 'claws':
        // Клешни крабика — по бокам, над телом.
        final Paint claw = Paint()..color = body;
        for (final double sx in <double>[-0.62, 0.62]) {
          final Offset c = Offset(bodyC.dx + bw * sx, bodyC.dy - bh * 0.1);
          canvas.drawCircle(c, 8.5 * scale, claw);
          // «Зев» клешни.
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: 8.5 * scale),
            sx < 0 ? -0.6 : 2.5,
            1.2,
            false,
            Paint()
              ..color = speciesBelly(type)
              ..style = PaintingStyle.fill,
          );
        }
        break;
      case 'tentacles':
        // Ножки осьминожки — волны под телом.
        final Paint tent = Paint()..color = body;
        for (int i = -2; i <= 2; i++) {
          final Offset c = Offset(bodyC.dx + bw * 0.17 * i, bodyC.dy + bh * 0.52);
          canvas.drawCircle(c, 5.2 * scale, tent);
        }
        break;
      default:
        break;
    }
  }

  void _paintFace(Canvas canvas, Offset bodyC, double bw, double bh,
      SpeciesStyle st, PetType type, Color belly, double scale, bool lying) {
    final double eyeY;
    final double eyeDX;
    switch (st.muzzle) {
      case 'topEyes':
        // Глаза лягушонка на макушке.
        eyeY = bodyC.dy - bh * 0.48;
        eyeDX = bw * 0.2;
        canvas.drawCircle(Offset(bodyC.dx - eyeDX, eyeY - 2), 8.5 * scale,
            Paint()..color = Colors.white);
        canvas.drawCircle(Offset(bodyC.dx + eyeDX, eyeY - 2), 8.5 * scale,
            Paint()..color = Colors.white);
        break;
      default:
        eyeY = bodyC.dy - bh * 0.05;
        eyeDX = bw * 0.17;
        break;
    }

    final bool eyesClosed = lying || ((phase * 3) % 1.0) < 0.1;

    // Пятна-очки панды и маска енота — под глазами.
    if (st.extra == 'patches' && !eyesClosed) {
      final Paint patch = Paint()..color = kInk;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bodyC.dx - eyeDX, eyeY),
            width: bw * 0.3,
            height: bh * 0.34),
        patch,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bodyC.dx + eyeDX, eyeY),
            width: bw * 0.3,
            height: bh * 0.34),
        patch,
      );
    }
    if (st.extra == 'mask') {
      final Paint mask = Paint()..color = const Color(0xFF5A5F66);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bodyC.dx - eyeDX, eyeY),
            width: bw * 0.34,
            height: bh * 0.3),
        mask,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bodyC.dx + eyeDX, eyeY),
            width: bw * 0.34,
            height: bh * 0.3),
        mask,
      );
    }

    if (eyesClosed) {
      final Paint closed = Paint()
        ..color = const Color(0xFF4A3B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(bodyC.dx - eyeDX, eyeY),
          Offset(bodyC.dx - eyeDX + 7 * scale, eyeY), closed);
      canvas.drawLine(Offset(bodyC.dx + eyeDX - 7 * scale, eyeY),
          Offset(bodyC.dx + eyeDX, eyeY), closed);
    } else {
      final Paint white = Paint()..color = Colors.white;
      final Paint pupil = Paint()..color = const Color(0xFF33261A);
      canvas.drawCircle(Offset(bodyC.dx - eyeDX, eyeY), 6.5 * scale, white);
      canvas.drawCircle(Offset(bodyC.dx + eyeDX, eyeY), 6.5 * scale, white);
      canvas.drawCircle(Offset(bodyC.dx - eyeDX + 1.5, eyeY + 1), 3.2 * scale,
          pupil);
      canvas.drawCircle(Offset(bodyC.dx + eyeDX + 1.5, eyeY + 1), 3.2 * scale,
          pupil);
      canvas.drawCircle(Offset(bodyC.dx - eyeDX + 2.5, eyeY - 1.5),
          1.1 * scale, white);
      canvas.drawCircle(Offset(bodyC.dx + eyeDX + 2.5, eyeY - 1.5),
          1.1 * scale, white);
    }

    // Румянец
    final Paint blush = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.55);
    canvas.drawCircle(Offset(bodyC.dx - bw * 0.28, bodyC.dy + bh * 0.05),
        4.5 * scale, blush);
    canvas.drawCircle(Offset(bodyC.dx + bw * 0.28, bodyC.dy + bh * 0.05),
        4.5 * scale, blush);

    // Клювы, мордочки, улыбки
    switch (st.muzzle) {
      case 'beak':
        canvas.drawPath(
          Path()
            ..moveTo(bodyC.dx - 4 * scale, bodyC.dy + bh * 0.06)
            ..lineTo(bodyC.dx + 4 * scale, bodyC.dy + bh * 0.06)
            ..lineTo(bodyC.dx, bodyC.dy + bh * 0.06 + 7 * scale)
            ..close(),
          Paint()..color = const Color(0xFFFFB703),
        );
        break;
      case 'duckBeak':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(bodyC.dx, bodyC.dy + bh * 0.1),
              width: bw * 0.36,
              height: bh * 0.16,
            ),
            Radius.circular(4 * scale),
          ),
          Paint()..color = kBeakOrange,
        );
        break;
      case 'bearMuzzle':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.16),
            width: bw * 0.4,
            height: bh * 0.3,
          ),
          Paint()..color = belly,
        );
        canvas.drawCircle(Offset(bodyC.dx, bodyC.dy + bh * 0.1), 3.2 * scale,
            Paint()..color = kInk);
        final Paint mouth = Paint()
          ..color = kInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.2),
            width: 12 * scale,
            height: 8 * scale,
          ),
          0.3,
          2.5,
          false,
          mouth,
        );
        break;
      case 'snout':
        // Пятачок поросёнка.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.14),
            width: bw * 0.26,
            height: bh * 0.2,
          ),
          Paint()..color = const Color(0xFFE88AA0),
        );
        canvas.drawCircle(
            Offset(bodyC.dx - 3.2 * scale, bodyC.dy + bh * 0.14),
            1.7 * scale,
            Paint()..color = kInk);
        canvas.drawCircle(
            Offset(bodyC.dx + 3.2 * scale, bodyC.dy + bh * 0.14),
            1.7 * scale,
            Paint()..color = kInk);
        break;
      case 'buckteeth':
        final Paint mouth = Paint()
          ..color = const Color(0xFF4A3B2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.08),
            width: 14 * scale,
            height: 10 * scale,
          ),
          0.3,
          2.5,
          false,
          mouth,
        );
        // Два зубика.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bodyC.dx - 4 * scale, bodyC.dy + bh * 0.13,
                3.4 * scale, 4.6 * scale),
            const Radius.circular(1.6),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bodyC.dx + 0.8 * scale, bodyC.dy + bh * 0.13,
                3.4 * scale, 4.6 * scale),
            const Radius.circular(1.6),
          ),
          Paint()..color = Colors.white,
        );
        break;
      case 'whaleMouth':
        // Большая добрая улыбка кита + фонтанчик.
        final Paint mouth = Paint()
          ..color = const Color(0xFF3E6E8E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.05),
            width: bw * 0.5,
            height: bh * 0.5,
          ),
          0.4,
          2.3,
          false,
          mouth,
        );
        break;
      case 'topEyes':
        final Paint pupil = Paint()..color = const Color(0xFF33261A);
        canvas.drawCircle(Offset(bodyC.dx - bw * 0.2, eyeY - 2), 3.6 * scale,
            pupil);
        canvas.drawCircle(Offset(bodyC.dx + bw * 0.2, eyeY - 2), 3.6 * scale,
            pupil);
        final Paint smile = Paint()
          ..color = const Color(0xFF4A3B2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.12),
            width: bw * 0.4,
            height: bh * 0.3,
          ),
          0.35,
          2.4,
          false,
          smile,
        );
        break;
      default:
        final Paint mouth = Paint()
          ..color = const Color(0xFF4A3B2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.08),
            width: 14 * scale,
            height: 10 * scale,
          ),
          0.3,
          2.5,
          false,
          mouth,
        );
        break;
    }

    // Усики тюленя.
    if (type == PetType.seal) {
      final Paint whisk = Paint()
        ..color = const Color(0xFF7A8896)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (final double sx in <double>[-1, 1]) {
        canvas.drawLine(
          Offset(bodyC.dx + sx * bw * 0.1, bodyC.dy + bh * 0.1),
          Offset(bodyC.dx + sx * bw * 0.3, bodyC.dy + bh * 0.06),
          whisk,
        );
        canvas.drawLine(
          Offset(bodyC.dx + sx * bw * 0.1, bodyC.dy + bh * 0.12),
          Offset(bodyC.dx + sx * bw * 0.3, bodyC.dy + bh * 0.14),
          whisk,
        );
      }
    }
  }

  // ── Растения ─────────────────────────────────────────────────────────
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

  // ── Яйцо и zzz ───────────────────────────────────────────────────────
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
      oldDelegate.pets.length != pets.length ||
      oldDelegate.sleeping != sleeping ||
      oldDelegate.weather != weather ||
      oldDelegate.frame != frame;
}
