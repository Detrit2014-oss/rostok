import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/species_style.dart';
import '../models/pet.dart';

/// Анимированная сцена «Ростка»: небо, солнце, облака, лужайка, погода
/// (v1.7.0) и питомцы, нарисованные полностью процедурно (CustomPaint).
///
/// v1.9.0: звери ходят по лужайке как настоящие — голова на шее,
/// горизонтальное тело на четырёх лапах с чередующейся походкой,
/// птицы семенят на двух лапах, зайчик и лягушонок прыгают.
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

    final Offset pondC =
        Offset(size.width * 0.5, size.height * 0.74 + size.height * 0.10);
    final double prw = size.width * 0.30;
    final double prh = size.height * 0.115;

    final List<Pet> land =
        pets.where((Pet p) => !isAquatic(p.type)).toList();
    final List<Pet> water = pets.where((Pet p) => isAquatic(p.type)).toList();

    for (int i = 0; i < land.length; i++) {
      final Pet pet = land[i];
      final double baseX;
      final double facing;
      if (sleeping) {
        // Спят на своих местах.
        baseX = size.width *
            (land.length == 1 ? 0.5 : 0.14 + 0.72 * i / (land.length - 1));
        facing = 1;
      } else {
        // v1.9.0: звери ГУЛЯЮТ по лужайке — треугольная волна туда-обратно.
        final double speed = 0.14 + (i % 3) * 0.04;
        final double t = (phase * speed + i * 0.41) % 2.0;
        final double tri = t < 1.0 ? t : 2.0 - t;
        final double minX = size.width * 0.16;
        final double maxX = size.width * 0.84;
        baseX = minX + (maxX - minX) * tri;
        facing = t < 1.0 ? 1 : -1;
      }
      _paintLandPet(canvas, Offset(baseX, groundY), pet, i, facing);
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
  }

  /// Диспетчер сухопутного питомца: тень + нужный «корпус».
  void _paintLandPet(
      Canvas canvas, Offset base, Pet pet, int index, double facing) {
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

    // Мягкая тень под питомцем.
    canvas.drawOval(
      Rect.fromCenter(
        center: base + const Offset(0, 3),
        width: 64 * (0.55 + pet.stage * 0.22) * 1.15,
        height: 11 * (0.55 + pet.stage * 0.22),
      ),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    switch (st.build) {
      case 'bird':
        _paintBird(canvas, base, pet, st, body, belly, facing);
        break;
      case 'hop':
        _paintHop(canvas, base, pet, st, body, belly, facing);
        break;
      default:
        _paintQuad(canvas, base, pet, st, body, belly, facing);
    }

    if (sleeping && index == pets.length - 1) {
      _paintZzz(canvas, base + Offset(26, -66 * (0.55 + pet.stage * 0.22)),
          0.55 + pet.stage * 0.22);
    }
  }

  // ── Четвероногий ходок: тело, 4 лапы с походкой, шея, голова ────────
  void _paintQuad(Canvas canvas, Offset base, Pet pet, SpeciesStyle st,
      Color body, Color belly, double facing) {
    final double s = 0.55 + pet.stage * 0.22;
    final double bw = 78 * s * st.bodyLen;
    final double bh = 46 * s;
    final double legH = 26 * s * st.legLen;
    final double hr = 15.5 * s * st.headScale;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(facing, 1); // морда всегда по направлению ходьбы

    if (sleeping) {
      // Лёжа: тело распластано, лапки спрятаны, голова впереди на земле.
      final Offset bodyC = Offset(0, -bh * 0.36);
      _paintTail(canvas, Offset(-bw * 0.46, bodyC.dy), bw, bh, st, body, s,
          wagging: false);
      canvas.drawOval(
        Rect.fromCenter(center: bodyC, width: bw, height: bh * 0.74),
        Paint()..color = body,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: bodyC + Offset(-bw * 0.02, bh * 0.14),
          width: bw * 0.55,
          height: bh * 0.36,
        ),
        Paint()..color = belly,
      );
      _paintBackDetails(canvas, bodyC, bw, bh, st, body, s, stage: 3);
      final Offset headC = Offset(bw * 0.50, -bh * 0.34);
      canvas.drawLine(
        Offset(bw * 0.34, bodyC.dy - bh * 0.12),
        headC,
        Paint()
          ..color = body
          ..strokeWidth = bh * 0.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(headC, hr, Paint()..color = body);
      _paintEarsOnHead(canvas, headC, hr, st, body, belly, s);
      _paintHeadDetails(canvas, headC, hr, st, body, belly, s);
      _paintFaceOnHead(canvas, headC, hr, st, pet.type, belly, s, closed: true);
      _paintHat(canvas, headC, hr, pet, s);
      _paintGlasses(canvas, headC, hr, pet, s, hidden: true);
      canvas.restore();
      return;
    }

    final double walk = phase * 2 * math.pi;
    final double bob = math.sin(walk * 2) * 1.6 * s;
    final Offset bodyC = Offset(0, -legH - bh * 0.46 + bob);

    // Дальняя пара лап (диагональ, темнее).
    final Color far = Color.alphaBlend(body.withOpacity(0.72), Colors.black26);
    _paintLeg(canvas, Offset(-bw * 0.25, -legH + bob * 0.4), legH,
        math.sin(walk + math.pi) * 0.42, far, s);
    _paintLeg(canvas, Offset(bw * 0.23, -legH + bob * 0.4), legH,
        math.sin(walk) * 0.42, far, s);

    // Хвост за телом (виляет на ходу).
    _paintTail(canvas, Offset(-bw * 0.46, bodyC.dy), bw, bh, st, body, s,
        wagging: true);

    // Ближняя пара лап.
    _paintLeg(canvas, Offset(-bw * 0.33, -legH + bob * 0.4), legH,
        math.sin(walk) * 0.42, body, s);
    _paintLeg(canvas, Offset(bw * 0.31, -legH + bob * 0.4), legH,
        math.sin(walk + math.pi) * 0.42, body, s);

    // Тело и животик.
    canvas.drawOval(
      Rect.fromCenter(center: bodyC, width: bw, height: bh),
      Paint()..color = body,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(0, bh * 0.2),
        width: bw * 0.58,
        height: bh * 0.48,
      ),
      Paint()..color = belly,
    );
    _paintBackDetails(canvas, bodyC, bw, bh, st, body, s,
        stage: pet.stage);

    // Шея и голова.
    final Offset headC =
        Offset(bw * 0.40, bodyC.dy - bh * (0.14 + st.neck));
    if (st.extra == 'mane') {
      _paintMane(canvas, bodyC, headC, bw, bh, s);
    }
    if (st.neck > 0.16) {
      canvas.drawLine(
        Offset(bw * 0.30, bodyC.dy - bh * 0.16),
        headC + Offset(-hr * 0.1, hr * 0.5),
        Paint()
          ..color = body
          ..strokeWidth = bh * 0.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(headC, hr, Paint()..color = body);
    _paintEarsOnHead(canvas, headC, hr, st, body, belly, s);
    _paintHeadDetails(canvas, headC, hr, st, body, belly, s);
    _paintFaceOnHead(canvas, headC, hr, st, pet.type, belly, s, closed: false);
    _paintHat(canvas, headC, hr, pet, s);
    _paintNeckwear(canvas, headC, hr, pet, s);
    _paintGlasses(canvas, headC, hr, pet, s, hidden: false);
    canvas.restore();
  }

  // ── Птица: две лапы, вертикальное тело, голова сверху ───────────────
  void _paintBird(Canvas canvas, Offset base, Pet pet, SpeciesStyle st,
      Color body, Color belly, double facing) {
    final double s = 0.55 + pet.stage * 0.22;
    final double bw = 40 * s;
    final double bh = 56 * s * st.bodyLen;
    final double legH = 16 * s;
    final double hr = 14.5 * s * st.headScale;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(facing, 1);

    final double walk = phase * 2 * math.pi;
    if (!sleeping) {
      canvas.rotate(math.sin(walk) * 0.05); // переваливающаяся походка
    }

    final double sit = sleeping ? legH * 0.35 : legH;
    final Offset bodyC = Offset(0, -sit - bh * 0.46);

    // Лапки-палочки (шагают вразнобой).
    final Color far = Color.alphaBlend(body.withOpacity(0.72), Colors.black26);
    final Paint legPaint = Paint()
      ..color = sleeping ? far : const Color(0xFFE8A13D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2 * s
      ..strokeCap = StrokeCap.round;
    for (final double off in <double>[0, math.pi]) {
      final double sx = off == 0 ? -bw * 0.14 : bw * 0.14;
      final double swing =
          sleeping ? 0 : math.sin(walk + off) * 0.3;
      canvas.save();
      canvas.translate(sx, -sit);
      canvas.rotate(swing);
      canvas.drawLine(Offset(0, 0), Offset(0, sit), legPaint);
      canvas.drawLine(
          Offset(0, sit), Offset(5 * s, sit + 1), legPaint);
      canvas.restore();
    }

    // Хвост-веер сзади-снизу.
    final Path tail = Path()
      ..moveTo(-bw * 0.30, bodyC.dy + bh * 0.30)
      ..lineTo(-bw * 0.78, bodyC.dy + bh * 0.44)
      ..lineTo(-bw * 0.32, bodyC.dy + bh * 0.52)
      ..close();
    canvas.drawPath(tail, Paint()..color = Color.alphaBlend(body.withOpacity(0.85), Colors.black12));

    // Тело и животик.
    canvas.drawOval(
      Rect.fromCenter(center: bodyC, width: bw, height: bh),
      Paint()..color = body,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(bw * 0.08, bh * 0.16),
        width: bw * 0.58,
        height: bh * 0.5,
      ),
      Paint()..color = belly,
    );

    // Крылышко.
    final Paint wing = Paint()..color = Color.alphaBlend(body.withOpacity(0.8), Colors.black12);
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(-bw * 0.12, -bh * 0.02),
        width: bw * 0.42,
        height: bh * 0.46,
      ),
      wing,
    );

    // Голова.
    final Offset headC = Offset(bw * 0.06, bodyC.dy - bh * 0.5 - hr * 0.62);
    canvas.drawCircle(headC, hr, Paint()..color = body);
    _paintEarsOnHead(canvas, headC, hr, st, body, belly, s);
    _paintHeadDetails(canvas, headC, hr, st, body, belly, s);
    _paintFaceOnHead(canvas, headC, hr, st, pet.type, belly, s,
        closed: sleeping);
    _paintHat(canvas, headC, hr, pet, s);
    _paintNeckwear(
        canvas, headC, hr, pet, s,
        anchor: Offset(bw * 0.04, bodyC.dy - bh * 0.42));
    _paintGlasses(canvas, headC, hr, pet, s, hidden: sleeping);
    canvas.restore();
  }

  // ── Прыгун: зайчик и лягушонок ──────────────────────────────────────
  void _paintHop(Canvas canvas, Offset base, Pet pet, SpeciesStyle st,
      Color body, Color belly, double facing) {
    final double s = 0.55 + pet.stage * 0.22;
    final double bw = 58 * s * st.bodyLen;
    final double bh = 46 * s;

    // Прыжок с паузой: 40% цикла в воздухе.
    double jump = 0;
    if (!sleeping) {
      final double t = (phase * 1.6 + pet.id.hashCode.abs() % 100 / 400) % 1.0;
      if (t < 0.4) jump = -24 * s * math.sin(math.pi * t / 0.4);
    }

    canvas.save();
    canvas.translate(base.dx, base.dy + jump * 0);
    canvas.scale(facing, 1);
    canvas.translate(0, jump);

    final Offset bodyC = Offset(0, -bh * 0.5 - 4 * s);

    // Задние лапки-пружинки (у зайца) / сложенные лапы (у лягушки).
    final Paint hind = Paint()..color = Color.alphaBlend(body.withOpacity(0.88), Colors.black15);
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
    // Передние лапки.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bw * 0.34, -3 * s),
        width: bw * 0.16,
        height: bh * 0.14,
      ),
      Paint()..color = body,
    );

    if (pet.type == PetType.bunny) {
      _paintTail(canvas, Offset(-bw * 0.5, bodyC.dy + bh * 0.1), bw, bh, st,
          body, s,
          wagging: false);
    }

    // Тело и животик.
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

    final double hr = bh * 0.42;
    if (st.muzzle == 'topEyes') {
      // Лягушонок: глаза-фонарики на макушке + широкая улыбка.
      final double eyeY = bodyC.dy - bh * 0.5;
      for (final double sx in <double>[-0.22, 0.22]) {
        canvas.drawCircle(Offset(bw * sx, eyeY), hr * 0.42,
            Paint()..color = body);
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
    } else {
      // Зайчик: голова спереди-сверху, длинные уши, зубки.
      final Offset headC = Offset(bw * 0.40, bodyC.dy - bh * 0.38);
      canvas.drawCircle(headC, hr, Paint()..color = body);
      _paintEarsOnHead(canvas, headC, hr, st, body, belly, s);
      _paintHeadDetails(canvas, headC, hr, st, body, belly, s);
      _paintFaceOnHead(canvas, headC, hr, st, pet.type, belly, s,
          closed: sleeping);
      _paintHat(canvas, headC, hr, pet, s);
      _paintNeckwear(canvas, headC, hr, pet, s,
          anchor: Offset(bw * 0.34, bodyC.dy - bh * 0.1));
      _paintGlasses(canvas, headC, hr, pet, s, hidden: sleeping);
    }
    canvas.restore();
  }

  // ── Лапа с походкой ─────────────────────────────────────────────────
  void _paintLeg(
      Canvas canvas, Offset hip, double legH, double swing, Color color, double s) {
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(swing);
    final double legW = 10.5 * s;
    final Rect r = Rect.fromLTWH(-legW / 2, -2, legW, legH + 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(legW * 0.5)),
      Paint()..color = color,
    );
    // Ступня-лапка с пальцами.
    final Offset foot = Offset(0, legH);
    canvas.drawOval(
      Rect.fromCenter(
          center: foot, width: legW * 1.55, height: legW * 0.95),
      Paint()..color = color,
    );
    final Paint toe = Paint()..color = Colors.white.withOpacity(0.3);
    for (int t = -1; t <= 1; t++) {
      canvas.drawCircle(
        Offset(foot.dx + t * legW * 0.42, foot.dy + legW * 0.12),
        legW * 0.14,
        toe,
      );
    }
    canvas.restore();
  }

  // ── Хвосты ──────────────────────────────────────────────────────────
  void _paintTail(Canvas canvas, Offset anchor, double bw, double bh,
      SpeciesStyle st, Color body, double s,
      {required bool wagging}) {
    final double wag = wagging ? math.sin(phase * 2 * math.pi * 2) * 0.18 : 0;
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(wag);
    switch (st.tail) {
      case 'bushy':
        // Пышный хвост с белым кончиком (лиса, собака, белка).
        final Path tail = Path()
          ..moveTo(0, bh * 0.18)
          ..quadraticBezierTo(-bw * 0.42, bh * 0.10, -bw * 0.34, -bh * 0.42)
          ..quadraticBezierTo(-bw * 0.12, -bh * 0.12, 0, bh * 0.18)
          ..close();
        canvas.drawPath(tail, Paint()..color = body);
        final Path tip = Path()
          ..moveTo(-bw * 0.315, -bh * 0.30)
          ..quadraticBezierTo(-bw * 0.36, -bh * 0.42, -bw * 0.34, -bh * 0.42)
          ..quadraticBezierTo(-bw * 0.2, -bh * 0.24, -bw * 0.16, -bh * 0.14)
          ..quadraticBezierTo(-bw * 0.26, -bh * 0.16, -bw * 0.315, -bh * 0.30)
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
          ..quadraticBezierTo(-bw * 0.3, bh * 0.26, -bw * 0.3, -bh * 0.2);
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

  // ── Морда на голове ─────────────────────────────────────────────────
  void _paintFaceOnHead(Canvas canvas, Offset headC, double hr,
      SpeciesStyle st, PetType type, Color belly, double s,
      {required bool closed}) {
    final double eyeY = headC.dy - hr * 0.06;
    final double eyeDX = hr * 0.38;
    final bool blink =
        !closed && ((phase * 3) % 1.0) < 0.08;

    if (blink || closed) {
      final Paint lash = Paint()
        ..color = const Color(0xFF4A3B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(headC.dx - eyeDX - hr * 0.2, eyeY),
          Offset(headC.dx - eyeDX + hr * 0.2, eyeY), lash);
      canvas.drawLine(Offset(headC.dx + eyeDX - hr * 0.2, eyeY),
          Offset(headC.dx + eyeDX + hr * 0.2, eyeY), lash);
    } else {
      final Paint white = Paint()..color = Colors.white;
      final Paint pupil = Paint()..color = const Color(0xFF33261A);
      canvas.drawCircle(
          Offset(headC.dx - eyeDX, eyeY), hr * 0.3, white);
      canvas.drawCircle(
          Offset(headC.dx + eyeDX, eyeY), hr * 0.3, white);
      canvas.drawCircle(Offset(headC.dx - eyeDX + hr * 0.08, eyeY + hr * 0.05),
          hr * 0.15, pupil);
      canvas.drawCircle(Offset(headC.dx + eyeDX + hr * 0.08, eyeY + hr * 0.05),
          hr * 0.15, pupil);
      canvas.drawCircle(Offset(headC.dx - eyeDX + hr * 0.14, eyeY - hr * 0.08),
          hr * 0.05, white);
      canvas.drawCircle(Offset(headC.dx + eyeDX + hr * 0.14, eyeY - hr * 0.08),
          hr * 0.05, white);
    }

    // Румянец.
    final Paint blush = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.5);
    canvas.drawCircle(headC + Offset(-hr * 0.72, hr * 0.3), hr * 0.2, blush);
    canvas.drawCircle(headC + Offset(hr * 0.05, hr * 0.42), hr * 0.18, blush);

    final Paint ink = Paint()
      ..color = const Color(0xFF4A3B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    switch (st.muzzle) {
      case 'beak':
        canvas.drawPath(
          Path()
            ..moveTo(headC.dx + hr * 0.35, headC.dy)
            ..lineTo(headC.dx + hr * 0.35, headC.dy + hr * 0.12)
            ..lineTo(headC.dx + hr * 0.95, headC.dy + hr * 0.06)
            ..close(),
          Paint()..color = kBeakOrange,
        );
        break;
      case 'duckBeak':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: headC + Offset(hr * 0.62, hr * 0.14),
              width: hr * 0.95,
              height: hr * 0.4,
            ),
            Radius.circular(4 * s),
          ),
          Paint()..color = kBeakOrange,
        );
        break;
      case 'bearMuzzle':
        canvas.drawOval(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.34, hr * 0.3),
            width: hr * 0.95,
            height: hr * 0.66,
          ),
          Paint()..color = belly,
        );
        canvas.drawCircle(headC + Offset(hr * 0.42, hr * 0.16), hr * 0.13,
            Paint()..color = kInk);
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.42, hr * 0.38),
            width: hr * 0.5,
            height: hr * 0.4,
          ),
          0.3,
          2.4,
          false,
          ink,
        );
        break;
      case 'buckteeth':
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.4, hr * 0.22),
            width: hr * 0.62,
            height: hr * 0.46,
          ),
          0.3,
          2.4,
          false,
          ink,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(headC.dx + hr * 0.26, headC.dy + hr * 0.3,
                hr * 0.16, hr * 0.24),
            const Radius.circular(1.6),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(headC.dx + hr * 0.46, headC.dy + hr * 0.3,
                hr * 0.16, hr * 0.24),
            const Radius.circular(1.6),
          ),
          Paint()..color = Colors.white,
        );
        break;
      case 'snout':
        canvas.drawOval(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.58, hr * 0.12),
            width: hr * 0.6,
            height: hr * 0.46,
          ),
          Paint()..color = const Color(0xFFE88AA0),
        );
        canvas.drawCircle(headC + Offset(hr * 0.5, hr * 0.12), hr * 0.07,
            Paint()..color = kInk);
        canvas.drawCircle(headC + Offset(hr * 0.68, hr * 0.12), hr * 0.07,
            Paint()..color = kInk);
        break;
      case 'topEyes':
        break; // лягушонок обрабатывается в _paintHop
      default:
        // Добрая улыбка с носиком-точкой.
        canvas.drawCircle(headC + Offset(hr * 0.52, hr * 0.1), hr * 0.1,
            Paint()..color = kInk);
        canvas.drawArc(
          Rect.fromCenter(
            center: headC + Offset(hr * 0.42, hr * 0.26),
            width: hr * 0.56,
            height: hr * 0.4,
          ),
          0.3,
          2.4,
          false,
          ink,
        );
        break;
    }

    // Усики тюленя (если вдруг в пруду рисуем морду на голове).
    if (type == PetType.seal) {
      final Paint whisk = Paint()
        ..color = const Color(0xFF7A8896)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (final double sy in <double>[-0.04, 0.1]) {
        canvas.drawLine(
          headC + Offset(hr * 0.4, hr * sy),
          headC + Offset(hr * 1.05, hr * (sy - 0.06)),
          whisk,
        );
      }
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
      oldDelegate.pets.length != pets.length ||
      oldDelegate.sleeping != sleeping ||
      oldDelegate.weather != weather ||
      oldDelegate.frame != frame;
}
