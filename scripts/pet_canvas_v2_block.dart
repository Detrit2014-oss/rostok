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
      _paintEgg(canvas, base, body, pet.stageProgress);
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

    canvas.scale(scale);
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
