import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/cartoon.dart';
import '../models/pet.dart';

/// Процедурный мультяшный рисовальщик питомцев «Ростка» v2.2.0.
///
/// Каждый вид рисуется кодом в едином мультяшном стиле: тёплый плотный
/// контур, плоские сочные заливки, округлые формы, большие глаза с
/// бликом и румянец. И всё ЖИВОЕ: лапы шагают диагональной походкой,
/// корпус покачивается, хвост виляет, уши пружинят, глаза моргают,
/// зверь дышит; на паузах — настоящие повадки (принюхивается, щиплет
/// траву, сидит, клюёт); спит ЛЁЖА, положив морду на лапы.
///
/// Контракт: рисует ВПРАВО в локальных координатах — (0,0) это точка
/// опоры (земля), вверх — отрицательный Y. Вызывающий код делает
/// translate/scale(facing)/rotate. Единица u = h/10 (quad/bird/hop),
/// h/3.6 (pond), h/7.2 (plant). Аналогичный порт для веб-демо живёт в
/// src/lib/ttg/cartoon.ts — числа совпадают 1:1.
library;

// ── Кисти: заливка + мягкий контур ─────────────────────────────────────

class _P {
  _P(this.alpha, [this.inkW = 1.0]);

  /// Глобальная альфа (кроссфейд поз).
  final double alpha;

  /// Толщина контура (синхронна с _Ctx.inkW).
  final double inkW;

  Paint fill(Color c) => Paint()..color = _a(c);
  Paint stroke(Color c, double w) => Paint()
    ..color = _a(c)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  Color _a(Color c) => alpha >= 0.999 ? c : c.withOpacity(alpha);

  void shape(Canvas canvas, Path path, Color color, Color ink, double w) {
    if (color.opacity > 0) canvas.drawPath(path, fill(color));
    if (w > 0 && ink.opacity > 0) canvas.drawPath(path, stroke(ink, w));
  }

  void circle(Canvas canvas, Offset c, double r, Color color, Color ink, double w) {
    canvas.drawCircle(c, r, fill(color));
    canvas.drawCircle(c, r, stroke(ink, w));
  }

  void ellipse(Canvas canvas, Offset c, double rx, double ry, Color color,
      Color ink, double w,
      {double rot = 0}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final Rect r = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    canvas.drawOval(r, fill(color));
    canvas.drawOval(r, stroke(ink, w));
    canvas.restore();
  }

  /// Мягкая деталь без контура (щёчки, блики, пятнышки).
  void dot(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(c, r, fill(color));
  }

  void line(Canvas canvas, Offset a, Offset b, Color color, double w) {
    canvas.drawLine(a, b, stroke(color, w));
  }

  /// Толстая линия с контуром: сначала широкий «контурный» штрих,
  /// поверх — цветной (хвосты кошки, стебли).
  void tube(Canvas canvas, Path path, Color color, Color ink, double w) {
    canvas.drawPath(path, stroke(ink, w + inkW * 0.9));
    canvas.drawPath(path, stroke(color, w));
  }
}

/// Капсула между двумя точками (лапы, уши, хвосты).
Path capsulePath(Offset a, double r1, Offset b, double r2) {
  final double dx = b.dx - a.dx, dy = b.dy - a.dy;
  final double ang = math.atan2(dy, dx);
  final double nx = -math.sin(ang), ny = math.cos(ang);
  return Path()
    ..moveTo(a.dx + nx * r1, a.dy + ny * r1)
    ..lineTo(b.dx + nx * r2, b.dy + ny * r2)
    ..arcTo(Rect.fromCircle(center: b, radius: r2), ang - math.pi / 2, math.pi, false)
    ..lineTo(a.dx - nx * r1, a.dy - ny * r1)
    ..arcTo(Rect.fromCircle(center: a, radius: r1), ang + math.pi / 2, math.pi, false)
    ..close();
}

/// Лист/слеза из основания к кончику (хвосты, листья, уши).
Path leafPath(Offset base, Offset tip, double w) {
  final double mx = (base.dx + tip.dx) / 2, my = (base.dy + tip.dy) / 2;
  final double dx = tip.dx - base.dx, dy = tip.dy - base.dy;
  final double len = math.sqrt(dx * dx + dy * dy).clamp(0.001, 9999);
  final double nx = -dy / len * w, ny = dx / len * w;
  return Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(mx + nx, my + ny, tip.dx, tip.dy)
    ..quadraticBezierTo(mx - nx, my - ny, base.dx, base.dy)
    ..close();
}

// ── Публичный вход ─────────────────────────────────────────────────────

/// Рисует питомца в мультяшном стиле. kind: walk|sniff|graze|sit|peck|
/// look|idle; sleeping — поза сна; chewing — мини-игра «Покорми».
void paintCartoonPet(
  Canvas canvas,
  Pet pet,
  double h, {
  required double tSec,
  String kind = 'idle',
  double stride = 0,
  double headPitch = 0,
  double poseEase = 0,
  bool sleeping = false,
  bool chewing = false,
  int index = 0,
}) {
  final CartoonSpec spec = cartoonSpec(pet.type);
  final _Ctx c = _Ctx(
    pet: pet,
    spec: spec,
    h: h,
    u: h /
        (spec.build == 'pond'
            ? 3.6
            : spec.build == 'plant'
                ? 7.2
                : 10.0),
    tSec: tSec,
    kind: kind,
    stride: stride,
    headPitch: headPitch,
    poseEase: poseEase,
    sleeping: sleeping,
    chewing: chewing,
    index: index,
    blinkSeed: ((pet.id.hashCode & 0x7fffffff) % 340) / 100,
  );

  switch (spec.build) {
    case 'bird':
      _paintBird(canvas, c);
      break;
    case 'hop':
      _paintHop(canvas, c);
      break;
    case 'pond':
      _paintPond(canvas, c);
      break;
    case 'plant':
      _paintPlant(canvas, c);
      break;
    default:
      _paintQuad(canvas, c);
  }
}

class _Ctx {
  const _Ctx({
    required this.pet,
    required this.spec,
    required this.h,
    required this.u,
    required this.tSec,
    required this.kind,
    required this.stride,
    required this.headPitch,
    required this.poseEase,
    required this.sleeping,
    required this.chewing,
    required this.index,
    required this.blinkSeed,
  });

  final Pet pet;
  final CartoonSpec spec;
  final double h;
  final double u;
  final double tSec;
  final String kind;
  final double stride;
  final double headPitch;
  final double poseEase;
  final bool sleeping;
  final bool chewing;
  final int index;
  final double blinkSeed;

  bool get walking => kind == 'walk';
  double get inkW => u * 0.42;

  Color get body {
    final Color base = spec.body;
    switch (pet.skin) {
      case 'golden':
        return Color.lerp(base, const Color(0xFFFFC800), 0.45)!;
      case 'mint':
        return Color.lerp(base, const Color(0xFF7FD8C0), 0.45)!;
      case 'rose':
        return Color.lerp(base, const Color(0xFFFF9FB2), 0.45)!;
      default:
        return base;
    }
  }

  Color get belly => spec.belly;
  Color get accent => spec.accent ?? belly;
  Color get dark => spec.dark ?? cartoonShade(spec.body);
  Color get ink => cartoonInk(spec.body);

  /// Моргание: раз в ~3.4 с на 0.12 с.
  bool get blink => ((tSec * 0.7 + blinkSeed) % 3.4) < 0.12;

  /// Дыхание.
  double get breath => 1.0 + math.sin(tSec * 1.15 + index * 1.3) * 0.014;

  /// Виляние хвостом: на шагу быстро, в покое лениво.
  double get wag => walking
      ? math.sin(stride) * 0.35
      : math.sin(tSec * 2.1 + index) * 0.14;
}

// ── Глаза ──────────────────────────────────────────────────────────────

/// Профильный глаз (quad): белок, зрачок вперёд, блик.
void _eyeProfile(Canvas cv, _P p, _Ctx c, Offset center, double r) {
  if (c.sleeping || c.blink) {
    final Path arc = Path()
      ..moveTo(center.dx - r * 0.9, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + r, center.dx + r * 0.9, center.dy);
    cv.drawPath(arc, p.stroke(c.ink, c.inkW * 0.7));
    return;
  }
  p.circle(cv, center, r, Colors.white, c.ink, c.inkW * 0.45);
  p.dot(cv, center + Offset(r * 0.24, r * 0.04), r * 0.6, const Color(0xFF33261A));
  p.dot(cv, center + Offset(r * 0.02, -r * 0.3), r * 0.22, Colors.white);
}

/// Пара «фронтальных» глаз (птицы, лягушка, осьминог, краб).
void _eyesFront(Canvas cv, _P p, _Ctx c, List<Offset> pts, double r) {
  for (final Offset o in pts) {
    if (c.sleeping || c.blink) {
      final Path arc = Path()
        ..moveTo(o.dx - r * 0.85, o.dy)
        ..quadraticBezierTo(o.dx, o.dy + r * 0.9, o.dx + r * 0.85, o.dy);
      cv.drawPath(arc, p.stroke(c.ink, c.inkW * 0.7));
      continue;
    }
    p.circle(cv, o, r, Colors.white, c.ink, c.inkW * 0.45);
    p.dot(cv, o + Offset(r * 0.16, r * 0.05), r * 0.58, const Color(0xFF33261A));
    p.dot(cv, o + Offset(-r * 0.1, -r * 0.26), r * 0.2, Colors.white);
  }
}

/// Румянец.
void _blush(Canvas cv, _P p, Offset c, double r) {
  p.dot(cv, c, r, const Color(0xFFFF9FB2).withOpacity(0.45));
}

/// Улыбка-дужка (или открытый рот при жевании).
void _mouth(Canvas cv, _P p, _Ctx c, Offset center, double w) {
  if (c.chewing && !c.sleeping) {
    final Rect r = Rect.fromCenter(center: center, width: w * 0.7, height: w * 0.55);
    cv.drawOval(r, p.fill(const Color(0xFF7A4238)));
    cv.drawOval(r, p.stroke(c.ink, c.inkW * 0.5));
    return;
  }
  final Path arc = Path()
    ..moveTo(center.dx - w / 2, center.dy)
    ..quadraticBezierTo(center.dx, center.dy + w * 0.55, center.dx + w / 2, center.dy);
  cv.drawPath(arc, p.stroke(c.ink, c.inkW * 0.55));
}

// ── Аксессуары гардероба (в локальных единицах u) ──────────────────────

