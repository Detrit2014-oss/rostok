import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pet.dart';

/// Анимированная сцена с питомцем: небо, солнце, облака, лужайка
/// и питомцы, нарисованные полностью процедурно (CustomPaint) —
/// ни одной картинки-ассета, мгновенная загрузка на всех платформах.
class PetCanvas extends StatefulWidget {
  const PetCanvas({super.key, required this.pets, this.sleeping = false});

  final List<Pet> pets;

  /// true — идёт сессия детокса: питомцы спят и «копят» рост (zzz).
  final bool sleeping;

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
  });

  final List<Pet> pets;
  final double phase;
  final bool sleeping;

  static const Color _fox = Color(0xFFFF9F45);
  static const Color _cat = Color(0xFFA8B8C8);
  static const Color _owl = Color(0xFFA97FE0);
  static const Color _dragon = Color(0xFF62C46A);
  static const Color _duck = Color(0xFFFFD24C);
  static const Color _bunny = Color(0xFFD9CFC4);
  static const Color _penguin = Color(0xFF56789A);
  static const Color _hedgehog = Color(0xFFC08552);
  static const Color _panda = Color(0xFFF2EEE4);
  static const Color _bear = Color(0xFFA9744F);

  static const Color _beakOrange = Color(0xFFFF9500);
  static const Color _dark = Color(0xFF3A3A3A);
  static const Color _spike = Color(0xFF8B5E34);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintGround(canvas, size);
    _paintPets(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFA6E4FF), Color(0xFFEAF9E0)],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    // Солнце с гало
    final Offset sun = Offset(size.width * 0.16, size.height * 0.14);
    canvas.drawCircle(
      sun,
      size.width * 0.085,
      Paint()..color = const Color(0xFFFFC800).withOpacity(0.25),
    );
    canvas.drawCircle(
      sun,
      size.width * 0.055,
      Paint()..color = const Color(0xFFFFC800),
    );

    // Облака
    _paintCloud(canvas, Offset(size.width * 0.55, size.height * 0.14),
        size.width * 0.045);
    _paintCloud(canvas, Offset(size.width * 0.78, size.height * 0.24),
        size.width * 0.035);
  }

  void _paintCloud(Canvas canvas, Offset center, double r) {
    final Paint p = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(center + Offset(-r * 0.8, r * 0.25), r * 0.65, p);
    canvas.drawCircle(center, r, p);
    canvas.drawCircle(center + Offset(r * 0.8, r * 0.25), r * 0.6, p);
  }

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
        Offset(size.width * 0.15, groundY + size.height * 0.09), 22, bush);
    canvas.drawCircle(
        Offset(size.width * 0.86, groundY + size.height * 0.07), 18, bush);

    // Цветочки
    final List<Offset> flowers = <Offset>[
      Offset(size.width * 0.08, groundY + size.height * 0.14),
      Offset(size.width * 0.30, groundY + size.height * 0.10),
      Offset(size.width * 0.70, groundY + size.height * 0.16),
      Offset(size.width * 0.93, groundY + size.height * 0.12),
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

  void _paintPets(Canvas canvas, Size size) {
    if (pets.isEmpty) return;
    final double groundY = size.height * 0.76;
    final int n = pets.length;
    for (int i = 0; i < n; i++) {
      final Pet pet = pets[i];
      final double t = n == 1 ? 0.5 : 0.18 + 0.64 * i / (n - 1);
      final double x = size.width * t;
      final double bounce =
          math.sin(phase * 2 * math.pi + i * 1.7) * (sleeping ? 0.5 : 2.5);
      final Offset base = Offset(x, groundY - bounce);
      _paintPet(canvas, base, pet, i);
    }
  }

  Color _bodyColor(PetType type) {
    switch (type) {
      case PetType.fox:
        return _fox;
      case PetType.cat:
        return _cat;
      case PetType.owl:
        return _owl;
      case PetType.dragon:
        return _dragon;
      case PetType.duck:
        return _duck;
      case PetType.bunny:
        return _bunny;
      case PetType.penguin:
        return _penguin;
      case PetType.hedgehog:
        return _hedgehog;
      case PetType.panda:
        return _panda;
      case PetType.bear:
        return _bear;
    }
  }

  /// Особый цвет животика: у пингвинёнка и панды он белый.
  Color _bellyColor(PetType type, Color body) {
    if (type == PetType.penguin || type == PetType.panda) {
      return const Color(0xFFFDFBF5);
    }
    return Color.alphaBlend(body.withOpacity(0.35), Colors.white);
  }

  void _paintPet(Canvas canvas, Offset base, Pet pet, int index) {
    final Color body = _bodyColor(pet.type);
    final Color belly = _bellyColor(pet.type, body);
    final double scale = 0.55 + pet.stage * 0.22;
    final double bw = 64 * scale;
    final double bh = 54 * scale;
    final PetType type = pet.type;

    if (pet.stage == 0) {
      _paintEgg(canvas, base, body, pet.stageProgress);
      return;
    }

    final Offset bodyC = base - Offset(0, bh / 2);
    final Paint earPaint = Paint()..color = body;
    final double earY = bodyC.dy - bh * 0.42;

    // ── За телом: лапки, крылья, уши-лопушки, ласты ──────────────────
    // Перепёлки-лапки утёнка и пингвинёнка выглядывают из-под тела.
    if (type == PetType.duck || type == PetType.penguin) {
      final Paint feet = Paint()..color = _beakOrange;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx - bw * 0.18, base.dy - 1.5),
          width: bw * 0.24,
          height: bh * 0.1,
        ),
        feet,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx + bw * 0.18, base.dy - 1.5),
          width: bw * 0.24,
          height: bh * 0.1,
        ),
        feet,
      );
    }

    // Длинные уши зайчика — из-за головы.
    if (type == PetType.bunny) {
      final RRect leftEar = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(bodyC.dx - bw * 0.16, bodyC.dy - bh * 0.62),
          width: bw * 0.17,
          height: bh * 0.62,
        ),
        Radius.circular(bw * 0.085),
      );
      final RRect rightEar = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(bodyC.dx + bw * 0.16, bodyC.dy - bh * 0.62),
          width: bw * 0.17,
          height: bh * 0.62,
        ),
        Radius.circular(bw * 0.085),
      );
      canvas.drawRRect(leftEar, earPaint);
      canvas.drawRRect(rightEar, earPaint);
      final Paint inner = Paint()..color = const Color(0xFFF5B8C4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bodyC.dx - bw * 0.16, bodyC.dy - bh * 0.56),
            width: bw * 0.08,
            height: bh * 0.42,
          ),
          Radius.circular(bw * 0.04),
        ),
        inner,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bodyC.dx + bw * 0.16, bodyC.dy - bh * 0.56),
            width: bw * 0.08,
            height: bh * 0.42,
          ),
          Radius.circular(bw * 0.04),
        ),
        inner,
      );
    }

    // Крылья дракончика (появляются у подростка и взрослого)
    if (type == PetType.dragon && pet.stage >= 2) {
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

    // Ласты пингвинёнка — по бокам, за телом.
    if (type == PetType.penguin) {
      final Paint flipper = Paint()..color = body.withOpacity(0.85);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyC.dx - bw * 0.52, bodyC.dy + bh * 0.02),
          width: bw * 0.2,
          height: bh * 0.52,
        ),
        flipper,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyC.dx + bw * 0.52, bodyC.dy + bh * 0.02),
          width: bw * 0.2,
          height: bh * 0.52,
        ),
        flipper,
      );
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

    // ── Поверх тела: уши, хохолки, колючки ───────────────────────────
    switch (type) {
      case PetType.fox:
      case PetType.cat:
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
        break;
      case PetType.owl:
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.22, earY - bh * 0.02), 6 * scale, earPaint);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.22, earY - bh * 0.02), 6 * scale, earPaint);
        break;
      case PetType.dragon:
        final Paint horn = Paint()..color = const Color(0xFFF6E7C1);
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.14, earY - bh * 0.06), 4 * scale, horn);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.14, earY - bh * 0.06), 4 * scale, horn);
        break;
      case PetType.duck:
        // Хохолок из трёх перьев.
        final Paint tuft = Paint()..color = body;
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.07, bodyC.dy - bh * 0.52),
            2.6 * scale, tuft);
        canvas.drawCircle(
            Offset(bodyC.dx, bodyC.dy - bh * 0.58), 2.8 * scale, tuft);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.07, bodyC.dy - bh * 0.52),
            2.6 * scale, tuft);
        break;
      case PetType.penguin:
        break; // всё нарисовано раньше
      case PetType.hedgehog:
        // Веер колючек по верхней дуге тела.
        final Paint spike = Paint()..color = _spike;
        final List<double> angles = <double>[-2.45, -2.0, -1.57, -1.14, -0.7];
        for (final double a in angles) {
          final double c = math.cos(a);
          final double s = math.sin(a);
          final Offset tip = Offset(
            bodyC.dx + bw * 0.5 * 1.42 * c,
            bodyC.dy + bh * 0.5 * 1.42 * s,
          );
          final Offset b1 = Offset(
            bodyC.dx + bw * 0.5 * math.cos(a + 0.16),
            bodyC.dy + bh * 0.5 * math.sin(a + 0.16),
          );
          final Offset b2 = Offset(
            bodyC.dx + bw * 0.5 * math.cos(a - 0.16),
            bodyC.dy + bh * 0.5 * math.sin(a - 0.16),
          );
          final Path spikePath = Path()
            ..moveTo(b1.dx, b1.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(b2.dx, b2.dy)
            ..close();
          canvas.drawPath(spikePath, spike);
        }
        break;
      case PetType.panda:
        // Чёрные ушки-помпоны.
        final Paint black = Paint()..color = _dark;
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.27, earY - bh * 0.06),
            7.5 * scale, black);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.27, earY - bh * 0.06),
            7.5 * scale, black);
        break;
      case PetType.bear:
        // Круглые ушки с светлой серединкой.
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.3, earY - bh * 0.06), 8 * scale, earPaint);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.3, earY - bh * 0.06), 8 * scale, earPaint);
        final Paint innerEar = Paint()..color = belly;
        canvas.drawCircle(
            Offset(bodyC.dx - bw * 0.3, earY - bh * 0.06),
            4 * scale, innerEar);
        canvas.drawCircle(
            Offset(bodyC.dx + bw * 0.3, earY - bh * 0.06),
            4 * scale, innerEar);
        break;
    }

    // Глаза: спят во время сессии, иногда моргают
    final double eyeY = bodyC.dy - bh * 0.05;
    final double eyeDX = bw * 0.17;
    final bool eyesClosed = sleeping || ((phase * 3) % 1.0) < 0.1;

    // Пятна вокруг глаз панды — под глазами.
    if (type == PetType.panda && !eyesClosed) {
      final Paint patch = Paint()..color = _dark;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyC.dx - eyeDX, eyeY),
          width: bw * 0.3,
          height: bh * 0.34,
        ),
        patch,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyC.dx + eyeDX, eyeY),
          width: bw * 0.3,
          height: bh * 0.34,
        ),
        patch,
      );
    }

    if (eyesClosed) {
      final Paint closed = Paint()
        ..color = const Color(0xFF4A3B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(bodyC.dx - eyeDX, eyeY),
        Offset(bodyC.dx - eyeDX + 7 * scale, eyeY),
        closed,
      );
      canvas.drawLine(
        Offset(bodyC.dx + eyeDX - 7 * scale, eyeY),
        Offset(bodyC.dx + eyeDX, eyeY),
        closed,
      );
    } else {
      final Paint white = Paint()..color = Colors.white;
      final Paint pupil = Paint()..color = const Color(0xFF33261A);
      canvas.drawCircle(Offset(bodyC.dx - eyeDX, eyeY), 6.5 * scale, white);
      canvas.drawCircle(Offset(bodyC.dx + eyeDX, eyeY), 6.5 * scale, white);
      canvas.drawCircle(
          Offset(bodyC.dx - eyeDX + 1.5, eyeY + 1), 3.2 * scale, pupil);
      canvas.drawCircle(
          Offset(bodyC.dx + eyeDX + 1.5, eyeY + 1), 3.2 * scale, pupil);
      canvas.drawCircle(
          Offset(bodyC.dx - eyeDX + 2.5, eyeY - 1.5), 1.1 * scale, white);
      canvas.drawCircle(
          Offset(bodyC.dx + eyeDX + 2.5, eyeY - 1.5), 1.1 * scale, white);
    }

    // Румянец
    final Paint blush = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.55);
    canvas.drawCircle(
        Offset(bodyC.dx - bw * 0.28, bodyC.dy + bh * 0.05), 4.5 * scale, blush);
    canvas.drawCircle(
        Offset(bodyC.dx + bw * 0.28, bodyC.dy + bh * 0.05), 4.5 * scale, blush);

    // Клювы, мордочка, улыбка
    if (type == PetType.owl || type == PetType.penguin) {
      final Path beak = Path()
        ..moveTo(bodyC.dx - (type == PetType.penguin ? 5.5 : 4) * scale,
            bodyC.dy + bh * 0.06)
        ..lineTo(bodyC.dx + (type == PetType.penguin ? 5.5 : 4) * scale,
            bodyC.dy + bh * 0.06)
        ..lineTo(bodyC.dx, bodyC.dy + bh * 0.06 + 7 * scale)
        ..close();
      canvas.drawPath(
        beak,
        Paint()
          ..color =
              type == PetType.penguin ? _beakOrange : const Color(0xFFFFB703),
      );
    } else if (type == PetType.duck) {
      // Широкий утиный клюв.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bodyC.dx, bodyC.dy + bh * 0.1),
            width: bw * 0.36,
            height: bh * 0.16,
          ),
          Radius.circular(4 * scale),
        ),
        Paint()..color = _beakOrange,
      );
    } else if (type == PetType.bear) {
      // Мордочка с носом.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyC.dx, bodyC.dy + bh * 0.16),
          width: bw * 0.4,
          height: bh * 0.3,
        ),
        Paint()..color = belly,
      );
      canvas.drawCircle(
        Offset(bodyC.dx, bodyC.dy + bh * 0.1),
        3.2 * scale,
        Paint()..color = _dark,
      );
      final Paint mouth = Paint()
        ..color = _dark
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
    } else {
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
    }

    // zzz над спящим активным питомцем
    if (sleeping && index == pets.length - 1) {
      _paintZzz(canvas, Offset(bodyC.dx + bw * 0.55, bodyC.dy - bh * 0.6), scale);
    }
  }

  /// Большое яйцо (v1.2.0): заметно крупнее прежнего, слегка покачивается
  /// и покрывается трещинками по мере приближения вылупления.
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
    canvas.drawCircle(
        Offset(-w * 0.18, -h * 0.55), 3.5 * eggS, spots);
    canvas.drawCircle(
        Offset(w * 0.15, -h * 0.35), 2.6 * eggS, spots);
    canvas.drawCircle(
        Offset(-w * 0.05, -h * 0.75), 2.0 * eggS, spots);

    // Трещинки: первая после ~45% прогресса, вторая после ~75%.
    final Paint crack = Paint()
      ..color = const Color(0xFFC9A96E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (progress > 0.45) {
      final Path c1 = Path()
        ..moveTo(0, -h * 0.78)
        ..lineTo(w * 0.14, -h * 0.66)
        ..lineTo(-w * 0.07, -h * 0.54)
        ..lineTo(w * 0.1, -h * 0.44);
      canvas.drawPath(c1, crack);
    }
    if (progress > 0.75) {
      final Path c2 = Path()
        ..moveTo(-w * 0.05, -h * 0.52)
        ..lineTo(-w * 0.2, -h * 0.4)
        ..lineTo(w * 0.02, -h * 0.28);
      canvas.drawPath(c2, crack);
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
      oldDelegate.sleeping != sleeping;
}
