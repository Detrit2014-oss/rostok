import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/species_style.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../services/quest_service.dart';
import '../widgets/common.dart';

/// Мини-игра «Покорми питомца» (v1.6.0).
///
/// Питомец СИДИТ на задних лапах по центру и ЛОВИТ ЕДУ РТОМ:
/// тапните по падающей еде — она прилетит питомцу в рот, хруст —
/// плюс XP и монетки. Водные питомцы (кит и др.) повёрнуты ЛИЦОМ
/// К ЭКРАНУ с большим открытым ртом. Вся еда нарисована цветной.
class FeedingGameScreen extends StatefulWidget {
  const FeedingGameScreen({super.key});

  @override
  State<FeedingGameScreen> createState() => _FeedingGameScreenState();
}

enum _Phase { menu, playing, finished }

class _Food {
  _Food({
    required this.kind,
    required this.x,
    required this.spawn,
    required this.speed,
  });

  final int kind; // 0..4 — вид еды
  final double x;
  final Duration spawn;
  final double speed;

  /// Состояние «летит в рот» после тапа.
  double? flyT;
  Offset? from;
}

class _FeedingGameScreenState extends State<FeedingGameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: const Duration(hours: 1),
  );

  final List<_Food> _foods = <_Food>[];
  final math.Random _rnd = math.Random();

  _Phase _phase = _Phase.menu;
  int _score = 0;
  int _best = 0;
  Duration _elapsed = Duration.zero;
  Duration _lastSpawn = Duration.zero;
  double _mouthOpen = 0; // 0..1 анимация рта
  bool _chewing = false;

  static const int _roundSeconds = 45;
  static const Duration _spawnEvery = Duration(milliseconds: 850);

  @override
  void initState() {
    super.initState();
    _tick.addListener(_onTick);
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _onTick() {
    if (_phase != _Phase.playing) return;
    final Duration now = _tick.elapsed;
    final Duration dt = now - _elapsed;
    _elapsed = now;

    // Спавн еды.
    if (now - _lastSpawn >= _spawnEvery) {
      _lastSpawn = now;
      _foods.add(_Food(
        kind: _rnd.nextInt(5),
        x: 0.12 + _rnd.nextDouble() * 0.76,
        spawn: now,
        speed: 0.28 + _rnd.nextDouble() * 0.16, // экрана в секунду
      ));
    }

    // Рот закрывается.
    if (_mouthOpen > 0 && !_chewing) {
      _mouthOpen = math.max(0, _mouthOpen - dt.inMilliseconds / 180);
    }
    if (_chewing && now.inMilliseconds % 2 == 0) {
      _mouthOpen = 0.35 + 0.3 * math.sin(now.inMilliseconds / 60.0);
    }

    // Конец раунда.
    if (now.inSeconds >= _roundSeconds) {
      _finish();
      return;
    }

    setState(() {}); // перерисовка
  }

  void _start() {
    setState(() {
      _phase = _Phase.playing;
      _score = 0;
      _foods.clear();
      _elapsed = Duration.zero;
      _lastSpawn = Duration.zero;
      _mouthOpen = 0;
      _chewing = false;
    });
    _tick.forward(from: 0);
  }

  void _finish() {
    _tick.stop();
    setState(() => _phase = _Phase.finished);
    if (_score > _best) _best = _score;

    // Награда: 2 XP и 1 монетка за каждую пойманную еду.
    final PetService petService = context.read<PetService>();
    final Pet? pet = petService.activePet;
    if (pet != null && _score > 0) {
      petService.addXp(pet, _score * 2);
      petService.earnCoins(_score);
    }
    if (!mounted) return;
    context.read<QuestService>().addProgress('feed_5', _score);
  }

  /// Тап по еде: она летит в рот питомцу.
  void _tapFood(Offset local, Size canvasSize) {
    if (_phase != _Phase.playing) return;
    final Offset mouth = _mouthPosition(canvasSize);
    for (final _Food f in _foods.reversed) {
      if (f.flyT != null) continue;
      final Offset pos = _foodPosition(f, canvasSize);
      if ((pos - local).distance <= 34) {
        setState(() {
          f.flyT = 0;
          f.from = pos;
        });
        _animateFly(f, mouth, canvasSize);
        return;
      }
    }
  }

  void _animateFly(_Food f, Offset mouth, Size canvasSize) {
    const int steps = 12;
    int i = 0;
    Timer.periodic(const Duration(milliseconds: 16), (Timer t) {
      i++;
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => f.flyT = i / steps);
      if (i >= steps) {
        t.cancel();
        setState(() {
          _foods.remove(f);
          _score += 1;
          _mouthOpen = 1;
          _chewing = true;
        });
        Future<void>.delayed(const Duration(milliseconds: 420), () {
          if (mounted) setState(() => _chewing = false);
        });
      }
    });
  }

  Offset _mouthPosition(Size s) => Offset(s.width * 0.5, s.height * 0.52);

  Offset _foodPosition(_Food f, Size s) {
    if (f.flyT != null && f.from != null) {
      return Offset.lerp(f.from!, _mouthPosition(s), f.flyT!)!;
    }
    final double t =
        (_elapsed.inMilliseconds - f.spawn.inMilliseconds) / 1000.0;
    return Offset(s.width * f.x, s.height * 0.12 + s.height * f.speed * t);
  }

  @override
  Widget build(BuildContext context) {
    final PetService petService = context.watch<PetService>();
    final Pet? pet = petService.activePet;
    final bool aquatic = pet != null && isAquatic(pet.type);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Покорми питомца 🍽️'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '🪙 ${petService.coins}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Palette.ink),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Palette.bg,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final Size cs = c.biggest;
                    return GestureDetector(
                      onTapDown: (TapDownDetails d) =>
                          _tapFood(d.localPosition, cs),
                      child: CustomPaint(
                        size: cs,
                        painter: _GamePainter(
                          pet: pet,
                          foods: _foods,
                          phaseValue: _tick.value,
                          elapsed: _elapsed,
                          mouthOpen: _mouthOpen,
                          aquatic: aquatic,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: _bottomPanel(context, pet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel(BuildContext context, Pet? pet) {
    switch (_phase) {
      case _Phase.menu:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              pet == null
                  ? 'Сначала выберите питомца на главном экране.'
                  : '${pet.name} сидит и ждёт угощение! Тапайте по еде — '
                      'она полетит прямо в рот. 45 секунд.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Palette.inkSoft),
            ),
            const SizedBox(height: 10),
            BigButton(
              label: 'Начать кормление',
              icon: Icons.restaurant_rounded,
              fullWidth: true,
              onPressed: pet == null ? null : _start,
            ),
          ],
        );
      case _Phase.playing:
        return Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Поймано: $_score',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    'Осталось: ${_roundSeconds - _elapsed.inSeconds} с',
                    style: const TextStyle(
                        fontSize: 12.5, color: Palette.inkSoft),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: _elapsed.inSeconds / _roundSeconds,
              minHeight: 10,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: const Color(0xFFE8F4E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Palette.green),
            )
          ],
        );
      case _Phase.finished:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Хрум-хрум! 🎉 Поймано еды: $_score',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'Награда: +${_score * 2} XP · +$_score 🪙 (рекорд: $_best)',
              style: const TextStyle(fontSize: 12.5, color: Palette.inkSoft),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: BigButton(
                    label: 'Ещё раз',
                    icon: Icons.refresh_rounded,
                    onPressed: _start,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BigButton(
                    label: 'Готово',
                    icon: Icons.check_rounded,
                    color: Palette.blue,
                    shadow: const Color(0xFF1899D6),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class _GamePainter extends CustomPainter {
  _GamePainter({
    required this.pet,
    required this.foods,
    required this.phaseValue,
    required this.elapsed,
    required this.mouthOpen,
    required this.aquatic,
  });

  final Pet? pet;
  final List<_Food> foods;
  final double phaseValue;
  final Duration elapsed;
  final double mouthOpen;
  final bool aquatic;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);
    if (pet == null) return;
    if (aquatic) {
      _paintPond(canvas, size);
      _paintWhaleFront(canvas, size);
    } else if (isPlant(pet!.type)) {
      _paintSittingPlant(canvas, size);
    } else {
      _paintSittingPet(canvas, size);
    }
    for (final _Food f in foods) {
      _paintFood(canvas, f);
    }
  }

  // ── Фон ─────────────────────────────────────────────────────────────
  void _paintBackdrop(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFA6E4FF), Color(0xFFEAF9E0)],
        ).createShader(rect),
    );
    final double groundY = size.height * 0.8;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF90D26D),
    );
  }

  void _paintPond(Canvas canvas, Size size) {
    final Offset c = Offset(size.width * 0.5, size.height * 0.78);
    canvas.drawOval(
      Rect.fromCenter(
          center: c, width: size.width * 0.86, height: size.height * 0.2),
      Paint()..color = const Color(0xFF6EC1E4),
    );
  }

  // ── Сидящий питомец (на задних лапах) ───────────────────────────────
  void _paintSittingPet(Canvas canvas, Size size) {
    final Pet p = pet!;
    final SpeciesStyle st =
        kSpeciesStyles[p.type] ?? kSpeciesStyles[PetType.fox]!;
    final Color body = st.body;
    final Color belly = speciesBelly(p.type);
    final double s = 1.0;
    final double cx = size.width * 0.5;
    final double groundY = size.height * 0.8;
    final double bodyW = 110 * s;
    final double bodyH = 118 * s;
    final Offset bodyC = Offset(cx, groundY - bodyH * 0.52);

    // Хвост за телом.
    _tailBehind(canvas, bodyC, bodyW, bodyH, st.tail, body);

    // Задние лапы-бёдра (сидит!): два круга по бокам низа.
    final Paint hip = Paint()..color = body;
    canvas.drawCircle(
        bodyC + Offset(-bodyW * 0.38, bodyH * 0.32), bodyW * 0.24, hip);
    canvas.drawCircle(
        bodyC + Offset(bodyW * 0.38, bodyH * 0.32), bodyW * 0.24, hip);
    // Ступни перед бёдрами.
    final Paint foot = Paint()..color = body;
    final Paint toe = Paint()..color = belly;
    for (final double sx in <double>[-0.34, 0.34]) {
      final Offset fc = Offset(cx + bodyW * sx, groundY - 6);
      canvas.drawOval(
        Rect.fromCenter(center: fc, width: 34, height: 18),
        foot,
      );
      for (int t = -1; t <= 1; t++) {
        canvas.drawCircle(
            Offset(fc.dx + t * 8, fc.dy + 2), 2.6, toe);
      }
    }

    // Тело (вертикальный овал) и животик.
    canvas.drawOval(
      Rect.fromCenter(center: bodyC, width: bodyW, height: bodyH),
      Paint()..color = body,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyC + Offset(0, bodyH * 0.14),
        width: bodyW * 0.56,
        height: bodyH * 0.5,
      ),
      Paint()..color = belly,
    );

    // Передние лапки — сложены на животике.
    for (final double sx in <double>[-0.16, 0.16]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + bodyW * sx, bodyC.dy + bodyH * 0.3),
          width: 22,
          height: 14,
        ),
        Paint()..color = body,
      );
    }

    // Голова наверху тела.
    final double headR = bodyW * 0.42;
    final Offset headC = bodyC + Offset(0, -bodyH * 0.62);
    _ears(canvas, headC, headR, st.ear, body, belly);
    canvas.drawCircle(headC, headR, Paint()..color = body);

    // Глаза и румянец.
    final Paint white = Paint()..color = Colors.white;
    final Paint pupil = Paint()..color = const Color(0xFF33261A);
    final double eyeDX = headR * 0.42;
    final double eyeY = headC.dy - headR * 0.05;
    canvas.drawCircle(Offset(headC.dx - eyeDX, eyeY), headR * 0.2, white);
    canvas.drawCircle(Offset(headC.dx + eyeDX, eyeY), headR * 0.2, white);
    canvas.drawCircle(Offset(headC.dx - eyeDX + 1, eyeY + 1), headR * 0.1, pupil);
    canvas.drawCircle(Offset(headC.dx + eyeDX + 1, eyeY + 1), headR * 0.1, pupil);
    final Paint blush = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.55);
    canvas.drawCircle(
        Offset(headC.dx - headR * 0.72, headC.dy + headR * 0.18),
        headR * 0.14, blush);
    canvas.drawCircle(
        Offset(headC.dx + headR * 0.72, headC.dy + headR * 0.18),
        headR * 0.14, blush);

    // РОТ: открыт, готов ловить еду.
    _mouth(canvas, Offset(headC.dx, headC.dy + headR * 0.45),
        headR * (0.3 + 0.5 * mouthOpen.clamp(0.0, 1.0)), belly);
  }

  /// Кит (и другие водные) — ЛИЦОМ К ЭКРАНУ, большой открытый рот.
  void _paintWhaleFront(Canvas canvas, Size size) {
    final Pet p = pet!;
    final Color body = speciesBody(p.type);
    final Color belly = speciesBelly(p.type);
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.56;
    final double r = math.min(size.width, size.height) * 0.24;

    // Хвостовые плавники за спиной.
    final Paint fin = Paint()..color = body.withOpacity(0.85);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - r * 1.05, cy), width: r * 0.5, height: r * 0.9),
      fin,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + r * 1.05, cy), width: r * 0.5, height: r * 0.9),
      fin,
    );

    // Тело — круг «камера смотрит на кита».
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = body);
    // Животик-низ.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.45),
        width: r * 1.5,
        height: r * 0.9,
      ),
      Paint()..color = belly,
    );

    // Глаза наверху по бокам.
    final Paint white = Paint()..color = Colors.white;
    final Paint pupil = Paint()..color = const Color(0xFF33261A);
    for (final double sx in <double>[-0.45, 0.45]) {
      final Offset ec = Offset(cx + r * sx, cy - r * 0.3);
      canvas.drawCircle(ec, r * 0.16, white);
      canvas.drawCircle(ec + const Offset(1, 1), r * 0.08, pupil);
    }

    // Фонтанчик на макушке.
    canvas.drawCircle(
        Offset(cx, cy - r * 0.75), r * 0.08, Paint()..color = const Color(0xFF3E6E8E));

    // БОЛЬШОЙ ОТКРЫТЫЙ РОТ по центру.
    _mouth(canvas, Offset(cx, cy + r * 0.32), r * (0.34 + 0.42 * mouthOpen.clamp(0.0, 1.0)), belly);
  }

  void _paintSittingPlant(Canvas canvas, Size size) {
    final Pet p = pet!;
    final Color body = speciesBody(p.type);
    final double cx = size.width * 0.5;
    final double groundY = size.height * 0.8;

    // Горшочек.
    final Path pot = Path()
      ..moveTo(cx - 34, groundY - 52)
      ..lineTo(cx + 34, groundY - 52)
      ..lineTo(cx + 26, groundY - 4)
      ..lineTo(cx - 26, groundY - 4)
      ..close();
    canvas.drawPath(pot, Paint()..color = kPot);
    canvas.drawRect(
      Rect.fromLTWH(cx - 37, groundY - 58, 74, 10),
      Paint()..color = kPotDark,
    );

    // Растение: стебель и листья — «рот» это центр цветка/верхушка.
    final double topY = groundY - 58;
    canvas.drawRect(
      Rect.fromLTWH(cx - 3, topY - 44, 6, 44),
      Paint()..color = kStem,
    );
    final Path leafL = Path()
      ..moveTo(cx, topY - 40)
      ..quadraticBezierTo(cx - 36, topY - 48, cx - 30, topY - 74)
      ..quadraticBezierTo(cx - 8, topY - 56, cx, topY - 40)
      ..close();
    final Path leafR = Path()
      ..moveTo(cx, topY - 40)
      ..quadraticBezierTo(cx + 36, topY - 48, cx + 30, topY - 74)
      ..quadraticBezierTo(cx + 8, topY - 56, cx, topY - 40)
      ..close();
    canvas.drawPath(leafL, Paint()..color = body);
    canvas.drawPath(leafR, Paint()..color = body.withOpacity(0.88));
    // Рот растения — распахнутый бутон на верхушке.
    _mouth(canvas, Offset(cx, topY - 46), 14 + 12 * mouthOpen.clamp(0.0, 1.0), body);
  }

  void _ears(Canvas canvas, Offset headC, double headR, String kind,
      Color body, Color belly) {
    final Paint ear = Paint()..color = body;
    switch (kind) {
      case 'triangle':
        for (final double sx in <double>[-1, 1]) {
          canvas.drawPath(
            Path()
              ..moveTo(headC.dx + sx * headR * 0.75, headC.dy - headR * 0.35)
              ..lineTo(headC.dx + sx * headR * 0.5, headC.dy - headR * 1.25)
              ..lineTo(headC.dx + sx * headR * 0.15, headC.dy - headR * 0.7)
              ..close(),
            ear,
          );
        }
        break;
      case 'round':
      case 'pom':
        for (final double sx in <double>[-1, 1]) {
          canvas.drawCircle(
              Offset(headC.dx + sx * headR * 0.72, headC.dy - headR * 0.7),
              headR * 0.34,
              ear);
        }
        break;
      case 'long':
        for (final double sx in <double>[-1, 1]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center:
                    Offset(headC.dx + sx * headR * 0.42, headC.dy - headR * 1.25),
                width: headR * 0.4,
                height: headR * 1.5,
              ),
              Radius.circular(headR * 0.2),
            ),
            ear,
          );
        }
        break;
      case 'horns':
        for (final double sx in <double>[-1, 1]) {
          canvas.drawCircle(
              Offset(headC.dx + sx * headR * 0.4, headC.dy - headR * 0.85),
              headR * 0.14,
              Paint()..color = const Color(0xFFF6E7C1));
        }
        break;
      case 'tuft':
        canvas.drawCircle(
            headC + Offset(0, -headR * 1.0), headR * 0.18, ear);
        break;
      default:
        break;
    }
  }

  void _tailBehind(Canvas canvas, Offset bodyC, double bodyW, double bodyH,
      String kind, Color body) {
    if (kind == 'bushy') {
      canvas.drawOval(
        Rect.fromCenter(
          center: bodyC + Offset(bodyW * 0.62, bodyH * 0.18),
          width: bodyW * 0.5,
          height: bodyH * 0.72,
        ),
        Paint()..color = body,
      );
    } else if (kind == 'thin' || kind == 'curl') {
      canvas.drawOval(
        Rect.fromCenter(
          center: bodyC + Offset(bodyW * 0.58, bodyH * 0.3),
          width: bodyW * 0.22,
          height: bodyH * 0.34,
        ),
        Paint()..color = body,
      );
    }
  }

  /// Открытый рот: тёмная пасть с язычком — сюда летит еда.
  void _mouth(Canvas canvas, Offset c, double r, Color belly) {
    final double rr = r.clamp(6.0, 60.0);
    canvas.drawCircle(c, rr, Paint()..color = const Color(0xFF7E3A47));
    canvas.drawCircle(
        c + Offset(0, rr * 0.35), rr * 0.55, Paint()..color = const Color(0xFFE88A9A));
    canvas.drawCircle(
        c, rr * 1.06, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = belly.withOpacity(0.7));
  }

  // ── Еда (всегда цветная — никаких прозрачных квадратов) ────────────
  void _paintFood(Canvas canvas, _Food f) {
    final Offset pos = _foodPos(f);
    final double wobble = math.sin(
            (elapsed.inMilliseconds + f.kind * 300) / 220.0) * 0.15;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(wobble);
    switch (f.kind) {
      case 0: // Яблоко 🍎
        canvas.drawCircle(Offset(0, 2), 15, Paint()..color = const Color(0xFFE5484D));
        canvas.drawCircle(Offset(-5, -3), 5, Paint()..color = const Color(0xFFFF8A8E));
        canvas.drawRect(
            Rect.fromLTWH(-1.5, -22, 3, 8), Paint()..color = const Color(0xFF8B5E34));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(7, -18), width: 12, height: 6),
          Paint()..color = const Color(0xFF62C46A),
        );
        break;
      case 1: // Рыбка 🐟
        canvas.drawOval(
          Rect.fromCenter(center: Offset(-2, 0), width: 28, height: 14),
          Paint()..color = const Color(0xFF5FA8D3),
        );
        canvas.drawPath(
          Path()
            ..moveTo(11, 0)
            ..lineTo(21, -8)
            ..lineTo(21, 8)
            ..close(),
          Paint()..color = const Color(0xFF4A8FB8),
        );
        canvas.drawCircle(Offset(-10, -3), 2.2, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(-10, -3), 1.1, Paint()..color = const Color(0xFF33261A));
        break;
      case 2: // Морковка 🥕
        canvas.drawPath(
          Path()
            ..moveTo(-9, -12)
            ..lineTo(9, -12)
            ..lineTo(0, 16)
            ..close(),
          Paint()..color = const Color(0xFFFF8A3D),
        );
        for (final double sx in <double>[-4, 0, 4]) {
          canvas.drawCircle(
              Offset(sx, -15), 3.4, Paint()..color = const Color(0xFF62C46A));
        }
        break;
      case 3: // Горшочек мёда 🍯
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, 2), width: 22, height: 20),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFFE8A33D),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -10), width: 24, height: 7),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFC97B4E),
        );
        canvas.drawCircle(Offset(0, 2), 4.5, Paint()..color = const Color(0xFFFFD98A));
        break;
      default: // Ягоды 🫐
        canvas.drawCircle(Offset(-5, 3), 8, Paint()..color = const Color(0xFF7C5CBF));
        canvas.drawCircle(Offset(6, 4), 7.2, Paint()..color = const Color(0xFF8F6FD1));
        canvas.drawCircle(Offset(1, -6), 7.6, Paint()..color = const Color(0xFF6B4CAD));
        canvas.drawCircle(Offset(4, -12), 2.4, Paint()..color = const Color(0xFF62C46A));
        break;
    }
    canvas.restore();
  }

  Offset _foodPos(_Food f) {
    final Size s = size;
    if (f.flyT != null && f.from != null) {
      return Offset.lerp(f.from!, Offset(s.width * 0.5, s.height * 0.52), f.flyT!)!;
    }
    final double t =
        (elapsed.inMilliseconds - f.spawn.inMilliseconds) / 1000.0;
    return Offset(s.width * f.x, s.height * 0.12 + s.height * f.speed * t);
  }

  @override
  bool shouldRepaint(_GamePainter oldDelegate) => true;
}