void _accHat(Canvas cv, _P p, _Ctx c, Offset top) {
  final double au = c.u * 0.115; // единица аксессуаров (1% ширины спрайта)
  switch (c.pet.hat) {
    case 'cap':
      final Path dome = Path()
        ..moveTo(top.dx - 14 * au * 0.62, top.dy)
        ..quadraticBezierTo(top.dx, top.dy - 22 * au * 0.62, top.dx + 14 * au * 0.62, top.dy)
        ..close();
      p.shape(cv, dome, const Color(0xFFEF476F), c.ink, c.inkW * 0.6);
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromLTWH(top.dx + 5 * au, top.dy - 2 * au, 13 * au, 4 * au),
                const Radius.circular(3))),
          const Color(0xFFD63860),
          c.ink,
          c.inkW * 0.5);
      p.dot(cv, top + Offset(0, -11 * au * 0.62), 2.1 * au, Colors.white);
      break;
    case 'beanie':
      final Path dome = Path()
        ..moveTo(top.dx - 14 * au * 0.62, top.dy)
        ..quadraticBezierTo(top.dx, top.dy - 20 * au * 0.62, top.dx + 14 * au * 0.62, top.dy)
        ..close();
      p.shape(cv, dome, const Color(0xFFB892E0), c.ink, c.inkW * 0.6);
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromLTWH(top.dx - 14 * au * 0.62, top.dy - 2 * au,
                    28 * au * 0.62, 4.4 * au * 0.62),
                const Radius.circular(3))),
          const Color(0xFF9A77C9),
          c.ink,
          c.inkW * 0.5);
      p.dot(cv, top + Offset(0, -19 * au * 0.62), 3.2 * au, const Color(0xFFF7F1EA));
      break;
    case 'crown':
      final Path crown = Path()
        ..moveTo(top.dx - 11 * au * 0.62, top.dy)
        ..lineTo(top.dx - 11 * au * 0.62, top.dy - 10 * au * 0.62)
        ..lineTo(top.dx - 5.5 * au * 0.62, top.dy - 5 * au * 0.62)
        ..lineTo(top.dx, top.dy - 12 * au * 0.62)
        ..lineTo(top.dx + 5.5 * au * 0.62, top.dy - 5 * au * 0.62)
        ..lineTo(top.dx + 11 * au * 0.62, top.dy - 10 * au * 0.62)
        ..lineTo(top.dx + 11 * au * 0.62, top.dy)
        ..close();
      p.shape(cv, crown, const Color(0xFFFFC800), c.ink, c.inkW * 0.6);
      p.dot(cv, top + Offset(0, -3.4 * au), 1.7 * au, const Color(0xFFEF476F));
      break;
    case 'flowerPin':
      for (int i = 0; i < 5; i++) {
        final double ang = i * 2 * math.pi / 5 - math.pi / 2;
        p.dot(cv,
            top + Offset(math.cos(ang), math.sin(ang)) * 3.2 * au, 2.3 * au,
            const Color(0xFFFF8FB1));
      }
      p.dot(cv, top, 2.1 * au, const Color(0xFFFFD166));
      break;
    default:
      break;
  }
}

void _accFace(Canvas cv, _P p, _Ctx c, Offset eye) {
  final double au = c.u * 0.115; // единица аксессуаров (1% ширины спрайта)
  switch (c.pet.face) {
    case 'glasses':
      cv.drawCircle(eye, 6 * au * 0.62, p.stroke(const Color(0xFF3A3A3A), 1.6 * au));
      p.line(cv, eye + Offset(6 * au * 0.62, 0), eye + Offset(12 * au, -1.5 * au),
          const Color(0xFF3A3A3A), 1.6 * au);
      break;
    case 'shades':
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(center: eye, width: 12 * au, height: 8.5 * au),
                const Radius.circular(3 * au))),
          const Color(0xFF23262B),
          c.ink,
          c.inkW * 0.5);
      p.line(cv, eye + Offset(6 * au, -1 * au), eye + Offset(12 * au, -2.5 * au),
          const Color(0xFF23262B), 1.6 * au);
      break;
    default:
      break;
  }
}

void _accNeck(Canvas cv, _P p, _Ctx c, Offset neck) {
  final double au = c.u * 0.115; // единица аксессуаров (1% ширины спрайта)
  switch (c.pet.neck) {
    case 'scarf':
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(center: neck, width: 22 * au, height: 6.5 * au),
                const Radius.circular(3.2 * au))),
          const Color(0xFFEF6461),
          c.ink,
          c.inkW * 0.55);
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromLTWH(neck.dx - 11 * au, neck.dy, 6.5 * au, 13 * au),
                const Radius.circular(3 * au))),
          const Color(0xFFD63860),
          c.ink,
          c.inkW * 0.55);
      break;
    case 'bow':
      p.dot(cv, neck, 2.4 * au, const Color(0xFFE85D8A));
      final Path l = Path()
        ..moveTo(neck.dx, neck.dy)
        ..lineTo(neck.dx - 11 * au, neck.dy - 6.5 * au)
        ..quadraticBezierTo(neck.dx - 14 * au, neck.dy, neck.dx - 11 * au, neck.dy + 6.5 * au)
        ..close();
      final Path r = Path()
        ..moveTo(neck.dx, neck.dy)
        ..lineTo(neck.dx + 11 * au, neck.dy - 6.5 * au)
        ..quadraticBezierTo(neck.dx + 14 * au, neck.dy, neck.dx + 11 * au, neck.dy + 6.5 * au)
        ..close();
      p.shape(cv, l, const Color(0xFFFF6FA5), c.ink, c.inkW * 0.55);
      p.shape(cv, r, const Color(0xFFFF6FA5), c.ink, c.inkW * 0.55);
      break;
    case 'bandana':
      final Path kerchief = Path()
        ..moveTo(neck.dx - 12 * au, neck.dy - 2.5 * au)
        ..lineTo(neck.dx + 12 * au, neck.dy - 2.5 * au)
        ..lineTo(neck.dx, neck.dy + 10 * au)
        ..close();
      p.shape(cv, kerchief, const Color(0xFF3E7BFA), c.ink, c.inkW * 0.55);
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: neck - Offset(0, 2.5 * au), width: 24 * au, height: 4.6 * au),
                const Radius.circular(2.4 * au))),
          const Color(0xFF2F63D6),
          c.ink,
          c.inkW * 0.5);
      break;
    case 'bell':
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(center: neck, width: 22 * au, height: 3.4 * au),
                const Radius.circular(2 * au))),
          const Color(0xFFD63860),
          c.ink,
          c.inkW * 0.5);
      p.circle(cv, neck + Offset(0, 5 * au), 4.4 * au, const Color(0xFFFFC800),
          c.ink, c.inkW * 0.55);
      p.circle(cv, neck + Offset(0, 5 * au), 2 * au, const Color(0xFFE09E00),
          c.ink, c.inkW * 0.45);
      p.dot(cv, neck + Offset(0, 3.6 * au), 1 * au, Colors.white);
      break;
    default:
      break;
  }
}

// ── ЧЕТВЕРОНОГИЕ ───────────────────────────────────────────────────────

// Ключевые точки (в единицах u), вид в профиль вправо.
Offset _qBodyC(_Ctx c) => Offset(0.1 * c.u, -4.5 * c.u);
double _qBodyRx(_Ctx c) => 3.0 * c.u;
double _qBodyRy(_Ctx c) => 1.65 * c.u;

Offset _qNeckBase(_Ctx c) => Offset(2.45 * c.u, -5.5 * c.u);

/// Центр головы при данном наклоне шеи: шея поворачивается от
/// «вверх-вперёд» вниз к земле; при глубоком наклоне чуть вытягивается.
Offset _qHeadC(_Ctx c, double pitch) {
  final double theta = -0.95 + pitch * 1.85;
  final double len = (1.72 + (pitch > 0.3 ? (pitch - 0.3) * 0.9 : 0)) * c.u;
  return _qNeckBase(c) + Offset(math.cos(theta), math.sin(theta)) * len;
}

void _paintQuad(Canvas canvas, _Ctx c) {
  if (c.sleeping) {
    _quadSleep(canvas, _P(1, c.inkW), c);
    return;
  }
  // Поза «сидит» — кроссфейд между стоячей и сидячей фигурами.
  if (c.kind == 'sit' && c.poseEase > 0.01) {
    _paintQuadStand(canvas, _P((1 - c.poseEase).clamp(0.05, 1.0), c.inkW), c);
    _paintQuadSit(canvas, _P(c.poseEase.clamp(0.05, 1.0), c.inkW), c);
    return;
  }
  _paintQuadStand(canvas, _P(1, c.inkW), c);
}

/// Шагающая лапа: бедро+голень с коленом, лапка. phase — фаза шага.
void _quadLeg(Canvas cv, _P p, _Ctx c, Offset hip, double phase, Color color) {
  final double a = math.sin(phase) * 0.45 * (c.walking ? 1.0 : 0.0);
  final double lift =
      math.max(0, math.sin(phase + math.pi / 2)) * 0.55 * c.u * (c.walking ? 1.0 : 0.0);
  final Offset knee = hip + Offset(0.35 * c.u * 0.3 + math.sin(a) * 2.3 * c.u * 0.55,
      math.cos(a) * 2.3 * c.u * 0.55);
  final Offset foot = knee +
      Offset(math.sin(a) * 2.1 * c.u * 0.7, math.cos(a) * 2.1 * c.u - lift);
  p.shape(cv, capsulePath(hip, 0.52 * c.u, knee, 0.4 * c.u), color, c.ink, c.inkW);
  p.shape(cv, capsulePath(knee, 0.4 * c.u, foot, 0.36 * c.u), color, c.ink, c.inkW);
  p.circle(cv, foot + Offset(0.12 * c.u, 0), 0.46 * c.u, color, c.ink, c.inkW);
}

void _paintQuadStand(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  final Offset bodyC = _qBodyC(c);
  final double br = c.breath;

  // Дальняя пара лап (чуть темнее) — диагональ к ближней.
  final Color farC = Color.lerp(c.body, kInkCartoon, 0.2)!;
  _quadLeg(cv, p, c, Offset(-1.9 * u, -4.7 * u), c.stride + math.pi, farC);
  _quadLeg(cv, p, c, Offset(2.0 * u, -4.7 * u), c.stride + math.pi, farC);

  // Дальнее крыло дракона.
  if (c.spec.extras.contains('wings')) {
    cv.save();
    cv.translate(1.1 * u, -5.7 * u);
    cv.rotate(math.sin(c.tSec * 2.6) * 0.12 - 0.15);
    final Path fw = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-1.6 * u, -2.6 * u, -3.0 * u, -3.1 * u)
      ..quadraticBezierTo(-2.0 * u, -2.2 * u, -1.7 * u, -1.2 * u)
      ..quadraticBezierTo(-0.9 * u, -1.9 * u, 0, -0.6 * u)
      ..close();
    p.shape(cv, fw, cartoonShade(c.accent), c.ink, c.inkW * 0.8);
    cv.restore();
  }

  // Хвост (за корпусом).
  _quadTail(cv, p, c, bodyC);

  // Корпус.
  p.ellipse(cv, bodyC + Offset(0, (1 - br) * 0.8 * u), _qBodyRx(c) * (2 - br),
      _qBodyRy(c) * br, c.body, c.ink, c.inkW);

  // Животик.
  p.ellipse(
      cv,
      bodyC + Offset(0.4 * u, 0.7 * u),
      _qBodyRx(c) * 0.58,
      _qBodyRy(c) * 0.42,
      c.belly,
      Colors.transparent,
      0);

  // Детали спины.
  if (c.spec.extras.contains('spikesBack')) _quadSpikes(cv, p, c);
  if (c.spec.extras.contains('spots')) {
    for (final Offset s in <Offset>[
      Offset(0.7 * u, -5.6 * u),
      Offset(-0.5 * u, -5.95 * u),
      Offset(-1.5 * u, -5.6 * u),
    ]) {
      p.dot(cv, s, 0.24 * u, Colors.white.withOpacity(0.85));
    }
  }

  // Шея.
  final Offset base = _qNeckBase(c);
  final Offset headC = _qHeadC(c, c.headPitch);
  final double theta = math.atan2(headC.dy - base.dy, headC.dx - base.dx);
  p.shape(
      cv,
      capsulePath(base + Offset(-0.2 * u, 0.3 * u), 0.85 * u,
          headC - Offset(math.cos(theta), math.sin(theta)) * 0.9 * u, 0.7 * u),
      c.body,
      c.ink,
      c.inkW);

  // Голова.
  _quadHead(cv, p, c, headC, math.max(0, theta) * 0.9);

  // Ближняя пара лап.
  _quadLeg(cv, p, c, Offset(-1.9 * u, -4.7 * u), c.stride, c.body);
  _quadLeg(cv, p, c, Offset(2.0 * u, -4.7 * u), c.stride, c.body);

  // Гардероб на шее.
  _accNeck(cv, p, c, Offset(2.35 * u, -5.15 * u));
}

