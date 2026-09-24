import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/sprite_meta.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../services/quest_service.dart';
import '../widgets/common.dart';
import '../widgets/sprite_cache.dart';

/// Мини-игра «Покорми питомца» (v1.6.0, спрайты v2.1.0).
///
/// Питомец стоит по центру — настоящий зверь с иллюстрации в едином
/// стиле. Тапните по падающей еде — она прилетит прямо в рот (якорь
/// морды спрайта), питомец довольно «пожуёт» (пружинка), хруст —
/// плюс XP и монетки. Водные питомцы плавают в пруду, растения ловят
/// еду бутоном. Вся еда нарисована цветной.
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
  bool _chewing = false;

  static const int _roundSeconds = 45;

  Duration _elapsed = Duration.zero;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _tick.repeat();
    _ensureSprite();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureSprite();
  }

  void _ensureSprite() {
    final PetService petService = context.read<PetService>();
    final Pet? pet = petService.activePet;
    if (pet == null || pet.stage == 0) return;
    SpriteCache.ensure(spriteAsset(pet.type), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.dispose();
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.playing;
      _score = 0;
      _foods.clear();
      _elapsed = Duration.zero;
    });
    _spawnFood(Duration.zero, initialCount: 3);
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _elapsed += const Duration(milliseconds: 200));
      if (_elapsed.inSeconds >= _roundSeconds) _finish();
    });
  }

  void _spawnFood(Duration at, {int initialCount = 0}) {
    for (int i = 0; i < initialCount; i++) {
      _foods.add(_Food(
        kind: _rnd.nextInt(5),
        x: 0.12 + _rnd.nextDouble() * 0.76,
        spawn: at,
        speed: 0.09 + _rnd.nextDouble() * 0.05,
      ));
    }
  }

  void _finish() {
    _countdown?.cancel();
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
          _chewing = true;
        });
        Future<void>.delayed(const Duration(milliseconds: 420), () {
          if (mounted) setState(() => _chewing = false);
        });
      }
    });
  }

  /// Прямоугольник «сцены» питомца в мини-игре (тот же расчёт, что
  /// использует painter — еда летит точно в якорь морды).
  Rect _creatureBox(Size s) {
    final Pet? pet = context.read<PetService>().activePet;
    final PetType type = pet?.type ?? PetType.fox;
    final int stage = pet?.stage ?? 3;
    final ui.Image? img = SpriteCache.get(spriteAsset(type));
    final double aspect = img == null ? 1.45 : img.width / img.height;
    final double groundY = s.height * 0.82;
    double boxH = s.height * 0.38 * spriteStageScale(stage);
    double boxW = boxH * aspect;
    if (boxW > s.width * 0.74) {
      boxW = s.width * 0.74;
      boxH = boxW / aspect;
    }
    return Rect.fromLTWH(
        s.width * 0.5 - boxW / 2, groundY - boxH, boxW, boxH);
  }

  Offset _mouthPosition(Size s) {
    final Pet? pet = context.read<PetService>().activePet;
    final Anchors a = anchorsFor(pet?.type ?? PetType.fox);
    final Rect box = _creatureBox(s);
    return Offset(
      box.left + a.mouth.$1 * box.width,
      box.top + a.mouth.$2 * box.height,
    );
  }

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CoinIcon(size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${petService.coins}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Palette.ink),
                  ),
                ],
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
                    final ui.Image? img = pet != null && pet.stage > 0
                        ? SpriteCache.get(spriteAsset(pet.type))
                        : null;
                    return GestureDetector(
                      onTapDown: (TapDownDetails d) =>
                          _tapFood(d.localPosition, cs),
                      child: CustomPaint(
                        size: cs,
                        painter: _GamePainter(
                          pet: pet,
                          creature: img,
                          creatureBox:
                              pet != null && pet.stage > 0
                                  ? _creatureBox(cs)
                                  : null,
                          foods: _foods,
                          phaseValue: _tick.value,
                          elapsed: _elapsed,
                          chewing: _chewing,
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
                  : '${pet.name} ждёт угощение! Тапайте по еде — '
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
              'Награда: +${_score * 2} XP · +$_score монеток (рекорд: $_best)',
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
    required this.creature,
    required this.creatureBox,
    required this.foods,
    required this.phaseValue,
    required this.elapsed,
    required this.chewing,
    required this.aquatic,
  });

  final Pet? pet;
  final ui.Image? creature;
  final Rect? creatureBox;
  final List<_Food> foods;
  final double phaseValue;
  final Duration elapsed;
  final bool chewing;
  final bool aquatic;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);
    if (pet != null && creature != null && creatureBox != null) {
      if (aquatic) _paintPond(canvas, size);
      _paintCreature(canvas, size);
      if (aquatic) _paintWaterFront(canvas, size);
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
    final Offset c = Offset(size.width * 0.5, size.height * 0.80);
    canvas.drawOval(
      Rect.fromCenter(
          center: c,
          width: size.width * 0.92,
          height: size.height * 0.22),
      Paint()..color = const Color(0xFFE8D8A8),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: c, width: size.width * 0.86, height: size.height * 0.19),
      Paint()..color = const Color(0xFF6EC1E4),
    );
  }

  /// Спрайт питомца: дышит (лёгкая качка), при поедании пружинит.
  void _paintCreature(Canvas canvas, Size size) {
    final Rect box = creatureBox!;
    final double bob = math.sin(phaseValue * 2 * math.pi) * 2.5;
    final double chew = chewing
        ? 1.0 + 0.06 * math.sin(phaseValue * 2 * math.pi * 6)
        : 1.0;

    // Тень.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(box.center.dx, box.bottom + 3),
        width: box.width * 0.6 * chew,
        height: box.width * 0.09,
      ),
      Paint()..color = const Color(0xFF2E7D32).withOpacity(0.18),
    );

    canvas.save();
    final Offset pivot = Offset(box.center.dx, box.bottom);
    canvas.translate(pivot.dx, pivot.dy + bob);
    canvas.scale(chew, chew);
    final Rect dst = Rect.fromLTWH(-box.width / 2, -box.height,
        box.width, box.height);
    canvas.drawImageRect(
      creature!,
      Rect.fromLTWH(0, 0, creature!.width.toDouble(),
          creature!.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  void _paintWaterFront(Canvas canvas, Size size) {
    final Offset c = Offset(size.width * 0.5, size.height * 0.80);
    canvas.drawOval(
      Rect.fromCenter(
          center: c, width: size.width * 0.86, height: size.height * 0.19),
      Paint()..color = const Color(0xFF6EC1E4).withOpacity(0.45),
    );
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
      case 0: // Яблоко
        canvas.drawCircle(Offset(0, 2), 15, Paint()..color = const Color(0xFFE5484D));
        canvas.drawCircle(Offset(-5, -3), 5, Paint()..color = const Color(0xFFFF8A8E));
        canvas.drawRect(
            Rect.fromLTWH(-1.5, -22, 3, 8), Paint()..color = const Color(0xFF8B5E34));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(7, -18), width: 12, height: 6),
          Paint()..color = const Color(0xFF62C46A),
        );
        break;
      case 1: // Рыбка
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
      case 2: // Морковка
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
      case 3: // Горшочек мёда
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
      default: // Ягоды
        canvas.drawCircle(Offset(-5, 3), 8, Paint()..color = const Color(0xFF7C5CBF));
        canvas.drawCircle(Offset(6, 4), 7.2, Paint()..color = const Color(0xFF8F6FD1));
        canvas.drawCircle(Offset(1, -6), 7.6, Paint()..color = const Color(0xFF6B4CAD));
        canvas.drawCircle(Offset(4, -12), 2.4, Paint()..color = const Color(0xFF62C46A));
        break;
    }
    canvas.restore();
  }

  Offset _mouthPos(Size s) {
    final Anchors a = anchorsFor(pet?.type ?? PetType.fox);
    final Rect box = creatureBox ?? Rect.zero;
    return Offset(
      box.left + a.mouth.$1 * box.width,
      box.top + a.mouth.$2 * box.height,
    );
  }

  Offset _foodPos(_Food f) {
    final Size s = size;
    if (f.flyT != null && f.from != null) {
      return Offset.lerp(f.from!, _mouthPos(s), f.flyT!)!;
    }
    final double t =
        (elapsed.inMilliseconds - f.spawn.inMilliseconds) / 1000.0;
    return Offset(s.width * f.x, s.height * 0.12 + s.height * f.speed * t);
  }

  @override
  bool shouldRepaint(_GamePainter oldDelegate) => true;
}
