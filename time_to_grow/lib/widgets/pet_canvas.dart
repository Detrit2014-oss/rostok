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

  // v1.3.0: цвета растений
  static const Color _cactusC = Color(0xFF4FA850);
  static const Color _sunflowerC = Color(0xFFFFB800);
  static const Color _cloverC = Color(0xFF4CB944);
  static const Color _bonsaiC = Color(0xFF6B9E4A);
  static const Color _fernC = Color(0xFF2F8F5B);
  static const Color _tulipC = Color(0xFFFF6B6B);

  static const Color _potC = Color(0xFFD97941);
  static const Color _potDarkC = Color(0xFFB85F36);
  static const Color _potLightC = Color(0xFFEB9A66);
  static const Color _soilC = Color(0xFF6B4A2E);
  static const Color _leafC = Color(0xFF57B85C);
  static const Color _trunkC = Color(0xFF8B5E34);

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
      case PetType.cactus:
        return _cactusC;
      case PetType.sunflower:
        return _sunflowerC;
      case PetType.clover:
        return _cloverC;
      case PetType.bonsai:
        return _bonsaiC;
      case PetType.fern:
        return _fernC;
      case PetType.tulip:
        return _tulipC;
    }
  }

  // ── Анатомия v2: мультяшная, но узнаваемая ──────────────────────────
  // Портировано 1:1 из src/components/ttg/scene.tsx (веб-демо):
  // у каждого вида есть голова, туловище, лапы, хвост/крылья/колючки и
  // своя морда. Координаты — для масштаба 1 (лапы на y = 0, вверх —
  // отрицательно); вид масштабируется целиком через canvas.scale().

  /// Особый цвет животика: у пингвинёнка и панды он белый.
  Color _bellyColor(PetType type, Color body) {
    if (type == PetType.penguin || type == PetType.panda) {
      return const Color(0xFFFDFBF5);
    }
    return Color.alphaBlend(body.withOpacity(0.35), Colors.white);
  }

  /// Смешивает цвет к белому (f > 0) или к чёрному (f < 0).
  Color _shade(Color c, double f) {
    int m(int v) =>
        (f >= 0 ? v + (255 - v) * f : v * (1 + f)).round().clamp(0, 255);
    return Color.fromARGB(c.alpha, m(c.red), m(c.green), m(c.blue));
  }

  void _oval(Canvas canvas, double cx, double cy, double rx, double ry,
      Paint p) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      p,
    );
  }

  /// Большие выразительные глаза: белок, зрачок, блик; во сне — дуги.
  void _eyes(Canvas canvas, double dx, double y, double r, bool closed) {
    if (closed) {
      final Paint arc = Paint()
        ..color = const Color(0xFF33261A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round;
      final Path l = Path()
        ..moveTo(-dx - r * 0.5, y)
        ..quadraticBezierTo(-dx, y + r * 0.7, -dx + r * 0.5, y);
      final Path rr = Path()
        ..moveTo(dx - r * 0.5, y)
        ..quadraticBezierTo(dx, y + r * 0.7, dx + r * 0.5, y);
      canvas.drawPath(l, arc);
      canvas.drawPath(rr, arc);
      return;
    }
    final Paint white = Paint()..color = Colors.white;
    final Paint pupil = Paint()..color = const Color(0xFF33261A);
    canvas.drawCircle(Offset(-dx, y), r, white);
    canvas.drawCircle(Offset(dx, y), r, white);
    canvas.drawCircle(Offset(-dx + 1.1, y + 0.9), r * 0.52, pupil);
    canvas.drawCircle(Offset(dx + 1.1, y + 0.9), r * 0.52, pupil);
    canvas.drawCircle(Offset(-dx + 2, y - r * 0.32), r * 0.17, white);
    canvas.drawCircle(Offset(dx + 2, y - r * 0.32), r * 0.17, white);
  }

  void _blush(Canvas canvas, double dx, double y, double r, double opacity) {
    final Paint p = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(opacity);
    canvas.drawCircle(Offset(-dx, y), r, p);
    canvas.drawCircle(Offset(dx, y), r, p);
  }

  /// Треугольник с обводкой того же цвета — скругляет углы (как в SVG).
  void _ear(Canvas canvas, Offset a, Offset b, Offset c, Color color, double w) {
    final Path p = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// «w-улыбка»: вертикальная черта + две дуги вниз.
  void _mouth(Canvas canvas, double x, double y, double w) {
    final Paint p = Paint()
      ..color = const Color(0xFF4A3B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final Path path = Path()
      ..moveTo(x, y)
      ..lineTo(x, y + 2.8)
      ..moveTo(x, y + 2.8)
      ..quadraticBezierTo(x - 3.2, y + 5.6, x - 5.8, y + 3.4)
      ..moveTo(x, y + 2.8)
      ..quadraticBezierTo(x + 3.2, y + 5.6, x + 5.8, y + 3.4);
    canvas.drawPath(path, p);
  }

  void _paintRotatedOval(
      Canvas canvas, double cx, double cy, double rx, double ry, double deg,
      {required Paint paint}) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(deg * math.pi / 180);
    _oval(canvas, 0, 0, rx, ry, paint);
    canvas.restore();
  }

  void _paintPet(Canvas canvas, Offset base, Pet pet, int index) {
    final Color body = _bodyColor(pet.type);
    final PetType type = pet.type;
    final double scale = 0.55 + pet.stage * 0.22;

    if (pet.stage == 0) {
      // v1.3.0: растения растут из семечка в горшочке — это логично,
      // а не из яйца, как у зверят.
      if (type.isPlant) {
        _paintSeed(canvas, base, pet.stageProgress);
      } else {
        _paintEgg(canvas, base, body, pet.stageProgress);
      }
      return;
    }

    // Глаза: спят во время сессии, иначе иногда моргают.
    final bool closed = sleeping || ((phase * 3) % 1.0) < 0.1;

    canvas.save();
    canvas.translate(base.dx, base.dy);

    // Мягкая тень на траве
    _oval(
      canvas,
      0,
      0.5,
      26,
      4.6,
      Paint()..color = const Color(0xFF3E6B22).withOpacity(0.16),
    );

    canvas.scale(scale * (type.isPlant ? 1.35 : 1.0));
    if (type.isPlant) {
      // Горшок стоит на месте, «крона» плавно качается.
      _paintPot(canvas);
      if (!sleeping) {
        canvas.save();
        canvas.rotate(math.sin(phase * 2 * math.pi) * 0.038);
      }
      switch (type) {
        case PetType.cactus:
          _paintCactus(canvas, pet.stage, closed);
          break;
        case PetType.sunflower:
          _paintSunflower(canvas, pet.stage, closed);
          break;
        case PetType.clover:
          _paintClover(canvas, pet.stage, closed);
          break;
        case PetType.bonsai:
          _paintBonsai(canvas, pet.stage, closed);
          break;
        case PetType.fern:
          _paintFern(canvas, pet.stage, closed);
          break;
        case PetType.tulip:
          _paintTulip(canvas, pet.stage, closed);
          break;
        default:
          break;
      }
      if (!sleeping) {
        canvas.restore();
      }
    } else {
      switch (type) {
        case PetType.fox:
          _paintFox(canvas, closed);
          break;
        case PetType.cat:
          _paintCat(canvas, closed);
          break;
        case PetType.owl:
          _paintOwl(canvas, closed);
          break;
        case PetType.dragon:
          _paintDragon(canvas, closed);
          break;
        case PetType.duck:
          _paintDuck(canvas, closed);
          break;
        case PetType.bunny:
          _paintBunny(canvas, closed);
          break;
        case PetType.penguin:
          _paintPenguin(canvas, closed);
          break;
        case PetType.hedgehog:
          _paintHedgehog(canvas, closed);
          break;
        case PetType.panda:
          _paintPanda(canvas, closed);
          break;
        case PetType.bear:
          _paintBear(canvas, closed);
          break;
        default:
          break;
      }
    }
    canvas.restore();

    // zzz над спящим активным питомцем
    if (sleeping && index == pets.length - 1) {
      _paintZzz(
          canvas, Offset(base.dx + 34 * scale, base.dy - 58 * scale), scale);
    }
  }

  /// ЛИСЁНОК: острая морда с носом, большие уши, пышный хвост с белым кончиком.
  void _paintFox(Canvas canvas, bool closed) {
    final Color body = _fox;
    final Color cream = const Color(0xFFFFF6EA);
    final Color dark = _shade(body, -0.16);
    final Paint pb = Paint()..color = body;
    final Paint pc = Paint()..color = cream;
    final Paint pd = Paint()..color = dark;
    // Хвост — пышный, набок, с кремовым кончиком
    _paintRotatedOval(canvas, 27, -32, 11.5, 18, 38, paint: pb);
    canvas.drawCircle(const Offset(37, -46), 6.5, pc);
    // Тело + грудка
    _oval(canvas, 0, -17, 17, 14, pb);
    _oval(canvas, 0, -13, 9.5, 10, pc);
    // Лапы
    _oval(canvas, -8.5, -3.2, 5.6, 4.2, pd);
    _oval(canvas, 8.5, -3.2, 5.6, 4.2, pd);
    // Бакенбарды-шерсть по бокам головы
    canvas.drawPath(
        Path()
          ..moveTo(-21, -40)
          ..lineTo(-30, -33)
          ..lineTo(-19, -30)
          ..close(),
        pc);
    canvas.drawPath(
        Path()
          ..moveTo(21, -40)
          ..lineTo(30, -33)
          ..lineTo(19, -30)
          ..close(),
        pc);
    // Голова
    _oval(canvas, 0, -46, 23, 19.5, pb);
    // Уши: треугольные, с розовой серединкой
    _ear(canvas, const Offset(-18, -57), const Offset(-27, -79),
        const Offset(-5, -66), body, 3);
    _ear(canvas, const Offset(18, -57), const Offset(27, -79),
        const Offset(5, -66), body, 3);
    final Paint earIn = Paint()..color = const Color(0xFFE8938F);
    canvas.drawPath(
        Path()
          ..moveTo(-17, -60)
          ..lineTo(-22.5, -73.5)
          ..lineTo(-9.5, -65.5)
          ..close(),
        earIn);
    canvas.drawPath(
        Path()
          ..moveTo(17, -60)
          ..lineTo(22.5, -73.5)
          ..lineTo(9.5, -65.5)
          ..close(),
        earIn);
    // Морда: кремовый клин, чёрный нос, улыбка
    canvas.drawPath(
        Path()
          ..moveTo(-10.5, -46)
          ..quadraticBezierTo(0, -51, 10.5, -46)
          ..quadraticBezierTo(9, -34.5, 0, -32.5)
          ..quadraticBezierTo(-9, -34.5, -10.5, -46)
          ..close(),
        pc);
    canvas.drawPath(
        Path()
          ..moveTo(-3.2, -44.2)
          ..quadraticBezierTo(0, -46.4, 3.2, -44.2)
          ..quadraticBezierTo(2, -41.4, 0, -41.4)
          ..quadraticBezierTo(-2, -41.4, -3.2, -44.2)
          ..close(),
        Paint()..color = _dark);
    _mouth(canvas, 0, -41.4, 1.9);
    _blush(canvas, 17, -44, 4, 0.45);
    _eyes(canvas, 9.5, -50, 6.2, closed);
  }

  /// КОТИК: треугольные уши, полоски на лбу, усы, хвост трубой.
  void _paintCat(Canvas canvas, bool closed) {
    final Color body = _cat;
    final Color cream = const Color(0xFFF6FAFD);
    final Color dark = _shade(body, -0.2);
    final Paint pb = Paint()..color = body;
    final Paint pc = Paint()..color = cream;
    final Paint pd = Paint()..color = dark;
    // Хвост — изогнут вверх, с тёмным кончиком
    canvas.drawPath(
        Path()
          ..moveTo(11, -14)
          ..quadraticBezierTo(31, -16, 28.5, -38)
          ..quadraticBezierTo(27.5, -47, 20, -49),
        Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(20, -49), 3.8, pd);
    // Тело
    _oval(canvas, 0, -16, 16, 13.5, pb);
    _oval(canvas, 0, -12.5, 8.5, 9, pc);
    // Лапы
    _oval(canvas, -7.5, -3, 5.4, 4, pd);
    _oval(canvas, 7.5, -3, 5.4, 4, pd);
    // Голова
    _oval(canvas, 0, -44, 21, 18, pb);
    // Уши — со скруглением, розовая серединка
    _ear(canvas, const Offset(-18.5, -52), const Offset(-23, -70),
        const Offset(-6.5, -60), body, 3.4);
    _ear(canvas, const Offset(18.5, -52), const Offset(23, -70),
        const Offset(6.5, -60), body, 3.4);
    final Paint earIn = Paint()..color = const Color(0xFFF0A8B8);
    canvas.drawPath(
        Path()
          ..moveTo(-17.5, -55)
          ..lineTo(-20, -65)
          ..lineTo(-10.5, -59.5)
          ..close(),
        earIn);
    canvas.drawPath(
        Path()
          ..moveTo(17.5, -55)
          ..lineTo(20, -65)
          ..lineTo(10.5, -59.5)
          ..close(),
        earIn);
    // Полоски на лбу
    final Paint stripes = Paint()..color = dark.withOpacity(0.75);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-8.6, -62.5, 3.6, 7.5),
            const Radius.circular(1.8)),
        stripes);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-1.8, -64, 3.6, 8.5),
            const Radius.circular(1.8)),
        stripes);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, -62.5, 3.6, 7.5),
            const Radius.circular(1.8)),
        stripes);
    // Нос, улыбка, усы
    canvas.drawPath(
        Path()
          ..moveTo(-2.9, -40.6)
          ..quadraticBezierTo(0, -42.6, 2.9, -40.6)
          ..quadraticBezierTo(1.9, -38.2, 0, -38.2)
          ..quadraticBezierTo(-1.9, -38.2, -2.9, -40.6)
          ..close(),
        Paint()..color = const Color(0xFFE58FA2));
    _mouth(canvas, 0, -38.2, 1.8);
    final Paint whisk = Paint()
      ..color = const Color(0xFF5F7182)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(16, -39.5)
          ..lineTo(25.5, -41)
          ..moveTo(16, -36.8)
          ..lineTo(25, -35.2)
          ..moveTo(-16, -39.5)
          ..lineTo(-25.5, -41)
          ..moveTo(-16, -36.8)
          ..lineTo(-25, -35.2),
        whisk);
    _blush(canvas, 15, -42, 3.6, 0.45);
    _eyes(canvas, 8.5, -46.5, 6, closed);
  }

  /// СОВЁНОК: лицевой диск, кисточки, перья-дуги на животе, лапки-коготки.
  void _paintOwl(Canvas canvas, bool closed) {
    final Color body = _owl;
    final Color light = const Color(0xFFEDE3FA);
    final Color dark = _shade(body, -0.15);
    final Paint pb = Paint()..color = body;
    // Кисточки на голове
    _ear(canvas, const Offset(-19, -54), const Offset(-16.5, -71),
        const Offset(-7, -57), body, 3);
    _ear(canvas, const Offset(19, -54), const Offset(16.5, -71),
        const Offset(7, -57), body, 3);
    // Корпус-яйцо
    _oval(canvas, 0, -30, 22, 27, pb);
    // Животик с перьями-дугами
    _oval(canvas, 0, -16, 12.5, 13, Paint()..color = light);
    canvas.drawPath(
        Path()
          ..moveTo(-8, -14)
          ..quadraticBezierTo(-4, -10.5, 0, -14)
          ..quadraticBezierTo(4, -10.5, 8, -14)
          ..moveTo(-8, -8.5)
          ..quadraticBezierTo(-4, -5, 0, -8.5)
          ..quadraticBezierTo(4, -5, 8, -8.5),
        Paint()
          ..color = _shade(body, -0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round);
    // Крылья
    _paintRotatedOval(canvas, -20.5, -19, 6, 11.5, 14, paint: Paint()..color = dark);
    _paintRotatedOval(canvas, 20.5, -19, 6, 11.5, -14, paint: Paint()..color = dark);
    // Лицевой диск: два белых круга + клюв
    canvas.drawCircle(const Offset(-8.5, -44), 10.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(8.5, -44), 10.5, Paint()..color = Colors.white);
    canvas.drawPath(
        Path()
          ..moveTo(-4.6, -36.5)
          ..lineTo(4.6, -36.5)
          ..lineTo(0, -29)
          ..close(),
        Paint()..color = const Color(0xFFFFB703));
    // Лапки-коготки
    final Paint talon = Paint()..color = const Color(0xFFFFB703);
    _oval(canvas, -7, -2.2, 5, 2.8, talon);
    _oval(canvas, 7, -2.2, 5, 2.8, talon);
    _blush(canvas, 15.5, -36, 3.6, 0.4);
    _eyes(canvas, 8.5, -44, 4.9, closed);
  }

  /// ДРАКОНЧИК: крылья, рога, морда с ноздрями, брюшные пластинки, хвост-стрела.
  void _paintDragon(Canvas canvas, bool closed) {
    final Color body = _dragon;
    final Color light = const Color(0xFFD8F3C8);
    final Color dark = _shade(body, -0.22);
    final Paint pb = Paint()..color = body;
    final Paint pd = Paint()..color = dark;
    // Крылья за телом
    canvas.drawPath(
        Path()
          ..moveTo(-13, -36)
          ..quadraticBezierTo(-34, -54, -29, -30)
          ..quadraticBezierTo(-26.5, -19, -13, -23)
          ..close(),
        pd);
    canvas.drawPath(
        Path()
          ..moveTo(13, -36)
          ..quadraticBezierTo(34, -54, 29, -30)
          ..quadraticBezierTo(26.5, -19, 13, -23)
          ..close(),
        pd);
    // Хвост с наконечником-стрелой
    canvas.drawPath(
        Path()
          ..moveTo(11, -13)
          ..quadraticBezierTo(30, -11, 33.5, -28),
        Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.5
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        Path()
          ..moveTo(30.5, -32.5)
          ..lineTo(40.5, -33.5)
          ..lineTo(33.5, -22.5)
          ..close(),
        pd);
    // Тело с брюшными пластинками
    _oval(canvas, 0, -16, 17, 14, pb);
    final Paint plates = Paint()..color = light;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-8.5, -21.5, 17, 4.6),
            const Radius.circular(2.3)),
        plates);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6.8, -15.4, 13.6, 4.4),
            const Radius.circular(2.2)),
        plates);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.6, -9.8, 9.2, 4.2),
            const Radius.circular(2.1)),
        plates);
    // Лапы
    _oval(canvas, -7.5, -3, 5.4, 4, pd);
    _oval(canvas, 7.5, -3, 5.4, 4, pd);
    // Голова + морда с ноздрями
    _oval(canvas, 0, -44, 21, 18, pb);
    _oval(canvas, 0, -36.5, 11, 7, Paint()..color = _shade(body, 0.28));
    canvas.drawCircle(const Offset(-3.6, -37.6), 1.25, Paint()..color = _dark);
    canvas.drawCircle(const Offset(3.6, -37.6), 1.25, Paint()..color = _dark);
    // Рога и шип на лбу
    final Paint horn = Paint()..color = const Color(0xFFF6E7C1);
    canvas.drawPath(
        Path()
          ..moveTo(-12.5, -55.5)
          ..lineTo(-17, -68)
          ..lineTo(-6.5, -58.5)
          ..close(),
        horn);
    canvas.drawPath(
        Path()
          ..moveTo(12.5, -55.5)
          ..lineTo(17, -68)
          ..lineTo(6.5, -58.5)
          ..close(),
        horn);
    canvas.drawPath(
        Path()
          ..moveTo(-3.4, -60.5)
          ..lineTo(-1.2, -67.5)
          ..lineTo(2.6, -60.8)
          ..close(),
        horn);
    _blush(canvas, 16, -42, 3.8, 0.4);
    _eyes(canvas, 9, -47, 6, closed);
  }

  /// УТЁНОК: широкий клюв, хохолок, крылышки, хвостовые пёрышки, лапки-ласты.
  void _paintDuck(Canvas canvas, bool closed) {
    final Color body = _duck;
    final Color dark = _shade(body, -0.12);
    final Paint pb = Paint()..color = body;
    final Paint pd = Paint()..color = dark;
    // Хвостовые пёрышки
    canvas.drawPath(
        Path()
          ..moveTo(-15, -19)
          ..lineTo(-26, -25)
          ..lineTo(-17, -13)
          ..close(),
        pd);
    canvas.drawPath(
        Path()
          ..moveTo(-16, -13)
          ..lineTo(-25, -9.5)
          ..lineTo(-15, -7.5)
          ..close(),
        pd..color = dark.withOpacity(0.85));
    pd.color = dark;
    // Тело + крылышки
    _oval(canvas, 0, -16, 17, 14, pb);
    _paintRotatedOval(canvas, -14.5, -17, 6, 9.5, 22, paint: pd);
    _paintRotatedOval(canvas, 14.5, -17, 6, 9.5, -22, paint: pd);
    // Лапки-ласты
    final Paint feet = Paint()..color = _beakOrange;
    _oval(canvas, -7.5, -2, 6.2, 2.8, feet);
    _oval(canvas, 7.5, -2, 6.2, 2.8, feet);
    // Голова + хохолок
    canvas.drawCircle(const Offset(0, -43), 18.5, pb);
    _oval(canvas, -4, -60.5, 2.7, 2.7, pb);
    _oval(canvas, 0, -62.5, 3, 3, pb);
    _oval(canvas, 4, -60.5, 2.7, 2.7, pb);
    // Клюв
    _oval(canvas, 0, -36.5, 10.5, 5.4, feet);
    canvas.drawPath(
        Path()
          ..moveTo(-7, -33.8)
          ..quadraticBezierTo(0, -30.6, 7, -33.8),
        Paint()
          ..color = _shade(_beakOrange, -0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    _blush(canvas, 14.5, -42, 3.8, 0.45);
    _eyes(canvas, 8.2, -46.5, 6, closed);
  }

  /// ЗАЙЧИК: длинные уши с розовой серединкой, зубки, помпон-хвост.
  void _paintBunny(Canvas canvas, bool closed) {
    final Color body = _bunny;
    final Color cream = const Color(0xFFFDFBF5);
    final Color dark = _shade(body, -0.16);
    final Paint pb = Paint()..color = body;
    final Paint pc = Paint()..color = cream;
    final Paint pd = Paint()..color = dark;
    // Уши — длинные, чуть наклонены, с розовой серединкой
    for (final bool left in <bool>[true, false]) {
      canvas.save();
      canvas.translate(left ? -10 : 10, -70);
      canvas.rotate((left ? -9 : 9) * math.pi / 180);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(left ? -3.7 : -3.9, -18, 7.6, 32),
              const Radius.circular(3.8)),
          pb);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(left ? -1.7 : -1.9, -14.5, 3.9, 25),
              const Radius.circular(1.95)),
          Paint()..color = const Color(0xFFF5B8C4));
      canvas.restore();
    }
    // Хвост-помпон
    canvas.drawCircle(const Offset(13, -14), 5, pc);
    // Тело
    _oval(canvas, 0, -15, 15, 12.5, pb);
    _oval(canvas, 0, -11.5, 8, 8.5, pc);
    // Лапы
    _oval(canvas, -7, -2.8, 5.2, 3.8, pd);
    _oval(canvas, 7, -2.8, 5.2, 3.8, pd);
    // Голова
    _oval(canvas, 0, -44, 20, 17.5, pb);
    // Нос, зубки, улыбка
    canvas.drawPath(
        Path()
          ..moveTo(-2.7, -40.2)
          ..quadraticBezierTo(0, -42.2, 2.7, -40.2)
          ..quadraticBezierTo(1.8, -38, 0, -38)
          ..quadraticBezierTo(-1.8, -38, -2.7, -40.2)
          ..close(),
        Paint()..color = const Color(0xFFE58FA2));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2.3, -37.8, 4.6, 4.4),
            const Radius.circular(1.1)),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2.3, -37.8, 4.6, 4.4),
            const Radius.circular(1.1)),
        Paint()
          ..color = _shade(body, -0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);
    canvas.drawPath(
        Path()
          ..moveTo(-5.5, -38.9)
          ..quadraticBezierTo(-7.5, -37.5, -8.8, -39)
          ..moveTo(5.5, -38.9)
          ..quadraticBezierTo(7.5, -37.5, 8.8, -39),
        Paint()
          ..color = const Color(0xFF4A3B2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    _blush(canvas, 14.5, -41.5, 3.8, 0.45);
    _eyes(canvas, 8.5, -46, 5.8, closed);
  }

  /// ПИНГВИНОНОК: яйцо-тело, белое лицо и живот, ласты, клюв, лапки.
  void _paintPenguin(Canvas canvas, bool closed) {
    final Color body = _penguin;
    final Color white = _bellyColor(PetType.penguin, body);
    final Color dark = _shade(body, -0.14);
    final Paint pb = Paint()..color = body;
    final Paint pw = Paint()..color = white;
    // Тело-яйцо
    _oval(canvas, 0, -25, 20, 26, pb);
    // Белое лицо и живот
    canvas.drawCircle(const Offset(0, -39.5), 11.5, pw);
    _oval(canvas, 0, -19, 13.5, 16, pw);
    // Ласты
    _paintRotatedOval(canvas, -21, -26, 5.5, 12, 16, paint: Paint()..color = dark);
    _paintRotatedOval(canvas, 21, -26, 5.5, 12, -16, paint: Paint()..color = dark);
    // Лапки
    final Paint feet = Paint()..color = _beakOrange;
    _oval(canvas, -7.5, -1.8, 6, 2.8, feet);
    _oval(canvas, 7.5, -1.8, 6, 2.8, feet);
    // Клюв
    canvas.drawPath(
        Path()
          ..moveTo(-4.6, -38.5)
          ..lineTo(4.6, -38.5)
          ..lineTo(0, -31.5)
          ..close(),
        feet);
    _blush(canvas, 10.5, -36, 3.2, 0.4);
    _eyes(canvas, 6.4, -42.5, 4.7, closed);
  }

  /// ЁЖИК: колючий купол с остриями, вытянутая мордочка с носом, ушки.
  void _paintHedgehog(Canvas canvas, bool closed) {
    final Color body = _hedgehog;
    final Color dark = _shade(body, -0.16);
    final Paint pb = Paint()..color = body;
    final Paint pd = Paint()..color = dark;
    final Paint spikes = Paint()..color = _spike;
    // Колючая «причёска»: купол с зигзагом + острые кончики
    canvas.drawPath(
        Path()
          ..moveTo(-24, -44)
          ..quadraticBezierTo(-28, -75, 0, -77)
          ..quadraticBezierTo(28, -75, 24, -44)
          ..lineTo(17, -51)
          ..lineTo(11, -42.5)
          ..lineTo(4.5, -50)
          ..lineTo(0, -42.5)
          ..lineTo(-4.5, -50)
          ..lineTo(-11, -42.5)
          ..lineTo(-17, -51)
          ..close(),
        spikes);
    canvas.drawPath(
        Path()
          ..moveTo(-17, -60)
          ..lineTo(-20, -73)
          ..lineTo(-9, -63)
          ..close(),
        spikes);
    canvas.drawPath(
        Path()
          ..moveTo(17, -60)
          ..lineTo(20, -73)
          ..lineTo(9, -63)
          ..close(),
        spikes);
    canvas.drawPath(
        Path()
          ..moveTo(-5, -63)
          ..lineTo(0, -76)
          ..lineTo(5, -63)
          ..close(),
        spikes);
    // Тело
    _oval(canvas, 0, -13.5, 15, 12, pb);
    // Лапы
    _oval(canvas, -7, -2.8, 5.2, 3.8, pd);
    _oval(canvas, 7, -2.8, 5.2, 3.8, pd);
    // Голова + ушки
    _oval(canvas, 0, -42, 21, 18, pb);
    canvas.drawCircle(
        const Offset(-15, -56.5),
        4.2,
        Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    canvas.drawCircle(
        const Offset(15, -56.5),
        4.2,
        Paint()
          ..color = body
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    // Вытянутая мордочка с носом
    canvas.drawPath(
        Path()
          ..moveTo(-8.5, -38)
          ..quadraticBezierTo(0, -42, 8.5, -38)
          ..quadraticBezierTo(6.5, -28.5, 0, -27.5)
          ..quadraticBezierTo(-6.5, -28.5, -8.5, -38)
          ..close(),
        Paint()..color = _shade(body, 0.32));
    canvas.drawCircle(const Offset(0, -28.5), 3, Paint()..color = _dark);
    canvas.drawPath(
        Path()
          ..moveTo(0, -31.5)
          ..lineTo(0, -33.8)
          ..moveTo(0, -33.8)
          ..quadraticBezierTo(-2.6, -35.6, -4.6, -34.2)
          ..moveTo(0, -33.8)
          ..quadraticBezierTo(2.6, -35.6, 4.6, -34.2),
        Paint()
          ..color = const Color(0xFF4A3B2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    _blush(canvas, 14.5, -40, 3.4, 0.4);
    _eyes(canvas, 8.5, -44.5, 5.4, closed);
  }

  /// ПАНДА: чёрные уши, пятна вокруг глаз, чёрные лапы-обнимашки.
  void _paintPanda(Canvas canvas, bool closed) {
    final Color white = _panda;
    final Paint pw = Paint()..color = white;
    final Paint black = Paint()..color = _dark;
    // Тело + чёрные лапы
    _oval(canvas, 0, -16, 17, 14, pw);
    _paintRotatedOval(canvas, -15.5, -19, 6, 9.5, 18, paint: black);
    _paintRotatedOval(canvas, 15.5, -19, 6, 9.5, -18, paint: black);
    _oval(canvas, -8, -3, 6, 4.2, black);
    _oval(canvas, 8, -3, 6, 4.2, black);
    // Голова + уши
    _oval(canvas, 0, -44, 22, 19, pw);
    canvas.drawCircle(const Offset(-14.5, -58.5), 6.8, black);
    canvas.drawCircle(const Offset(14.5, -58.5), 6.8, black);
    // Пятна вокруг глаз
    _paintRotatedOval(canvas, -9.2, -46, 5.6, 7.2, -16, paint: black);
    _paintRotatedOval(canvas, 9.2, -46, 5.6, 7.2, 16, paint: black);
    if (closed) {
      final Paint arc = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
          Path()
            ..moveTo(-11.5, -46)
            ..quadraticBezierTo(-9.2, -44, -6.9, -46),
          arc);
      canvas.drawPath(
          Path()
            ..moveTo(6.9, -46)
            ..quadraticBezierTo(9.2, -44, 11.5, -46),
          arc);
    } else {
      canvas.drawCircle(const Offset(-9.2, -46.5), 3.7, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(9.2, -46.5), 3.7, Paint()..color = Colors.white);
      canvas.drawCircle(
          const Offset(-8.6, -46.2), 2, Paint()..color = const Color(0xFF33261A));
      canvas.drawCircle(
          const Offset(8.6, -46.2), 2, Paint()..color = const Color(0xFF33261A));
      canvas.drawCircle(const Offset(-8, -47.2), 0.7, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(8, -47.2), 0.7, Paint()..color = Colors.white);
    }
    // Нос и улыбка
    canvas.drawPath(
        Path()
          ..moveTo(-3, -38.4)
          ..quadraticBezierTo(0, -40.4, 3, -38.4)
          ..quadraticBezierTo(2, -36, 0, -36)
          ..quadraticBezierTo(-2, -36, -3, -38.4)
          ..close(),
        black);
    canvas.drawPath(
        Path()
          ..moveTo(0, -36)
          ..lineTo(0, -34.2)
          ..moveTo(0, -34.2)
          ..quadraticBezierTo(-2.6, -31.8, -4.8, -33.6)
          ..moveTo(0, -34.2)
          ..quadraticBezierTo(2.6, -31.8, 4.8, -33.6),
        Paint()
          ..color = const Color(0xFF4A3B2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round);
    _blush(canvas, 16, -39, 3.4, 0.35);
  }

  /// МЕДВЕЖОНОК: круглые уши, морда со светлой серединкой, косолапые лапы.
  void _paintBear(Canvas canvas, bool closed) {
    final Color body = _bear;
    final Color muzzleC = _shade(body, 0.35);
    final Color dark = _shade(body, -0.12);
    final Paint pb = Paint()..color = body;
    final Paint pm = Paint()..color = muzzleC;
    final Paint pd = Paint()..color = dark;
    // Тело + животик
    _oval(canvas, 0, -16.5, 18, 14.5, pb);
    _oval(canvas, 0, -12.5, 10, 9.5, pm);
    // Лапы
    _oval(canvas, -9, -3.2, 6.4, 4.4, pd);
    _oval(canvas, 9, -3.2, 6.4, 4.4, pd);
    // Голова + уши со светлой серединкой
    _oval(canvas, 0, -44, 22, 19, pb);
    canvas.drawCircle(const Offset(-14, -58.5), 7, pb);
    canvas.drawCircle(const Offset(14, -58.5), 7, pb);
    canvas.drawCircle(const Offset(-14, -58.5), 3.4, pm);
    canvas.drawCircle(const Offset(14, -58.5), 3.4, pm);
    // Морда
    _oval(canvas, 0, -36.5, 10, 7.4, pm);
    _oval(canvas, 0, -39.4, 3.3, 2.5, Paint()..color = _dark);
    _mouth(canvas, 0, -37, 1.8);
    _blush(canvas, 16.5, -42, 3.8, 0.4);
    _eyes(canvas, 9.2, -48, 5.8, closed);
  }


  // ── Растения v1.3.0: семечко → росток → кустик → цветение ───────────
  // Портировано 1:1 из src/components/ttg/scene.tsx (веб-демо).
  // Горшок общий, у каждого вида своя «крона» и лицо.

  Paint _strokeP(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  /// Дуга-улыбка растений (проще, чем «двойная улыбка» зверят).
  void _smileArc(Canvas canvas, double y, double w) {
    final Path path = Path()
      ..moveTo(-w, y)
      ..quadraticBezierTo(0, y + w * 0.9, w, y);
    canvas.drawPath(path, _strokeP(const Color(0xFF4A3B2A), 1.7));
  }

  /// Лист-сердечко (клевер): черешок в точке (x, y).
  void _heartLeaf(Canvas canvas, double x, double y, double rotDeg, double s) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotDeg * math.pi / 180);
    canvas.scale(s);
    final Path heart = Path()
      ..moveTo(0, 0)
      ..cubicTo(-6.5, -2.5, -9, -9.5, -3.5, -11.5)
      ..cubicTo(-1.2, -12.3, 0, -10.8, 0, -9.5)
      ..cubicTo(0, -10.8, 1.2, -12.3, 3.5, -11.5)
      ..cubicTo(9, -9.5, 6.5, -2.5, 0, 0)
      ..close();
    canvas.drawPath(heart, Paint()..color = _leafC);
    canvas.drawLine(
        const Offset(0, -1.5),
        const Offset(0, -8.5),
        _strokeP(_shade(_leafC, -0.18), 1));
    canvas.restore();
  }

  /// Терракотовый горшок с землёй — общий для всех растений.
  void _paintPot(Canvas canvas) {
    final Path pot = Path()
      ..moveTo(-14.5, -14)
      ..lineTo(14.5, -14)
      ..lineTo(11.5, 0)
      ..quadraticBezierTo(0, 2.4, -11.5, 0)
      ..close();
    canvas.drawPath(pot, Paint()..color = _potC);
    canvas.drawLine(const Offset(-10, -11.5), const Offset(-7.5, -2),
        _strokeP(_potLightC, 2.4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-17, -22.5, 34, 9), const Radius.circular(3)),
      Paint()..color = _potDarkC,
    );
    _oval(canvas, 0, -16.5, 12.6, 3.4, Paint()..color = _soilC);
  }

  /// Стадия 0 у растений — семечко в горшочке: земля трескается,
  /// петелька ростка выглядывает перед всходом.
  void _paintSeed(Canvas canvas, Offset base, double progress) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(math.sin(phase * 2 * math.pi * 1.6) * 0.021);

    _paintPot(canvas);
    _oval(canvas, 0, -19.5, 7.5, 2.6, Paint()..color = _shade(_soilC, -0.12));

    canvas.save();
    canvas.translate(0, -23);
    canvas.rotate(-14 * math.pi / 180);
    _oval(canvas, 0, 0, 4.4, 6, Paint()..color = const Color(0xFFA9744F));
    _oval(
      canvas,
      -1.2,
      -2,
      1.5,
      2.6,
      Paint()..color = const Color(0xFFC08A5E).withOpacity(0.85),
    );
    canvas.restore();

    if (progress > 0.5) {
      final Path crack = Path()
        ..moveTo(-6, -18.4)
        ..lineTo(-2.5, -17.6)
        ..lineTo(1.5, -18.6)
        ..lineTo(5.5, -17.8);
      canvas.drawPath(crack, _strokeP(_shade(_soilC, -0.3), 1.4));
    }
    if (progress > 0.8) {
      final Path loop = Path()
        ..moveTo(0, -26.5)
        ..quadraticBezierTo(1, -31, 4.6, -28.6);
      canvas.drawPath(loop, _strokeP(_leafC, 2.2));
    }
    canvas.restore();
  }

  /// КАКТУСЁНОК: ствол с рёбрами, ручки-отростки, иголочки, цветок.
  void _paintCactus(Canvas canvas, int stage, bool closed) {
    final Color body = _cactusC;
    final Color ridge = _shade(body, -0.16);
    final double rx = stage == 1 ? 8 : stage == 2 ? 9.5 : 11;
    final double ry = stage == 1 ? 11 : stage == 2 ? 16 : 20.5;
    final double cy = -13 - ry;
    final double faceY = cy + 2;

    if (stage >= 3) {
      final Path arm = Path()
        ..moveTo(rx - 2.5, cy + 5)
        ..quadraticBezierTo(17, cy + 5, 17, cy - 2)
        ..lineTo(17, cy - 7);
      canvas.drawPath(arm, _strokeP(body, 8));
    }
    if (stage >= 2) {
      final Path arm = Path()
        ..moveTo(-(rx - 2.5), cy + 8)
        ..quadraticBezierTo(-16.5, cy + 8, -16.5, cy)
        ..lineTo(-16.5, cy - 6);
      canvas.drawPath(arm, _strokeP(body, 7.5));
    }
    _oval(canvas, 0, cy, rx, ry, Paint()..color = body);
    final Path ribL = Path()
      ..moveTo(-rx * 0.45, cy - ry + 4)
      ..lineTo(-rx * 0.45, -16);
    final Path ribR = Path()
      ..moveTo(rx * 0.45, cy - ry + 4)
      ..lineTo(rx * 0.45, -16);
    final Paint ribP = _strokeP(ridge, 1.5)..color = ridge.withOpacity(0.6);
    canvas.drawPath(ribL, ribP);
    canvas.drawPath(ribR, ribP);

    final Paint needles = _strokeP(Colors.white, 1.3)
      ..color = Colors.white.withOpacity(0.75);
    canvas.drawLine(const Offset(-6.5, -33), const Offset(-4.1, -35.4), needles);
    canvas.drawLine(const Offset(6.5, -29), const Offset(8.9, -31.4), needles);
    canvas.drawLine(const Offset(-6, -21.5), const Offset(-3.6, -23.9), needles);
    if (stage >= 2) {
      canvas.drawLine(const Offset(6.5, -40), const Offset(8.9, -42.4), needles);
    }
    if (stage >= 3) {
      canvas.drawLine(const Offset(-6.5, -45), const Offset(-4.1, -47.4), needles);
      final Paint petal = Paint()..color = const Color(0xFFFFD24C);
      for (final double a in const <double>[0, 72, 144, 216, 288]) {
        final double rad = a * math.pi / 180;
        canvas.drawCircle(
          Offset(7.2 * math.cos(rad), cy - ry - 3 + 7.2 * math.sin(rad)),
          3.4,
          petal,
        );
      }
      canvas.drawCircle(
          Offset(0, cy - ry - 3), 2.6, Paint()..color = const Color(0xFFE8890C));
    }
    _blush(canvas, rx * 0.72, faceY + 4.5, 2.8, 0.4);
    _eyes(canvas, 4.6, faceY, 4.1, closed);
    _smileArc(canvas, faceY + 6.4, 3.4);
  }

  /// ПОДСОЛНУШЕК: стебель, листья с прожилками, бутон → жёлтая головка.
  void _paintSunflower(Canvas canvas, int stage, bool closed) {
    final double stemTop = stage == 1 ? -31 : stage == 2 ? -47 : -50;
    const double petalY = -64;

    final Path stem = Path()
      ..moveTo(0, -17)
      ..quadraticBezierTo(2, (stemTop - 17) / 2, 0, stemTop);
    canvas.drawPath(stem, _strokeP(_leafC, stage == 1 ? 3 : 4.2));

    if (stage >= 2) {
      _paintRotatedOval(canvas, -9.5, -30, 8.5, 4, -18, paint: Paint()..color = _leafC);
      canvas.drawLine(const Offset(-14.5, -31.5), const Offset(-4.5, -28.5),
          _strokeP(_shade(_leafC, -0.2), 1.2));
      _paintRotatedOval(canvas, 9.5, -36, 8.5, 4, 18, paint: Paint()..color = _leafC);
      canvas.drawLine(const Offset(14.5, -37.5), const Offset(4.5, -34.5),
          _strokeP(_shade(_leafC, -0.2), 1.2));
    }

    if (stage == 1) {
      _paintRotatedOval(canvas, -6, -30.5, 5.5, 3, -22, paint: Paint()..color = _leafC);
      _paintRotatedOval(canvas, 6, -30.5, 5.5, 3, 22, paint: Paint()..color = _leafC);
      canvas.drawCircle(const Offset(0, -34.5), 4.4, Paint()..color = const Color(0xFF8FCF7A));
      _eyes(canvas, 2.3, -35.4, 2, closed);
      _smileArc(canvas, -33.2, 1.7);
    } else if (stage == 2) {
      final Path sepal = Path()
        ..moveTo(-6.5, -46.5)
        ..lineTo(0, -50.5)
        ..lineTo(6.5, -46.5)
        ..quadraticBezierTo(0, -43.5, -6.5, -46.5)
        ..close();
      canvas.drawPath(sepal, Paint()..color = _shade(_leafC, -0.05));
      _oval(canvas, 0, -53.5, 7, 8.5, Paint()..color = const Color(0xFF7FB069));
      canvas.drawPath(
          Path()
            ..moveTo(-2.6, -46.8)
            ..quadraticBezierTo(-3.2, -52, -2, -58),
          _strokeP(_shade(const Color(0xFF7FB069), -0.2), 1.3));
      canvas.drawPath(
          Path()
            ..moveTo(2.6, -46.8)
            ..quadraticBezierTo(3.2, -52, 2, -58),
          _strokeP(_shade(const Color(0xFF7FB069), -0.2), 1.3));
      _blush(canvas, 5.2, -50.5, 2.1, 0.4);
      _eyes(canvas, 3.4, -54.2, 2.9, closed);
      _smileArc(canvas, -50.4, 2.5);
    } else {
      for (int i = 0; i < 12; i++) {
        final double rad = i * 30 * math.pi / 180;
        final double px = 15.8 * math.cos(rad);
        final double py = petalY + 15.8 * math.sin(rad);
        _paintRotatedOval(canvas, px, py, 6.6, 3.5, i * 30,
            paint: Paint()..color = const Color(0xFFFFC800));
      }
      canvas.drawCircle(Offset(0, petalY), 10.5, Paint()..color = const Color(0xFF8A5A2B));
      canvas.drawCircle(Offset(0, petalY), 10.5,
          _strokeP(_shade(const Color(0xFF8A5A2B), -0.2), 1.4));
      _blush(canvas, 7.2, petalY + 4.4, 2.7, 0.4);
      _eyes(canvas, 4.4, petalY - 1, 3.9, closed);
      _smileArc(canvas, petalY + 4.4, 3.2);
    }
  }

  /// КЛЕВЕРЧИК: листья-сердечки, на цветении — четыре листа и цветки удачи.
  void _paintClover(Canvas canvas, int stage, bool closed) {
    final Paint stems = _strokeP(_shade(_leafC, -0.1), 1.6);
    if (stage == 1) {
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..quadraticBezierTo(-0.5, -21, -1, -25),
          stems);
    } else {
      canvas.drawPath(
          Path()..moveTo(0, -17)..quadraticBezierTo(-5, -22, -9, -26), stems);
      canvas.drawPath(
          Path()..moveTo(0, -17)..quadraticBezierTo(5, -22, 9, -26), stems);
      canvas.drawPath(
          Path()..moveTo(0, -17)..quadraticBezierTo(-0.5, -26, 0, -32), stems);
      if (stage >= 3) {
        canvas.drawPath(
            Path()..moveTo(0, -17)..quadraticBezierTo(2, -26, 5.5, -39), stems);
      }
    }

    if (stage == 1) {
      _heartLeaf(canvas, -1, -24.5, -8, 1.15);
      _eyes(canvas, 2.7, -30.5, 2.2, closed);
      _smileArc(canvas, -28, 1.9);
    } else if (stage == 2) {
      _heartLeaf(canvas, -9.5, -25.5, -32, 1.05);
      _heartLeaf(canvas, 9.5, -25.5, 32, 1.05);
      _heartLeaf(canvas, 0, -31.5, 0, 1.15);
      _blush(canvas, 5, -29.5, 2, 0.4);
      _eyes(canvas, 3, -31.5, 2.6, closed);
      _smileArc(canvas, -29, 2.2);
    } else {
      _heartLeaf(canvas, -10.5, -26.5, -36, 1.3);
      _heartLeaf(canvas, 10.5, -26.5, 36, 1.3);
      _heartLeaf(canvas, -5.5, -38.5, -10, 1.25);
      _heartLeaf(canvas, 6, -38.5, 10, 1.25);
      final Paint wf = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(-14, -20), 1.7, wf);
      canvas.drawCircle(const Offset(-16.4, -19), 1.7, wf);
      canvas.drawCircle(const Offset(-15.2, -17.6), 1.7, wf);
      canvas.drawCircle(const Offset(14.5, -21.5), 1.7, wf);
      canvas.drawCircle(const Offset(16.9, -20.5), 1.7, wf);
      canvas.drawCircle(const Offset(15.7, -19.1), 1.7, wf);
      canvas.drawCircle(const Offset(-15.2, -18.9), 1.1, Paint()..color = const Color(0xFFFFC800));
      canvas.drawCircle(const Offset(15.7, -20.4), 1.1, Paint()..color = const Color(0xFFFFC800));
      _blush(canvas, 5.6, -31, 2.2, 0.4);
      _eyes(canvas, 3.4, -33, 3, closed);
      _smileArc(canvas, -30.4, 2.5);
    }
  }

  /// БОНСАЙЧИК: изогнутый ствол, облака листвы, мох на земле.
  void _paintBonsai(Canvas canvas, int stage, bool closed) {
    final Color foliage = _bonsaiC;
    final Color cloudDark = _shade(foliage, -0.12);

    if (stage == 1) {
      canvas.drawLine(const Offset(0, -17), const Offset(0, -26), _strokeP(_trunkC, 4));
      _oval(canvas, 0, -31.5, 9, 7, Paint()..color = foliage);
      _blush(canvas, 5.5, -29.5, 1.9, 0.4);
      _eyes(canvas, 3.4, -32.2, 2.7, closed);
      _smileArc(canvas, -29.6, 2.3);
    } else if (stage == 2) {
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(0, -22, -3.5, -25, -3, -30),
          _strokeP(_trunkC, 5));
      canvas.drawPath(
          Path()
            ..moveTo(-1, -26)
            ..quadraticBezierTo(4, -27.5, 6.5, -29.5),
          _strokeP(_trunkC, 3.4));
      _oval(canvas, -4.5, -35.5, 8.5, 6.5, Paint()..color = foliage);
      _oval(canvas, 7, -32, 6.5, 5, Paint()..color = cloudDark);
      _blush(canvas, 0.8, -33.5, 1.9, 0.4);
      _eyes(canvas, -1.2, -36.2, 2.7, closed);
      _smileArc(canvas, -33.6, 2.3);
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(1, -24, -4.5, -28, -2.5, -36),
          _strokeP(_trunkC, 6.5));
      canvas.drawPath(
          Path()
            ..moveTo(-2, -31)
            ..quadraticBezierTo(-8, -32.5, -10.5, -35),
          _strokeP(_trunkC, 3.5));
      canvas.drawPath(
          Path()
            ..moveTo(-2.5, -35)
            ..quadraticBezierTo(4, -37.5, 7, -39),
          _strokeP(_trunkC, 3.5));
      _oval(canvas, -11, -38.5, 7.5, 5.5, Paint()..color = cloudDark);
      _oval(canvas, 10, -41, 7, 5.2, Paint()..color = cloudDark);
      _oval(canvas, 0, -46.5, 12, 9, Paint()..color = foliage);
      final Paint moss = Paint()..color = _leafC.withOpacity(0.85);
      canvas.drawCircle(const Offset(-6, -17.5), 1.7, moss);
      canvas.drawCircle(const Offset(7, -18), 1.5, moss);
      canvas.drawCircle(const Offset(2, -16.8), 1.3, moss);
      _blush(canvas, 7, -44, 2.4, 0.4);
      _eyes(canvas, 4.2, -47, 3.4, closed);
      _smileArc(canvas, -44.2, 2.9);
    }
  }

  /// ПАПОРОТИК: завиток → арки ваи́й с листочками, лицо у основания.
  void _paintFern(Canvas canvas, int stage, bool closed) {
    final Color frond = _fernC;
    final Color tick = _shade(frond, -0.12);

    if (stage == 1) {
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(0, -24, -4.5, -27, -4.5, -23.5)
            ..cubicTo(-4.5, -20.5, -1.2, -21, -0.8, -24),
          _strokeP(frond, 2.6));
      canvas.drawPath(
          Path()..moveTo(1, -17)..quadraticBezierTo(3.5, -22, 3, -26),
          _strokeP(frond, 2));
    } else if (stage == 2) {
      final Paint p = _strokeP(frond, 2.8);
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(-5, -23, -10, -26, -15.5, -26.5),
          p);
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(5, -23, 10, -26, 15.5, -26.5),
          p);
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(-0.5, -25, -1, -30, 0.5, -34),
          _strokeP(frond, 2.4));
    } else {
      final Paint p = _strokeP(frond, 3);
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(-6, -24, -12, -28, -19, -28.5),
          p);
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(6, -24, 12, -28, 19, -28.5),
          p);
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(-4, -27, -6, -34, -5.5, -40),
          _strokeP(frond, 2.6));
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(4, -27, 6, -34, 5.5, -40),
          _strokeP(frond, 2.6));
      canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..cubicTo(0, -26, 0.5, -33, -0.5, -38),
          _strokeP(frond, 2.4));
    }

    final Paint ticks = _strokeP(tick, 1.5);
    void tickLine(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), ticks);

    if (stage == 2) {
      tickLine(-6, -22.5, -5.4, -26.6);
      tickLine(-10.5, -25, -9.4, -28.9);
      tickLine(6, -22.5, 5.4, -26.6);
      tickLine(10.5, -25, 9.4, -28.9);
      tickLine(-1.5, -27, -4, -29.4);
      tickLine(1.5, -27, 4, -29.4);
    } else if (stage >= 3) {
      tickLine(-7, -22.5, -6.3, -27);
      tickLine(-12, -26, -10.7, -30.6);
      tickLine(-16.5, -27.6, -15.3, -32.2);
      tickLine(7, -22.5, 6.3, -27);
      tickLine(12, -26, 10.7, -30.6);
      tickLine(16.5, -27.6, 15.3, -32.2);
      tickLine(-5, -33, -8, -35);
      tickLine(5, -33, 8, -35);
      tickLine(-5.5, -38, -8.5, -39.8);
      tickLine(5.5, -38, 8.5, -39.8);
    }

    _blush(canvas, 4.6, -19.8, 1.9, 0.4);
    _eyes(canvas, 3.1, -22, 2.4, closed);
    _smileArc(canvas, -19.9, 1.9);
  }

  /// ТЮЛЬПАНЧИК: листья, бутон с чашелистиками → раскрытый цветок.
  void _paintTulip(Canvas canvas, int stage, bool closed) {
    final Color petal = _tulipC;
    final Color petalDark = _shade(petal, -0.16);
    final double stemTop = stage == 1 ? -24 : stage == 2 ? -40 : -46;

    final Path stem = Path()
      ..moveTo(0, -17)
      ..quadraticBezierTo(1.5, (stemTop - 17) / 2, 0, stemTop);
    canvas.drawPath(stem, _strokeP(_leafC, stage == 1 ? 2.6 : 3.6));

    canvas.drawPath(
        Path()
          ..moveTo(0, -18)
          ..quadraticBezierTo(-8, -24, -7.5, -40)
          ..quadraticBezierTo(-2.5, -30, 0.5, -22)
          ..close(),
        Paint()..color = _leafC);
    canvas.drawPath(
        Path()
          ..moveTo(0, -18)
          ..quadraticBezierTo(8, -24, 7.5, -40)
          ..quadraticBezierTo(2.5, -30, -0.5, -22)
          ..close(),
        Paint()..color = _shade(_leafC, -0.08));

    if (stage == 1) {
      _eyes(canvas, 2.5, -25.5, 2, closed);
      _smileArc(canvas, -23.4, 1.7);
    } else if (stage == 2) {
      final Path sepal = Path()
        ..moveTo(-6, -38.5)
        ..lineTo(0, -41.5)
        ..lineTo(6, -38.5)
        ..quadraticBezierTo(0, -35.5, -6, -38.5)
        ..close();
      canvas.drawPath(sepal, Paint()..color = _shade(_leafC, -0.05));
      _oval(canvas, 0, -46, 6.5, 8, Paint()..color = petal);
      canvas.drawPath(
          Path()
            ..moveTo(-2.6, -39.5)
            ..quadraticBezierTo(-3.4, -46, -2.2, -52.4),
          _strokeP(petalDark, 1.3));
      canvas.drawPath(
          Path()
            ..moveTo(2.6, -39.5)
            ..quadraticBezierTo(3.4, -46, 2.2, -52.4),
          _strokeP(petalDark, 1.3));
      _blush(canvas, 4.8, -43.5, 1.9, 0.4);
      _eyes(canvas, 3.2, -46.8, 2.6, closed);
      _smileArc(canvas, -43.9, 2.2);
    } else {
      final Path bloom = Path()
        ..moveTo(-9.5, -54)
        ..cubicTo(-9.5, -62.5, -5, -66.5, 0, -62.5)
        ..cubicTo(5, -66.5, 9.5, -62.5, 9.5, -54)
        ..cubicTo(9.5, -47.5, 5, -44, 0, -44)
        ..cubicTo(-5, -44, -9.5, -47.5, -9.5, -54)
        ..close();
      canvas.drawPath(bloom, Paint()..color = petal);
      canvas.drawPath(
          Path()
            ..moveTo(-3, -62.4)
            ..cubicTo(-6, -58, -6.4, -50.5, -5.2, -45.2),
          _strokeP(petalDark, 1.7));
      canvas.drawPath(
          Path()
            ..moveTo(3, -62.4)
            ..cubicTo(6, -58, 6.4, -50.5, 5.2, -45.2),
          _strokeP(petalDark, 1.7));
      _blush(canvas, 6.4, -50.5, 2.4, 0.4);
      _eyes(canvas, 4.1, -53.8, 3.1, closed);
      _smileArc(canvas, -50.8, 2.6);
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