/// Хвост quad-зверя (в корпусном пространстве).
void _quadTail(Canvas cv, _P p, _Ctx c, Offset bodyC) {
  final double u = c.u;
  final Offset rump = Offset(-2.6 * u, -4.9 * u);
  final String tail = c.spec.tail;
  if (tail == 'bushy') {
    // Лиса/енот: назад; белка: вверх.
    final bool up = c.pet.type == PetType.squirrel;
    final Offset tip = up ? Offset(-3.8 * u, -8.4 * u) : Offset(-5.6 * u, -5.2 * u);
    cv.save();
    cv.translate(rump.dx, rump.dy);
    cv.rotate(c.wag * 0.5);
    cv.translate(-rump.dx, -rump.dy);
    p.shape(cv, leafPath(rump, tip, 1.25 * u), c.body, c.ink, c.inkW);
    p.dot(cv, tip + Offset(-0.1 * u, 0.25 * u), 0.6 * u, c.belly);
    if (c.spec.extras.contains('rings')) {
      for (final double t in <double>[0.35, 0.62]) {
        final Offset m = Offset(
            rump.dx + (tip.dx - rump.dx) * t, rump.dy + (tip.dy - rump.dy) * t);
        p.line(cv, m - Offset(0, 0.9 * u), m + Offset(0, 0.9 * u),
            cartoonShade(c.body), 0.5 * u);
      }
    }
    cv.restore();
  } else if (tail == 'cat') {
    final Path cur = Path()
      ..moveTo(-2.7 * u, -4.8 * u)
      ..quadraticBezierTo(-4.3 * u, -5.2 * u, -4.2 * u, -7.2 * u)
      ..quadraticBezierTo(-4.15 * u, -8.1 * u, -3.5 * u, -8.2 * u);
    cv.save();
    cv.translate(-2.7 * u, -4.8 * u);
    cv.rotate(c.wag * 0.4);
    cv.translate(2.7 * u, 4.8 * u);
    p.tube(cv, cur, c.body, c.ink, 0.75 * u);
    p.dot(cv, Offset(-3.5 * u, -8.2 * u), 0.4 * u, c.accent);
    cv.restore();
  } else if (tail == 'long') {
    cv.save();
    cv.translate(rump.dx, rump.dy);
    cv.rotate(c.wag);
    cv.translate(-rump.dx, -rump.dy);
    p.shape(cv, leafPath(rump, Offset(-4.4 * u, -6.1 * u), 0.45 * u), c.body,
        c.ink, c.inkW * 0.8);
    cv.restore();
  } else if (tail == 'mane') {
    cv.save();
    cv.translate(rump.dx, rump.dy);
    cv.rotate(c.wag * 0.6);
    cv.translate(-rump.dx, -rump.dy);
    p.shape(cv, leafPath(rump, Offset(-4.9 * u, -7.4 * u), 0.85 * u), c.accent,
        c.ink, c.inkW * 0.8);
    p.shape(cv, leafPath(rump, Offset(-4.3 * u, -6.4 * u), 0.55 * u),
        const Color(0xFFFFD166), Colors.transparent, 0);
    cv.restore();
  } else if (tail == 'curl') {
    final Path cur = Path()
      ..moveTo(-3.0 * u, -4.7 * u)
      ..quadraticBezierTo(-4.0 * u, -5.4 * u, -3.6 * u, -4.2 * u)
      ..quadraticBezierTo(-3.3 * u, -3.4 * u, -2.9 * u, -4.0 * u);
    p.tube(cv, cur, c.body, c.ink, 0.42 * u);
  } else if (tail == 'puff') {
    p.circle(cv, Offset(-3.15 * u, -4.95 * u), 0.58 * u, c.body, c.ink, c.inkW * 0.8);
  }
}

/// Шипы на спине (ёжик, дракон).
void _quadSpikes(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  for (int i = 0; i < 7; i++) {
    final double t = i / 6;
    final double x = 1.5 * u - t * 4.0 * u;
    final double y = -6.0 * u + math.sin(t * math.pi) * 0.25 * u;
    final Path tri = Path()
      ..moveTo(x - 0.42 * u, y + 0.25 * u)
      ..lineTo(x, y - 1.05 * u + (i.isOdd ? 0.18 * u : 0))
      ..lineTo(x + 0.42 * u, y + 0.25 * u)
      ..close();
    p.shape(cv, tri, c.dark, c.ink, c.inkW * 0.7);
  }
}

/// Голова quad: уши, морда, глаз, нос, аксессуары.
void _quadHead(Canvas cv, _P p, _Ctx c, Offset headC, double rot) {
  final double u = c.u;
  final double headR = 1.55 * u;
  cv.save();
  cv.translate(headC.dx, headC.dy);
  cv.rotate(rot);

  // Уши: дальнее (тень) → голова → ближнее.
  _quadEars(cv, p, c, far: true);
  p.circle(cv, Offset.zero, headR, c.body, c.ink, c.inkW);
  // Горбик черепа чуть светлее сверху.
  p.dot(cv, Offset(-0.3 * u, -0.7 * u), 0.55 * u, Colors.white.withOpacity(0.12));

  // Рога/грива до морды.
  if (c.spec.extras.contains('antlers')) {
    final Color ant = c.accent == c.belly ? const Color(0xFFA87A4F) : c.accent;
    for (final double side in const <double>[-0.3, 0.45]) {
      final Offset root = Offset(side * u, -1.25 * u);
      final Path main = Path()
        ..moveTo(root.dx, root.dy)
        ..lineTo(root.dx + 0.35 * u, root.dy - 1.5 * u)
        ..moveTo(root.dx + 0.18 * u, root.dy - 0.75 * u)
        ..lineTo(root.dx + 0.95 * u, root.dy - 1.15 * u)
        ..moveTo(root.dx + 0.28 * u, root.dy - 1.15 * u)
        ..lineTo(root.dx + 0.8 * u, root.dy - 1.85 * u);
      cv.drawPath(main, p.stroke(ant, 0.34 * u));
    }
  }
  if (c.spec.extras.contains('horn')) {
    final Path horn = Path()
      ..moveTo(0.15 * u, -1.2 * u)
      ..lineTo(0.45 * u, -1.3 * u)
      ..lineTo(0.75 * u, -2.6 * u)
      ..close();
    p.shape(cv, horn, const Color(0xFFFFC800), c.ink, c.inkW * 0.6);
    p.line(cv, Offset(0.33 * u, -1.65 * u), Offset(0.58 * u, -1.7 * u),
        const Color(0xFFE09E00), 0.2 * u);
    // Грива-чёлка.
    p.shape(cv, leafPath(Offset(-0.4 * u, -1.35 * u), Offset(0.5 * u, -1.7 * u), 0.5 * u),
        c.accent, c.ink, c.inkW * 0.5);
    p.shape(cv, leafPath(Offset(-1.1 * u, -0.9 * u), Offset(-0.1 * u, -1.5 * u), 0.45 * u),
        const Color(0xFFFFD166), Colors.transparent, 0);
  }

  // Морда.
  _quadMuzzle(cv, p, c);

  // Маска енота / панды — до глаза.
  if (c.spec.extras.contains('mask')) {
    if (c.pet.type == PetType.panda) {
      p.ellipse(cv, Offset(0.5 * u, 0.02 * u), 0.62 * u, 0.72 * u, c.dark,
          Colors.transparent, 0, rot: 0.25);
    } else {
      // Енот: тёмная полоса через глаза.
      p.shape(
          cv,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(0.55 * u, 0.05 * u), width: 1.9 * u, height: 0.75 * u),
                const Radius.circular(0.4 * u))),
          c.dark,
          Colors.transparent,
          0);
    }
  }

  // Глаз.
  _eyeProfile(cv, p, c, Offset(0.5 * u, 0.0), 0.52 * u);

  // Румянец + блик.
  _blush(cv, p, Offset(0.1 * u, 0.62 * u), 0.34 * u);

  // Гардероб на голове.
  _accFace(cv, p, c, Offset(0.5 * u, 0.0));
  _accHat(cv, p, c, Offset(0, -headR - 0.15 * u));

  // Ближнее ухо поверх.
  _quadEars(cv, p, c, far: false);
  cv.restore();
}

void _quadEars(Canvas cv, _P p, _Ctx c, {required bool far}) {
  final double u = c.u;
  final String ear = c.spec.ear;
  final double bounce = c.walking ? math.sin(c.stride * 2) * 0.08 : math.sin(c.tSec * 1.4) * 0.03;
  switch (ear) {
    case 'pointy':
      final Path tri(double x, double rot, double s) => Path()
        ..moveTo(x - 0.42 * u * s, -0.95 * u)
        ..lineTo(x + 0.15 * u, -2.35 * u * s)
        ..lineTo(x + 0.55 * u * s, -0.85 * u)
        ..close();
      if (far) {
        cv.save();
        cv.translate(-0.55 * u, -0.95 * u);
        cv.rotate(-0.25 + bounce);
        cv.translate(0.55 * u, 0.95 * u);
        p.shape(cv, tri(-0.55 * u, -0.25, 0.9), cartoonShade(c.body), c.ink, c.inkW * 0.7);
        cv.restore();
      } else {
        cv.save();
        cv.translate(0.15 * u, -0.95 * u);
        cv.rotate(0.12 + bounce);
        cv.translate(-0.15 * u, 0.95 * u);
        p.shape(cv, tri(0.15 * u, 0.12, 1.0), c.body, c.ink, c.inkW);
        p.shape(
            cv,
            Path()
              ..moveTo(0.0 * u, -1.15 * u)
              ..lineTo(0.16 * u, -1.95 * u)
              ..lineTo(0.38 * u, -1.05 * u)
              ..close(),
            c.accent,
            Colors.transparent,
            0);
        cv.restore();
      }
      break;
    case 'round':
      final Color col = far ? cartoonShade(c.body) : (c.pet.type == PetType.panda ? c.dark : c.body);
      if (far) {
        p.circle(cv, Offset(-0.72 * u, -1.15 * u), 0.72 * u, col, c.ink, c.inkW * 0.7);
      } else {
        p.circle(cv, Offset(0.5 * u + (c.pet.type == PetType.koala ? 0.25 * u : 0), -1.2 * u),
            (c.pet.type == PetType.koala ? 0.95 : 0.75) * u, col, c.ink, c.inkW);
        if (c.accent != c.belly || c.pet.type == PetType.koala) {
          p.dot(cv, Offset(0.5 * u, -1.2 * u), 0.42 * u, c.accent);
        }
      }
      break;
    case 'floppy':
      if (far) {
        p.shape(cv, capsulePath(Offset(-0.5 * u, -1.1 * u), 0.4 * u, Offset(-1.15 * u, 0.1 * u), 0.42 * u),
            cartoonShade(c.body), c.ink, c.inkW * 0.7);
      } else {
        final Color col = c.pet.type == PetType.dog ? c.accent : cartoonShade(c.body);
        cv.save();
        cv.translate(0.35 * u, -1.05 * u);
        cv.rotate(0.1 + bounce * 1.5);
        p.shape(cv, capsulePath(Offset.zero, 0.42 * u, Offset(0.1 * u, 1.3 * u), 0.46 * u),
            col, c.ink, c.inkW);
        cv.restore();
      }
      break;
    case 'long':
      if (far) {
        p.ellipse(cv, Offset(-0.85 * u, -1.0 * u), 0.72 * u, 0.34 * u,
            cartoonShade(c.body), c.ink, c.inkW * 0.6, rot: -0.75);
      } else {
        cv.save();
        cv.translate(0.35 * u, -1.1 * u);
        cv.rotate(0.45 + bounce);
        p.ellipse(cv, Offset.zero, 0.78 * u, 0.36 * u, c.body, c.ink, c.inkW);
        p.ellipse(cv, Offset(0.06 * u, 0), 0.4 * u, 0.16 * u, c.belly, Colors.transparent, 0);
        cv.restore();
      }
      break;
    case 'tufts':
      if (!far) {
        p.shape(cv, leafPath(Offset(-0.15 * u, -1.3 * u), Offset(-0.45 * u, -2.15 * u), 0.22 * u),
            c.body, c.ink, c.inkW * 0.6);
        p.shape(cv, leafPath(Offset(0.35 * u, -1.35 * u), Offset(0.65 * u, -2.1 * u), 0.22 * u),
            c.body, c.ink, c.inkW * 0.6);
      }
      break;
    default:
      break;
  }
}

void _quadMuzzle(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  switch (c.spec.muzzle) {
    case 'fox':
      final Path wedge = Path()
        ..moveTo(0.25 * u, -0.35 * u)
        ..quadraticBezierTo(1.3 * u, -0.15 * u, 1.75 * u, 0.22 * u)
        ..quadraticBezierTo(1.15 * u, 0.8 * u, 0.3 * u, 0.75 * u)
        ..close();
      p.shape(cv, wedge, c.belly, c.ink, c.inkW * 0.7);
      p.dot(cv, Offset(1.62 * u, 0.18 * u), 0.21 * u, c.ink);
      _mouth(cv, p, c, Offset(1.15 * u, 0.6 * u), 0.55 * u);
      break;
    case 'cat':
      p.ellipse(cv, Offset(0.85 * u, 0.42 * u), 0.55 * u, 0.42 * u, c.belly,
          Colors.transparent, 0);
      final Path nose = Path()
        ..moveTo(0.82 * u, 0.02 * u)
        ..lineTo(1.12 * u, 0.02 * u)
        ..lineTo(0.97 * u, 0.22 * u)
        ..close();
      p.shape(cv, nose, c.accent, c.ink, c.inkW * 0.35);
      for (final double dy in const <double>[-0.12, 0.1]) {
        p.line(cv, Offset(1.15 * u, 0.28 * u + dy * u), Offset(1.7 * u, 0.18 * u + dy * u * 2.2),
            c.ink, c.inkW * 0.35);
      }
      _mouth(cv, p, c, Offset(0.97 * u, 0.42 * u), 0.5 * u);
      break;
    case 'bear':
      p.circle(cv, Offset(0.85 * u, 0.4 * u), 0.72 * u, c.belly, c.ink, c.inkW * 0.55);
      p.ellipse(cv, Offset(1.05 * u, 0.2 * u), 0.26 * u, 0.2 * u, c.ink, Colors.transparent, 0);
      _mouth(cv, p, c, Offset(1.0 * u, 0.55 * u), 0.5 * u);
      break;
    case 'long':
      p.shape(cv, capsulePath(Offset(0.3 * u, 0.2 * u), 0.62 * u, Offset(1.75 * u, 0.4 * u), 0.42 * u),
          c.belly, c.ink, c.inkW * 0.6);
      p.dot(cv, Offset(1.62 * u, 0.32 * u), 0.13 * u, c.ink);
      _mouth(cv, p, c, Offset(1.35 * u, 0.68 * u), 0.5 * u);
      break;
    case 'snout':
      p.ellipse(cv, Offset(1.0 * u, 0.3 * u), 0.6 * u, 0.48 * u, c.accent, c.ink, c.inkW * 0.6);
      p.dot(cv, Offset(0.85 * u, 0.28 * u), 0.09 * u, c.ink);
      p.dot(cv, Offset(1.16 * u, 0.28 * u), 0.09 * u, c.ink);
      break;
    case 'flat':
      p.ellipse(cv, Offset(0.85 * u, 0.16 * u), 0.3 * u, 0.22 * u,
          c.pet.type == PetType.koala ? c.ink : c.accent, Colors.transparent, 0);
      p.line(cv, Offset(0.82 * u, 0.4 * u), Offset(0.88 * u, 0.55 * u), c.ink, c.inkW * 0.4);
      p.line(cv, Offset(0.88 * u, 0.55 * u), Offset(1.0 * u, 0.62 * u), c.ink, c.inkW * 0.4);
      p.line(cv, Offset(0.88 * u, 0.55 * u), Offset(0.76 * u, 0.62 * u), c.ink, c.inkW * 0.4);
      if (c.pet.type == PetType.bunny) {
        for (final double dy in const <double>[-0.1, 0.12]) {
          p.line(cv, Offset(1.05 * u, 0.3 * u + dy * u), Offset(1.6 * u, 0.2 * u + dy * u * 2.4),
              c.ink, c.inkW * 0.35);
        }
      }
      break;
    default:
      break;
  }
}

/// Сон quad: лежит, морда на лапах, хвост пушистый вокруг.
void _quadSleep(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  final double br = c.breath;

  // Хвост вокруг перед лап.
  if (c.spec.tail == 'bushy' || c.spec.tail == 'mane') {
    p.shape(cv, leafPath(Offset(-2.2 * u, -1.5 * u), Offset(1.2 * u, -0.55 * u), 0.8 * u),
        c.spec.tail == 'mane' ? c.accent : c.body, c.ink, c.inkW * 0.8);
    p.dot(cv, Offset(1.15 * u, -0.6 * u), 0.42 * u, c.belly);
  } else if (c.spec.tail == 'long') {
    p.shape(cv, leafPath(Offset(-2.2 * u, -1.3 * u), Offset(0.6 * u, -0.5 * u), 0.4 * u),
        c.body, c.ink, c.inkW * 0.7);
  }

  // Корпус лежит.
  p.ellipse(cv, Offset(-0.1 * u, -1.3 * u), 3.15 * u * (2 - br) * 0.92,
      1.2 * u * br, c.body, c.ink, c.inkW);
  p.ellipse(cv, Offset(-0.4 * u, -0.9 * u), 2.2 * u, 0.72 * u, c.belly,
      Colors.transparent, 0);
  if (c.spec.extras.contains('spikesBack')) {
    for (int i = 0; i < 5; i++) {
      final double x = (0.9 - i * 1.05) * u;
      final Path tri = Path()
        ..moveTo(x - 0.4 * u, -2.15 * u)
        ..lineTo(x, -3.0 * u)
        ..lineTo(x + 0.4 * u, -2.15 * u)
        ..close();
      p.shape(cv, tri, c.dark, c.ink, c.inkW * 0.6);
    }
  }

  // Сложенные лапки.
  p.shape(cv, capsulePath(Offset(1.9 * u, -0.5 * u), 0.42 * u, Offset(3.2 * u, -0.5 * u), 0.36 * u),
      c.body, c.ink, c.inkW * 0.8);

  // Голова на лапах.
  p.circle(cv, Offset(2.9 * u, -1.5 * u), 1.32 * u, c.body, c.ink, c.inkW);
  cv.save();
  cv.translate(2.9 * u, -1.5 * u);
  cv.rotate(0.25);
  _quadEars(cv, p, c, far: true);
  _quadMuzzleSleep(cv, p, c);
  _eyeProfile(cv, p, c, Offset(0.5 * u, 0.0), 0.5 * u);
  _blush(cv, p, Offset(0.05 * u, 0.6 * u), 0.32 * u);
  _quadEars(cv, p, c, far: false);
  cv.restore();
}

void _quadMuzzleSleep(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  switch (c.spec.muzzle) {
    case 'fox':
      final Path wedge = Path()
        ..moveTo(0.2 * u, -0.3 * u)
        ..quadraticBezierTo(1.1 * u, -0.1 * u, 1.5 * u, 0.25 * u)
        ..quadraticBezierTo(1.0 * u, 0.65 * u, 0.25 * u, 0.62 * u)
        ..close();
      p.shape(cv, wedge, c.belly, c.ink, c.inkW * 0.6);
      p.dot(cv, Offset(1.4 * u, 0.2 * u), 0.18 * u, c.ink);
      break;
    case 'bear':
      p.circle(cv, Offset(0.8 * u, 0.35 * u), 0.62 * u, c.belly, c.ink, c.inkW * 0.5);
      p.ellipse(cv, Offset(0.95 * u, 0.18 * u), 0.22 * u, 0.17 * u, c.ink, Colors.transparent, 0);
      break;
    case 'long':
      p.shape(cv, capsulePath(Offset(0.25 * u, 0.15 * u), 0.55 * u, Offset(1.6 * u, 0.35 * u), 0.38 * u),
          c.belly, c.ink, c.inkW * 0.55);
      break;
    case 'snout':
      p.ellipse(cv, Offset(0.95 * u, 0.28 * u), 0.55 * u, 0.44 * u, c.accent, c.ink, c.inkW * 0.55);
      break;
    default:
      p.ellipse(cv, Offset(0.8 * u, 0.15 * u), 0.26 * u, 0.2 * u, c.ink, Colors.transparent, 0);
      break;
  }
}

/// Сидящая поза (собачкой): круп на земле, передние лапы прямо.
void _paintQuadSit(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  final double br = c.breath;

  // Хвост на земле.
  if (c.spec.tail == 'bushy' || c.spec.tail == 'mane') {
    p.shape(cv, leafPath(Offset(-1.9 * u, -0.9 * u), Offset(0.9 * u, -0.5 * u), 0.85 * u),
        c.spec.tail == 'mane' ? c.accent : c.body, c.ink, c.inkW * 0.8);
    p.dot(cv, Offset(0.85 * u, -0.55 * u), 0.45 * u, c.belly);
  } else if (c.spec.tail == 'long') {
    cv.save();
    cv.translate(-1.9 * u, -1.0 * u);
    cv.rotate(c.wag * 1.2);
    p.shape(cv, leafPath(Offset.zero, Offset(2.6 * u, -0.4 * u), 0.42 * u), c.body,
        c.ink, c.inkW * 0.7);
    cv.restore();
  } else if (c.spec.tail == 'cat') {
    cv.save();
    cv.translate(-1.9 * u, -1.0 * u);
    cv.rotate(c.wag * 0.8);
    final Path cur = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-1.6 * u, -0.4 * u, -2.4 * u, -1.8 * u);
    p.tube(cv, cur, c.body, c.ink, 0.7 * u);
    p.dot(cv, Offset(-2.4 * u, -1.8 * u), 0.38 * u, c.accent);
    cv.restore();
  }

  // Сложенная задняя лапа.
  p.shape(cv, capsulePath(Offset(-1.5 * u, -2.4 * u), 0.62 * u, Offset(-0.1 * u, -1.5 * u), 0.5 * u),
      c.body, c.ink, c.inkW);
  p.shape(cv, capsulePath(Offset(-0.1 * u, -1.5 * u), 0.42 * u, Offset(-0.35 * u, -0.45 * u), 0.38 * u),
      c.body, c.ink, c.inkW);
  p.circle(cv, Offset(-0.4 * u, -0.35 * u), 0.42 * u, c.body, c.ink, c.inkW);

  // Корпус наклонно: круп низко, грудь вверх.
  cv.save();
  cv.translate(-1.7 * u, -1.6 * u);
  cv.rotate(-0.52);
  p.ellipse(cv, Offset(0.2 * u, -1.55 * u * br), _qBodyRx(c) * 0.95 * (2 - br),
      _qBodyRy(c) * br, c.body, c.ink, c.inkW);
  p.ellipse(cv, Offset(0.5 * u, -0.8 * u), _qBodyRx(c) * 0.55, _qBodyRy(c) * 0.45,
      c.belly, Colors.transparent, 0);
  cv.restore();

  // Передние лапы прямо.
  for (final double dx in const <double>[-0.25, 0]) {
    p.shape(
        cv,
        capsulePath(Offset(1.55 * u + dx * u, -4.1 * u), 0.4 * u,
            Offset(1.62 * u + dx * u, -0.45 * u), 0.36 * u),
        dx < 0 ? cartoonShade(c.body) : c.body,
        c.ink,
        c.inkW);
    p.circle(cv, Offset(1.66 * u + dx * u, -0.4 * u), 0.44 * u,
        dx < 0 ? cartoonShade(c.body) : c.body, c.ink, c.inkW);
  }

  // Шея и голова.
  final Offset base = Offset(2.1 * u, -5.0 * u);
  final double pitch = c.headPitch * 0.35 + 0.12;
  final double theta = -0.85 + pitch;
  final Offset headC = base + Offset(math.cos(theta), math.sin(theta)) * 1.8 * u;
  p.shape(cv, capsulePath(base, 0.8 * u, headC, 0.68 * u), c.body, c.ink, c.inkW);
  _quadHead(cv, p, c, headC, math.max(0, pitch) * 0.9);
  _accNeck(cv, p, c, Offset(1.95 * u, -4.6 * u));
}

// ── ПТИЦЫ ──────────────────────────────────────────────────────────────

void _paintBird(Canvas cv, _Ctx c) {
  final double u = c.u;
  if (c.sleeping) {
    _birdSleep(cv, _P(1, c.inkW), c);
    return;
  }
  final bool isOwl = c.pet.type == PetType.owl;
  final bool isPenguin = c.pet.type == PetType.penguin;

  // Клюёт — весь корпус наклоняется вперёд.
  final double peck = c.kind == 'peck' ? c.headPitch : 0;
  cv.save();
  if (peck > 0.01) {
    cv.translate(1.0 * u, -0.6 * u);
    cv.rotate(peck * 0.5);
    cv.translate(-1.0 * u, 0.6 * u);
  }
  // Переваливание при ходьбе.
  cv.translate(0, 0);
  cv.rotate(c.walking ? math.sin(c.stride) * 0.05 : 0);

  // Лапки.
  final Color legC = isPenguin ? c.accent : cartoonShade(c.accent);
  for (final double dx in const <double>[-0.8, 0.8]) {
    final double lift = c.walking
        ? math.max(0, math.sin(c.stride + (dx > 0 ? 0 : math.pi))) * 0.5 * u
        : 0;
    p.shape(
        cv,
        capsulePath(Offset(dx * u, -1.2 * u), 0.24 * u,
            Offset(dx * u * 1.15, -0.3 * u - lift), 0.22 * u),
        legC,
        c.ink,
        c.inkW * 0.7);
    // Пальчики.
    p.line(cv, Offset(dx * u * 1.15, -0.3 * u - lift), Offset(dx * u * 1.15 + 0.4 * u, -lift),
        c.ink, c.inkW * 0.6);
    p.line(cv, Offset(dx * u * 1.15, -0.3 * u - lift), Offset(dx * u * 1.15 - 0.15 * u, -lift),
        c.ink, c.inkW * 0.6);
  }

  // Хвост-веер.
  if (c.spec.tail == 'plume') {
    for (final double ang in const <double>[-0.5, 0, 0.5]) {
      cv.save();
      cv.translate(-1.9 * u, -3.4 * u);
      cv.rotate(ang);
      p.shape(cv, leafPath(Offset.zero, Offset(-1.6 * u, 0.4 * u), 0.42 * u),
          cartoonShade(c.body), c.ink, c.inkW * 0.7);
      cv.restore();
    }
  } else if (c.spec.tail == 'flat') {
    cv.save();
    cv.translate(-2.0 * u, -4.4 * u);
    cv.rotate(-0.5 + c.wag * 0.8);
    p.shape(cv, leafPath(Offset.zero, Offset(-1.4 * u, -0.5 * u), 0.55 * u), c.body,
        c.ink, c.inkW * 0.8);
    cv.restore();
  }

  // Тело-яйцо.
  final double br = c.breath;
  p.ellipse(cv, Offset(0, -4.0 * u), 2.45 * u, 3.15 * u * br, c.body, c.ink, c.inkW);

  // Животик.
  if (isPenguin) {
    p.ellipse(cv, Offset(0.35 * u, -3.6 * u), 1.7 * u, 2.5 * u, c.belly, Colors.transparent, 0);
    // Лицо-пятно.
    p.circle(cv, Offset(0.55 * u, -6.5 * u), 1.25 * u, c.belly, Colors.transparent, 0);
  } else {
    p.ellipse(cv, Offset(0.3 * u, -3.7 * u), 1.65 * u, 2.3 * u, c.belly, Colors.transparent, 0);
    if (isOwl) {
      // Пёрышки на животе.
      for (final Offset o in <Offset>[
        Offset(-0.1 * u, -3.4 * u),
        Offset(0.7 * u, -4.2 * u),
        Offset(0.2 * u, -4.9 * u),
      ]) {
        final Path v = Path()
          ..moveTo(o.dx - 0.22 * u, o.dy - 0.2 * u)
          ..lineTo(o.dx, o.dy + 0.12 * u)
          ..lineTo(o.dx + 0.22 * u, o.dy - 0.2 * u);
        cv.drawPath(v, p.stroke(cartoonShade(c.belly), c.inkW * 0.4));
      }
    }
  }

  // Хохолок цыплёнка.
  if (c.spec.ear == 'tuft') {
    for (final double dx in const <double>[-0.25, 0.05, 0.35]) {
      p.line(cv, Offset(dx * u, -7.2 * u), Offset(dx * u + 0.18 * u, -7.9 * u),
          c.accent, 0.28 * u);
    }
  }

  // Крыло.
  cv.save();
  cv.translate(-0.5 * u, -4.3 * u);
  cv.rotate(c.kind == 'peck' ? -c.headPitch * 0.4 : math.sin(c.tSec * 1.8) * 0.04);
  p.ellipse(cv, Offset(-0.15 * u, 0.2 * u), 1.05 * u, 1.75 * u,
      isPenguin ? c.dark : cartoonShade(c.body), c.ink, c.inkW * 0.8, rot: 0.3);
  cv.restore();

  // Голова/лицо.
  if (isOwl) {
    // Лицевой диск.
    p.circle(cv, Offset(0.35 * u, -6.7 * u), 1.9 * u, c.body, c.ink, c.inkW * 0.8);
    // Совиные ушки.
    for (final double dx in const <double>[-0.85, 0.95]) {
      final Path tuft = Path()
        ..moveTo(dx * u - 0.3 * u, -7.9 * u)
        ..lineTo(dx * u + 0.1 * u, -9.1 * u)
        ..lineTo(dx * u + 0.42 * u, -7.7 * u)
        ..close();
      p.shape(cv, tuft, c.body, c.ink, c.inkW * 0.6);
    }
    _eyesFront(cv, p, c, <Offset>[Offset(-0.15 * u, -6.85 * u), Offset(0.95 * u, -6.75 * u)],
        0.68 * u);
    // Клюв.
    final Path beak = Path()
      ..moveTo(0.28 * u, -6.1 * u)
      ..lineTo(0.78 * u, -6.1 * u)
      ..lineTo(0.53 * u, -5.45 * u)
      ..close();
    p.shape(cv, beak, c.accent, c.ink, c.inkW * 0.55);
    _blush(cv, p, Offset(-0.75 * u, -5.9 * u), 0.34 * u);
    _blush(cv, p, Offset(1.45 * u, -5.85 * u), 0.3 * u);
    _accFace(cv, p, c, Offset(0.95 * u, -6.75 * u));
    _accHat(cv, p, c, Offset(0.1 * u, -8.65 * u));
  } else {
    // Утка/цыплёнок/пингвин: голова слита с телом, глаз + клюв.
    if (!isPenguin) {
      p.circle(cv, Offset(0.55 * u, -6.9 * u), 1.5 * u, c.body, c.ink, c.inkW);
    }
    if (c.spec.ear == 'tufts') {
      // Уточка: маленький хохолок.
      p.shape(cv, leafPath(Offset(0.35 * u, -8.2 * u), Offset(0.15 * u, -8.9 * u), 0.2 * u),
          c.body, c.ink, c.inkW * 0.5);
    }
    _eyeProfile(cv, p, c, Offset(0.85 * u, -7.15 * u), 0.5 * u);
    // Клюв плоский.
    p.ellipse(cv, Offset(1.85 * u, -6.85 * u), 0.72 * u, 0.26 * u, c.accent, c.ink,
        c.inkW * 0.55, rot: 0.06);
    p.ellipse(cv, Offset(1.8 * u, -6.6 * u), 0.5 * u, 0.16 * u,
        Color.lerp(c.accent, Colors.black, 0.12)!, Colors.transparent, 0);
    _blush(cv, p, Offset(0.35 * u, -6.45 * u), 0.3 * u);
    _accFace(cv, p, c, Offset(0.85 * u, -7.15 * u));
    _accHat(cv, p, c, Offset(0.4 * u, -8.45 * u));
  }

  // Гардероб на шее-теле.
  _accNeck(cv, p, c, Offset(0.1 * u, -2.2 * u));
  cv.restore();
}

void _birdSleep(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  final bool isPenguin = c.pet.type == PetType.penguin;
  final double br = c.breath;
  // Сидит, поджав лапы, голова чуть в плечо.
  p.ellipse(cv, Offset(0, -1.75 * u), 2.2 * u, 1.75 * u * br, c.body, c.ink, c.inkW);
  if (isPenguin) {
    p.ellipse(cv, Offset(0.3 * u, -1.5 * u), 1.55 * u, 1.3 * u, c.belly, Colors.transparent, 0);
  }
  // Сложенное крыло.
  p.ellipse(cv, Offset(-0.55 * u, -1.9 * u), 0.95 * u, 1.1 * u,
      isPenguin ? c.dark : cartoonShade(c.body), c.ink, c.inkW * 0.7, rot: 0.3);
  // Голова.
  if (c.pet.type == PetType.owl) {
    p.circle(cv, Offset(0.5 * u, -3.1 * u), 1.5 * u, c.body, c.ink, c.inkW);
    _eyesFront(cv, p, c, <Offset>[Offset(0.2 * u, -3.25 * u), Offset(1.0 * u, -3.15 * u)],
        0.5 * u);
    final Path beak = Path()
      ..moveTo(0.42 * u, -2.75 * u)
      ..lineTo(0.82 * u, -2.75 * u)
      ..lineTo(0.62 * u, -2.25 * u)
      ..close();
    p.shape(cv, beak, c.accent, c.ink, c.inkW * 0.5);
  } else {
    p.circle(cv, Offset(0.7 * u, -3.0 * u), 1.25 * u, c.body, c.ink, c.inkW);
    _eyeProfile(cv, p, c, Offset(0.95 * u, -3.15 * u), 0.42 * u);
    p.ellipse(cv, Offset(1.75 * u, -2.95 * u), 0.6 * u, 0.22 * u, c.accent, c.ink,
        c.inkW * 0.5, rot: 0.1);
  }
  _blush(cv, p, Offset(0.35 * u, -2.6 * u), 0.28 * u);
}

// ── ПРЫГУНЫ ────────────────────────────────────────────────────────────

void _paintHop(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  if (c.pet.type == PetType.frog) {
    _frog(cv, p, c);
    return;
  }
  // Зайчик.
  final double br = c.breath;
  if (c.sleeping) {
    // Лежит на боку, уши вдоль спины.
    p.ellipse(cv, Offset(0.2 * u, -1.15 * u), 2.5 * u, 1.1 * u * br, c.body, c.ink, c.inkW);
    p.shape(cv, leafPath(Offset(2.4 * u, -1.8 * u), Offset(-0.6 * u, -2.5 * u), 0.45 * u),
        c.body, c.ink, c.inkW * 0.7);
    p.shape(cv, leafPath(Offset(2.5 * u, -1.5 * u), Offset(-0.2 * u, -2.75 * u), 0.42 * u),
        c.body, c.ink, c.inkW * 0.7);
    p.circle(cv, Offset(2.6 * u, -1.5 * u), 1.15 * u, c.body, c.ink, c.inkW);
    _eyeProfile(cv, p, c, Offset(3.0 * u, -1.7 * u), 0.42 * u);
    p.ellipse(cv, Offset(3.4 * u, -1.3 * u), 0.24 * u, 0.18 * u, c.accent, Colors.transparent, 0);
    p.circle(cv, Offset(-2.1 * u, -1.5 * u), 0.6 * u, c.belly, c.ink, c.inkW * 0.6);
    return;
  }

  // Пушистый хвост.
  p.circle(cv, Offset(-2.75 * u, -2.7 * u), 0.72 * u, c.belly, c.ink, c.inkW * 0.7);
  // Задняя лапа-бедро.
  p.circle(cv, Offset(-1.1 * u, -2.3 * u), 1.75 * u, c.body, c.ink, c.inkW);
  // Ступня большой задней лапы.
  final double kick = c.walking ? math.sin(c.stride) * 0.18 : 0;
  cv.save();
  cv.translate(-0.4 * u, -0.9 * u);
  cv.rotate(kick);
  p.shape(cv, capsulePath(Offset.zero, 0.48 * u, Offset(1.5 * u, -0.1 * u), 0.42 * u),
      c.belly, c.ink, c.inkW * 0.8);
  cv.restore();
  // Тело-капля.
  p.ellipse(cv, Offset(0.35 * u, -4.1 * u * br), 2.15 * u * (2 - br), 2.35 * u * br,
      c.body, c.ink, c.inkW);
  p.ellipse(cv, Offset(0.55 * u, -2.6 * u), 1.4 * u, 1.15 * u, c.belly, Colors.transparent, 0);
  // Передние лапки.
  p.shape(cv, capsulePath(Offset(2.1 * u, -1.3 * u), 0.32 * u, Offset(2.4 * u, -0.4 * u), 0.3 * u),
      c.body, c.ink, c.inkW * 0.8);
  // Голова.
  p.circle(cv, Offset(1.9 * u, -6.5 * u), 1.6 * u, c.body, c.ink, c.inkW);
  // Уши: дальнее и ближнее, пружинят при прыжке.
  final double bounce = c.walking ? math.sin(c.stride * 2) * 0.12 : math.sin(c.tSec * 1.3) * 0.04;
  cv.save();
  cv.translate(1.35 * u, -7.7 * u);
  cv.rotate(-0.22 + bounce);
  p.shape(cv, capsulePath(Offset.zero, 0.44 * u, Offset(-0.15 * u, -2.5 * u), 0.36 * u),
      cartoonShade(c.body), c.ink, c.inkW * 0.8);
  cv.restore();
  cv.save();
  cv.translate(2.0 * u, -7.85 * u);
  cv.rotate(0.1 + bounce);
  p.shape(cv, capsulePath(Offset.zero, 0.48 * u, Offset(0.25 * u, -2.6 * u), 0.4 * u),
      c.body, c.ink, c.inkW);
  p.shape(cv, capsulePath(Offset(0.06 * u, -0.35 * u), 0.22 * u, Offset(0.22 * u, -2.15 * u), 0.18 * u),
      c.accent, Colors.transparent, 0);
  cv.restore();
  // Морда.
  _eyeProfile(cv, p, c, Offset(2.45 * u, -6.6 * u), 0.5 * u);
  p.dot(cv, Offset(3.25 * u, -6.35 * u), 0.17 * u, c.ink);
  _mouth(cv, p, c, Offset(3.0 * u, -5.95 * u), 0.42 * u);
  for (final double dy in const <double>[-0.1, 0.12]) {
    p.line(cv, Offset(3.35 * u, -6.2 * u + dy * u), Offset(3.95 * u, -6.35 * u + dy * u * 2.4),
        c.ink, c.inkW * 0.35);
  }
  _blush(cv, p, Offset(1.75 * u, -5.95 * u), 0.3 * u);
  _accFace(cv, p, c, Offset(2.45 * u, -6.6 * u));
  _accHat(cv, p, c, Offset(1.75 * u, -8.2 * u));
  _accNeck(cv, p, c, Offset(1.2 * u, -5.2 * u));
}

void _frog(Canvas cv, _P p, _Ctx c) {
  final double u = c.u;
  final double br = c.breath;
  if (c.sleeping) {
    p.ellipse(cv, Offset(0, -0.85 * u), 2.35 * u, 0.85 * u * br, c.body, c.ink, c.inkW);
    p.circle(cv, Offset(0.7 * u, -1.5 * u), 0.62 * u, c.body, c.ink, c.inkW * 0.7);
    p.circle(cv, Offset(-0.6 * u, -1.55 * u), 0.62 * u, c.body, c.ink, c.inkW * 0.7);
    // Закрытые глазки-щелочки.
    p.line(cv, Offset(0.45 * u, -1.5 * u), Offset(0.95 * u, -1.5 * u), c.ink, c.inkW * 0.5);
    p.line(cv, Offset(-0.85 * u, -1.55 * u), Offset(-0.35 * u, -1.55 * u), c.ink, c.inkW * 0.5);
    return;
  }
  // Задние лапы (сложенные).
  for (final double dx in const <double>[-1.0, 0.2]) {
    p.shape(cv, capsulePath(Offset(dx * u, -1.7 * u), 0.55 * u, Offset(dx * u - 0.9 * u, -0.7 * u), 0.42 * u),
        cartoonShade(c.body), c.ink, c.inkW * 0.8);
  }
  // Тело.
  p.ellipse(cv, Offset(0, -1.75 * u * br), 2.55 * u * (2 - br), 1.7 * u * br, c.body, c.ink, c.inkW);
  p.ellipse(cv, Offset(0.3 * u, -1.05 * u), 1.7 * u, 0.85 * u, c.belly, Colors.transparent, 0);
  // Горлышко-пузырь дышит.
  p.ellipse(cv, Offset(1.2 * u, -1.15 * u), 0.75 * u, 0.5 * u * (1 + math.sin(c.tSec * 3.1) * 0.12),
      c.belly, Colors.transparent, 0);
  // Глазные бугорки + глаза.
  p.circle(cv, Offset(0.85 * u, -3.1 * u), 0.72 * u, c.body, c.ink, c.inkW);
  p.circle(cv, Offset(-0.65 * u, -3.15 * u), 0.72 * u, cartoonShade(c.body), c.ink, c.inkW);
  _eyesFront(cv, p, c, <Offset>[Offset(0.95 * u, -3.2 * u)], 0.45 * u);
  _eyesFront(cv, p, c, <Offset>[Offset(-0.55 * u, -3.25 * u)], 0.45 * u);
  // Широкая улыбка.
  final Path smile = Path()
    ..moveTo(0.1 * u, -2.1 * u)
    ..quadraticBezierTo(1.4 * u, -1.7 * u, 2.15 * u, -2.2 * u);
  cv.drawPath(smile, p.stroke(c.ink, c.inkW * 0.55));
  _blush(cv, p, Offset(1.7 * u, -2.6 * u), 0.3 * u);
  _accFace(cv, p, c, Offset(0.95 * u, -3.2 * u));
  _accHat(cv, p, c, Offset(-0.3 * u, -3.85 * u));
}

// ── ВОДНЫЕ ЖИТЕЛИ ──────────────────────────────────────────────────────

void _paintPond(Canvas cv, _Ctx c) {
  switch (c.pet.type) {
    case PetType.whale:
      _whale(cv, c);
      break;
    case PetType.seal:
      _seal(cv, c);
      break;
    case PetType.turtle:
      _turtle(cv, c);
      break;
    case PetType.octopus:
      _octopus(cv, c);
      break;
    default:
      _crab(cv, c);
  }
}

void _pondEyeSmile(Canvas cv, _P p, _Ctx c, Offset eye, Offset smile) {
  _eyeProfile(cv, p, c, eye, 0.3 * c.u);
  _mouth(cv, p, c, smile, 0.5 * c.u);
  _blush(cv, p, smile + Offset(-0.15 * c.u, 0.35 * c.u), 0.26 * c.u);
}

void _whale(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final double br = c.breath;
  final double wag = c.sleeping ? 0 : math.sin(c.tSec * 2.2) * 0.16;

  // Хвост-плавник машет.
  cv.save();
  cv.translate(-3.6 * u, -1.9 * u);
  cv.rotate(wag);
  p.shape(cv, leafPath(Offset(0.3 * u, 0), Offset(-1.6 * u, -1.0 * u), 0.55 * u), c.body,
      c.ink, c.inkW * 0.8);
  p.shape(cv, leafPath(Offset(0.3 * u, 0), Offset(-1.6 * u, 0.9 * u), 0.55 * u), c.body,
      c.ink, c.inkW * 0.8);
  cv.restore();

  // Тело.
  final Path body = Path()
    ..moveTo(4.3 * u, -1.9 * u)
    ..quadraticBezierTo(3.4 * u, -3.35 * u * br, 0.2 * u, -3.25 * u * br)
    ..quadraticBezierTo(-3.2 * u, -3.1 * u * br, -3.9 * u, -1.7 * u)
    ..quadraticBezierTo(-1.5 * u, -0.55 * u, 0.8 * u, -0.6 * u)
    ..quadraticBezierTo(3.1 * u, -0.65 * u, 4.3 * u, -1.9 * u)
    ..close();
  p.shape(cv, body, c.body, c.ink, c.inkW);
  // Брюшко с полосками.
  final Path belly = Path()
    ..moveTo(3.9 * u, -1.55 * u)
    ..quadraticBezierTo(1.5 * u, -0.55 * u, -1.5 * u, -0.7 * u)
    ..quadraticBezierTo(0.5 * u, -1.5 * u, 3.9 * u, -1.55 * u)
    ..close();
  cv.drawPath(belly, p.fill(c.belly));
  for (final double dx in const <double>[-0.6, 0.6, 1.8]) {
    final Path groove = Path()
      ..moveTo(dx * u, -0.75 * u)
      ..quadraticBezierTo(dx * u + 0.3 * u, -1.1 * u, dx * u + 0.15 * u, -1.45 * u);
    cv.drawPath(groove, p.stroke(cartoonShade(c.belly), c.inkW * 0.35));
  }
  // Плавник.
  cv.save();
  cv.translate(0.9 * u, -1.05 * u);
  cv.rotate(math.sin(c.tSec * 2.6) * 0.12);
  p.shape(cv, leafPath(Offset.zero, Offset(0.7 * u, 0.75 * u), 0.4 * u),
      cartoonShade(c.body), c.ink, c.inkW * 0.7);
  cv.restore();
  _pondEyeSmile(cv, p, c, Offset(3.1 * u, -2.35 * u), Offset(3.55 * u, -1.7 * u));
}

void _seal(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final double br = c.breath;
  // Хвост-ласты.
  cv.save();
  cv.translate(-3.1 * u, -1.5 * u);
  cv.rotate(c.sleeping ? 0 : math.sin(c.tSec * 2) * 0.14);
  p.shape(cv, leafPath(Offset.zero, Offset(-1.1 * u, -0.7 * u), 0.45 * u), c.body, c.ink,
      c.inkW * 0.7);
  p.shape(cv, leafPath(Offset.zero, Offset(-1.1 * u, 0.6 * u), 0.45 * u), c.body, c.ink,
      c.inkW * 0.7);
  cv.restore();
  // Тело-торпеда.
  p.ellipse(cv, Offset(0.2 * u, -1.55 * u * br), 3.4 * u * (2 - br), 1.35 * u * br,
      c.body, c.ink, c.inkW);
  // Голова спереди.
  p.circle(cv, Offset(2.9 * u, -1.8 * u), 1.15 * u, c.body, c.ink, c.inkW);
  p.ellipse(cv, Offset(2.2 * u, -1.0 * u), 1.4 * u, 0.7 * u, c.belly, Colors.transparent, 0);
  // Нос и усы.
  p.dot(cv, Offset(3.85 * u, -1.95 * u), 0.15 * u, c.ink);
  for (final double dy in const <double>[-0.1, 0.08]) {
    p.line(cv, Offset(3.7 * u, -1.75 * u + dy * u), Offset(4.35 * u, -1.85 * u + dy * u * 2),
        c.ink, c.inkW * 0.3);
  }
  // Передние ласты.
  p.shape(cv, leafPath(Offset(1.4 * u, -0.9 * u), Offset(2.1 * u, -0.15 * u), 0.4 * u),
      cartoonShade(c.body), c.ink, c.inkW * 0.7);
  _pondEyeSmile(cv, p, c, Offset(3.15 * u, -2.1 * u), Offset(3.6 * u, -1.5 * u));
}

void _turtle(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final double br = c.breath;
  // Ласты-лапки гребут.
  for (final (double x, double ph) in const <(double, double)>[
    (2.1, 0), (-2.1, math.pi), (1.6, math.pi / 2), (-1.6, -math.pi / 2),
  ]) {
    final double sw = c.sleeping ? 0 : math.sin(c.tSec * 2.8 + ph) * 0.3;
    cv.save();
    cv.translate(x * u, -0.55 * u);
    cv.rotate(sw);
    p.shape(cv, capsulePath(Offset.zero, 0.34 * u, Offset(0.15 * u, 0.5 * u), 0.28 * u),
        ph == 0 || ph == math.pi / 2 ? c.body : cartoonShade(c.body), c.ink, c.inkW * 0.7);
    cv.restore();
  }
  // Хвостик.
  p.shape(cv, leafPath(Offset(-3.0 * u, -1.0 * u), Offset(-3.7 * u, -0.7 * u), 0.25 * u),
      c.body, c.ink, c.inkW * 0.6);
  // Панцирь.
  final Path shell = Path()
    ..moveTo(2.75 * u, -0.75 * u)
    ..quadraticBezierTo(2.3 * u, -2.95 * u * br, 0, -2.95 * u * br)
    ..quadraticBezierTo(-2.3 * u, -2.95 * u * br, -2.75 * u, -0.75 * u)
    ..close();
  p.shape(cv, shell, c.dark, c.ink, c.inkW);
  // Щитки панциря.
  for (final double dx in const <double>[-1.3, 0, 1.3]) {
    final Path plate = Path()
      ..moveTo(dx * u - 0.55 * u, -0.8 * u)
      ..quadraticBezierTo(dx * u, -2.3 * u, dx * u + 0.55 * u, -0.8 * u);
    cv.drawPath(plate, p.stroke(Color.lerp(c.dark, Colors.white, 0.18)!, c.inkW * 0.4));
  }
  // Кайма панциря.
  p.ellipse(cv, Offset(0, -0.72 * u), 2.95 * u, 0.42 * u, c.body, c.ink, c.inkW * 0.7);
  // Голова.
  p.circle(cv, Offset(3.3 * u, -1.25 * u), 0.85 * u, c.body, c.ink, c.inkW);
  _pondEyeSmile(cv, p, c, Offset(3.5 * u, -1.4 * u), Offset(3.8 * u, -0.95 * u));
}

void _octopus(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final double br = c.breath;
  // Щупальца волнуются.
  for (int i = 0; i < 5; i++) {
    final double bx = (-1.4 + i * 0.7) * u;
    final double wave = c.sleeping ? 0 : math.sin(c.tSec * 2 + i * 1.25) * 0.55 * u;
    final double curl = c.sleeping ? 0.5 : 0.9;
    final Path arm = Path()
      ..moveTo(bx, -1.3 * u)
      ..quadraticBezierTo(bx - 0.2 * u, -0.5 * u, bx - 0.1 * u + wave * 0.4, 0.05 * u)
      ..quadraticBezierTo(bx + wave, 0.45 * u * curl, bx + wave * 0.4, 0.1 * u);
    cv.drawPath(arm, p.stroke(c.ink, 0.85 * u));
    cv.drawPath(arm, p.stroke(c.body, 0.55 * u));
    if (i == 2 && c.spec.extras.contains('suckers')) {
      for (final double t in const <double>[0.3, 0.55, 0.8]) {
        final Offset m = Offset(
            bx + (wave * 0.4 - 0.1 * u + 0.1 * u) * t,
            -1.3 * u + (0.05 * u + 1.3 * u) * t);
        p.dot(cv, m, 0.1 * u, c.belly);
      }
    }
  }
  // Голова-купол.
  p.ellipse(cv, Offset(0, -2.7 * u * br), 2.05 * u * (2 - br) * 0.9, 2.1 * u * br,
      c.body, c.ink, c.inkW);
  _eyesFront(cv, p, c, <Offset>[Offset(-0.5 * u, -2.9 * u), Offset(0.75 * u, -2.85 * u)],
      0.48 * u);
  _mouth(cv, p, c, Offset(0.15 * u, -1.95 * u), 0.55 * u);
  _blush(cv, p, Offset(-0.95 * u, -2.2 * u), 0.3 * u);
  _blush(cv, p, Offset(1.25 * u, -2.15 * u), 0.3 * u);
  _accHat(cv, p, c, Offset(0, -4.85 * u));
}

void _crab(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  // Ножки-шпильки бегут.
  for (final (double x, double ph, bool far) in const <(double, double, bool)>[
    (-1.6, 0, true), (-2.3, 1.2, true), (-1.2, 2.1, true),
    (1.2, 0, false), (2.3, 1.2, false), (1.6, 2.1, false),
  ]) {
    final double sw = c.sleeping ? 0 : math.sin(c.tSec * 6 + ph) * 0.1;
    cv.save();
    cv.translate(x * u, -1.3 * u);
    cv.rotate((far ? -1 : 1) * (0.55 + sw));
    p.shape(cv, capsulePath(Offset.zero, 0.16 * u, Offset(0, 1.15 * u), 0.13 * u),
        far ? cartoonShade(c.accent) : c.accent, c.ink, c.inkW * 0.6);
    cv.restore();
  }
  // Дальняя клешня.
  cv.save();
  cv.translate(-1.9 * u, -2.0 * u);
  cv.rotate(-0.5);
  p.shape(cv, capsulePath(Offset.zero, 0.28 * u, Offset(-0.7 * u, -0.45 * u), 0.24 * u),
      cartoonShade(c.accent), c.ink, c.inkW * 0.7);
  p.circle(cv, Offset(-0.95 * u, -0.6 * u), 0.52 * u, cartoonShade(c.accent), c.ink, c.inkW * 0.7);
  cv.restore();
  // Тело.
  final double br = c.breath;
  p.ellipse(cv, Offset(0, -1.75 * u * br), 2.5 * u * (2 - br), 1.35 * u * br, c.body,
      c.ink, c.inkW);
  // Ближняя клешня машет.
  cv.save();
  cv.translate(1.8 * u, -2.1 * u);
  cv.rotate(c.sleeping ? 0.2 : math.sin(c.tSec * 2.6) * 0.28 - 0.1);
  p.shape(cv, capsulePath(Offset.zero, 0.3 * u, Offset(1.05 * u, -0.5 * u), 0.26 * u),
      c.accent, c.ink, c.inkW * 0.7);
  p.circle(cv, Offset(1.4 * u, -0.68 * u), 0.62 * u, c.accent, c.ink, c.inkW);
  final Path notch = Path()
    ..moveTo(1.75 * u, -0.5 * u)
    ..lineTo(2.2 * u, -0.25 * u)
    ..lineTo(1.6 * u, -0.05 * u)
    ..close();
  p.shape(cv, notch, c.body, Colors.transparent, 0);
  cv.restore();
  // Глазки на стебельках.
  for (final double dx in const <double>[-0.7, 0.7]) {
    final double droop = c.sleeping ? 0.55 : 0;
    cv.save();
    cv.translate(dx * u, -2.75 * u);
    cv.rotate(droop);
    p.shape(cv, capsulePath(Offset.zero, 0.2 * u, Offset(dx * 0.2 * u, -0.95 * u), 0.17 * u),
        c.body, c.ink, c.inkW * 0.6);
    _eyesFront(cv, p, c, <Offset>[Offset(dx * 0.2 * u, -1.0 * u)], 0.4 * u);
    cv.restore();
  }
  _mouth(cv, p, c, Offset(0.15 * u, -1.45 * u), 0.55 * u);
  _blush(cv, p, Offset(-1.3 * u, -1.35 * u), 0.28 * u);
  _blush(cv, p, Offset(1.3 * u, -1.3 * u), 0.28 * u);
}

// ── РАСТЕНИЯ ───────────────────────────────────────────────────────────

void _paintPlant(Canvas cv, _Ctx c) {
  switch (c.pet.type) {
    case PetType.cactus:
      _cactus(cv, c);
      break;
    case PetType.bonsai:
      _bonsai(cv, c);
      break;
    case PetType.succulent:
      _succulent(cv, c);
      break;
    case PetType.sunflower:
      _sunflower(cv, c);
      break;
    case PetType.clover:
      _clover(cv, c);
      break;
    default:
      _sprout(cv, c);
  }
}

void _cactus(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final Color ink = cartoonInk(c.body);
  final double br = c.breath;
  // Ствол.
  p.shape(
      cv,
      Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(-1.25 * u, -6.3 * u * br, 2.5 * u, 6.3 * u * br),
            Radius.circular(1.25 * u))),
      c.body,
      ink,
      c.inkW);
  // Рёбра.
  for (final double dx in const <double>[-0.45, 0.45]) {
    p.line(cv, Offset(dx * u, -5.6 * u), Offset(dx * u, -0.9 * u),
        cartoonShade(c.body), c.inkW * 0.4);
  }
  // Ручки покачиваются.
  final double sway = math.sin(c.tSec * 1.5 + c.index) * 0.05;
  cv.save();
  cv.translate(-1.1 * u, -3.6 * u);
  cv.rotate(-sway);
  p.shape(cv, capsulePath(Offset(-0.5 * u, 0), 0.55 * u, Offset(-1.5 * u, -0.7 * u), 0.5 * u),
      c.body, ink, c.inkW);
  p.shape(cv, capsulePath(Offset(-1.5 * u, -0.7 * u), 0.5 * u, Offset(-1.5 * u, -2.1 * u), 0.5 * u),
      c.body, ink, c.inkW);
  cv.restore();
  cv.save();
  cv.translate(1.1 * u, -2.6 * u);
  cv.rotate(sway);
  p.shape(cv, capsulePath(Offset(0.5 * u, 0), 0.5 * u, Offset(1.4 * u, -0.6 * u), 0.45 * u),
      c.body, ink, c.inkW);
  p.shape(cv, capsulePath(Offset(1.4 * u, -0.6 * u), 0.45 * u, Offset(1.4 * u, -1.9 * u), 0.45 * u),
      c.body, ink, c.inkW);
  cv.restore();
  // Иголочки.
  for (int i = 0; i < 6; i++) {
    final double y = (-1.0 - i * 0.95) * u;
    p.line(cv, Offset(-1.45 * u, y), Offset(-1.75 * u, y - 0.15 * u), ink, c.inkW * 0.3);
    p.line(cv, Offset(1.45 * u, y + 0.4 * u), Offset(1.75 * u, y + 0.25 * u), ink, c.inkW * 0.3);
  }
  // Цветок на макушке.
  final Offset flowerC = Offset(0, -6.55 * u);
  for (int i = 0; i < 5; i++) {
    final double ang = i * 2 * math.pi / 5 - math.pi / 2 + sway;
    p.dot(cv, flowerC + Offset(math.cos(ang), math.sin(ang)) * 0.55 * u, 0.42 * u, c.accent);
  }
  p.dot(cv, flowerC, 0.36 * u, const Color(0xFFFFD166));
}

void _bonsai(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final Color ink = cartoonInk(c.accent);
  final Color foliage = c.body;
  // Ствол.
  final Path trunk = Path()
    ..moveTo(-0.25 * u, 0)
    ..quadraticBezierTo(-0.75 * u, -1.8 * u, 0.1 * u, -3.2 * u);
  p.tube(cv, trunk, c.accent, ink, 0.85 * u);
  final Path branch = Path()
    ..moveTo(0.05 * u, -3.1 * u)
    ..quadraticBezierTo(0.6 * u, -3.6 * u, 1.3 * u, -3.75 * u);
  p.tube(cv, branch, c.accent, ink, 0.5 * u);
  final Path branch2 = Path()
    ..moveTo(0.0 * u, -2.6 * u)
    ..quadraticBezierTo(-0.7 * u, -3.0 * u, -1.3 * u, -3.6 * u);
  p.tube(cv, branch2, c.accent, ink, 0.45 * u);
  // Кроны-облачка дышат.
  final double br = c.breath;
  p.ellipse(cv, Offset(0.45 * u, -4.85 * u * br), 2.3 * u, 1.45 * u * br, foliage,
      cartoonInk(foliage), c.inkW);
  p.ellipse(cv, Offset(-1.55 * u, -4.15 * u), 1.45 * u, 0.95 * u,
      Color.lerp(foliage, Colors.black, 0.06)!, cartoonInk(foliage), c.inkW * 0.8);
  p.ellipse(cv, Offset(2.1 * u, -4.0 * u), 1.3 * u, 0.9 * u,
      Color.lerp(foliage, Colors.black, 0.06)!, cartoonInk(foliage), c.inkW * 0.8);
  // Блики-листочки.
  for (final Offset o in <Offset>[Offset(-0.2 * u, -5.2 * u), Offset(1.2 * u, -4.6 * u)]) {
    p.dot(cv, o, 0.22 * u, c.belly);
  }
  // Мох у корней.
  p.dot(cv, Offset(-0.7 * u, -0.25 * u), 0.3 * u, cartoonShade(foliage));
  p.dot(cv, Offset(0.6 * u, -0.2 * u), 0.24 * u, cartoonShade(foliage));
}

void _succulent(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final Color ink = cartoonInk(c.body);
  final Offset center = Offset(0, -1.9 * u);
  final double rot = math.sin(c.tSec * 1.4 + c.index) * 0.04;
  // Внешний ряд листьев.
  for (int i = 0; i < 7; i++) {
    final double ang = i * 2 * math.pi / 7 + 0.35 + rot;
    final Offset tip = center + Offset(math.cos(ang), math.sin(ang)) * 2.15 * u;
    p.shape(cv, leafPath(center + Offset(math.cos(ang), math.sin(ang)) * 0.3 * u, tip, 0.6 * u),
        c.body, ink, c.inkW * 0.7);
    p.dot(cv, tip, 0.22 * u, c.accent);
  }
  // Внутренний ряд.
  for (int i = 0; i < 5; i++) {
    final double ang = i * 2 * math.pi / 5 + 1.1 - rot;
    final Offset tip = center + Offset(math.cos(ang), math.sin(ang)) * 1.05 * u;
    p.shape(cv, leafPath(center, tip, 0.42 * u), c.belly, ink, c.inkW * 0.55);
  }
  p.dot(cv, center, 0.42 * u, c.accent);
}

void _sunflower(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final Color ink = cartoonInk(c.accent);
  // Стебель.
  p.shape(cv, capsulePath(Offset(0, 0), 0.26 * u, Offset(0.12 * u, -5.0 * u), 0.22 * u),
      c.accent, ink, c.inkW * 0.7);
  // Листья.
  final double sway = math.sin(c.tSec * 1.6 + c.index) * 0.06;
  for (final (double y, double dir) in const <(double, double)>[(-2.1, -1), (-3.3, 1)]) {
    cv.save();
    cv.translate(0.06 * u, y * u);
    cv.rotate(dir * (0.5 + sway));
    p.shape(cv, leafPath(Offset.zero, Offset(1.75 * u, -0.35 * u), 0.5 * u), c.accent,
        ink, c.inkW * 0.7);
    p.line(cv, Offset(0.2 * u, -0.05 * u), Offset(1.4 * u, -0.3 * u),
        cartoonShade(c.accent), c.inkW * 0.3);
    cv.restore();
  }
  // Голова кивает.
  cv.save();
  cv.translate(0.12 * u, -6.15 * u);
  cv.rotate(sway * 1.6);
  // Лепестки.
  for (int i = 0; i < 10; i++) {
    final double ang = i * 2 * math.pi / 10;
    final Offset base = Offset(math.cos(ang) * 0.6 * u, math.sin(ang) * 0.6 * u);
    final Offset tip = Offset(math.cos(ang) * 2.0 * u, math.sin(ang) * 2.0 * u);
    p.shape(cv, leafPath(base, tip, 0.55 * u), c.body, cartoonInk(Color.lerp(c.body, Colors.black, 0.35)!),
        c.inkW * 0.55);
  }
  // Сердцевинка.
  p.circle(cv, Offset.zero, 1.05 * u, c.belly, cartoonInk(c.belly), c.inkW * 0.7);
  for (final Offset o in <Offset>[
    Offset(-0.35 * u, -0.3 * u), Offset(0.3 * u, -0.35 * u), Offset(0, 0.15 * u),
    Offset(-0.4 * u, 0.35 * u), Offset(0.42 * u, 0.3 * u),
  ]) {
    p.dot(cv, o, 0.11 * u, cartoonInk(c.belly));
  }
  cv.restore();
}

void _clover(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final Color ink = cartoonInk(c.body);
  final double rot = math.sin(c.tSec * 1.6 + c.index) * 0.05;
  // Стебельки.
  for (final (double x, double y) in const <(double, double)>[
    (-1.15, -2.5), (1.15, -2.5), (0, -3.3),
  ]) {
    p.shape(cv, capsulePath(Offset(0, 0), 0.12 * u, Offset(x * u, y * u), 0.1 * u),
        cartoonShade(c.body), ink, c.inkW * 0.45);
  }
  // Листья-сердечки.
  final List<Offset> tips = <Offset>[
    Offset(-1.75 * u, -2.85 * u), Offset(1.75 * u, -2.85 * u), Offset(0, -3.95 * u),
  ];
  for (int i = 0; i < tips.length; i++) {
    cv.save();
    cv.translate(tips[i].dx, tips[i].dy);
    cv.rotate(i == 2 ? rot : -rot);
    p.shape(cv, leafPath(Offset.zero, Offset(0.9 * u, 0), 0.55 * u), c.body, ink, c.inkW * 0.6);
    p.shape(cv, leafPath(Offset.zero, Offset(-0.9 * u, 0), 0.55 * u), c.body, ink, c.inkW * 0.6);
    p.line(cv, Offset(-0.7 * u, 0), Offset(0.7 * u, 0), cartoonShade(c.body), c.inkW * 0.3);
    cv.restore();
  }
  // Цветочек у взрослых.
  final Offset fl = Offset(0.9 * u, -3.6 * u);
  for (int i = 0; i < 5; i++) {
    final double ang = i * 2 * math.pi / 5 - math.pi / 2 + rot;
    p.dot(cv, fl + Offset(math.cos(ang), math.sin(ang)) * 0.3 * u, 0.22 * u, c.accent);
  }
  p.dot(cv, fl, 0.18 * u, const Color(0xFFFFD166));
}

void _sprout(Canvas cv, _Ctx c) {
  final double u = c.u;
  final _P p = _P(1, c.inkW);
  final Color ink = cartoonInk(c.body);
  final double sway = math.sin(c.tSec * 1.7 + c.index) * 0.06;
  // Стебель.
  p.shape(cv, capsulePath(Offset(0, 0), 0.2 * u, Offset(0, -2.1 * u), 0.16 * u),
      cartoonShade(c.body), ink, c.inkW * 0.6);
  // Два больших листа.
  cv.save();
  cv.translate(0, -2.0 * u);
  cv.rotate(-0.5 - sway);
  p.shape(cv, leafPath(Offset.zero, Offset(-1.9 * u, -1.35 * u), 0.72 * u), c.body, ink,
      c.inkW * 0.7);
  p.line(cv, Offset(-0.25 * u, -0.2 * u), Offset(-1.45 * u, -1.05 * u),
      cartoonShade(c.body), c.inkW * 0.3);
  cv.restore();
  cv.save();
  cv.translate(0, -2.0 * u);
  cv.rotate(0.5 + sway);
  p.shape(cv, leafPath(Offset.zero, Offset(1.8 * u, -1.5 * u), 0.72 * u), c.belly, ink,
      c.inkW * 0.7);
  p.line(cv, Offset(0.25 * u, -0.2 * u), Offset(1.4 * u, -1.15 * u),
      cartoonShade(c.belly), c.inkW * 0.3);
  cv.restore();
  // Росточек между.
  p.shape(cv, leafPath(Offset(0, -2.1 * u), Offset(0.1 * u, -3.3 * u), 0.3 * u),
      c.body, ink, c.inkW * 0.55);
}
