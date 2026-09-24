import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Рисованая монетка (v1.9.0) — замена эмодзи 🪙, который на части
/// устройств Android отображается пустым квадратом (нет Emoji 13.1).
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CoinPainter(),
    );
  }
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset c = Offset(r, r);

    // Тёмный ободок-тень снизу (объём).
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFE0A800));
    // Тело монеты: золотой круг.
    canvas.drawCircle(
        c.translate(0, -r * 0.06), r * 0.92, Paint()..color = const Color(0xFFFFC800));
    // Внутренний диск светлее.
    canvas.drawCircle(
        c.translate(0, -r * 0.06), r * 0.62, Paint()..color = const Color(0xFFFFDD55));
    // Звёздочка в центре.
    final Path star = Path();
    const int points = 5;
    final Offset sc = c.translate(0, -r * 0.06);
    for (int i = 0; i < points * 2; i++) {
      final double ang = -math.pi / 2 + i * math.pi / points;
      final double rad = i.isEven ? r * 0.4 : r * 0.17;
      final Offset p = Offset(
        sc.dx + rad * (size.width / 34) * (34 / size.width) * _cos(ang),
        sc.dy + rad * _sin(ang),
      );
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFE0A800));
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Текст с рисованой монеткой: «N [монетка]».
class CoinText extends StatelessWidget {
  const CoinText(
    this.amount, {
    super.key,
    this.fontSize = 14,
    this.color,
    this.fontWeight = FontWeight.w800,
  });

  final int amount;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$amount',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
        SizedBox(width: fontSize * 0.22),
        CoinIcon(size: fontSize * 0.95),
      ],
    );
  }
}

/// Карточка в игровом стиле: белый фон, заметная рамка, крупные скругления.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.border, width: 2),
      ),
      child: child,
    );
  }
}

/// «Пухлая» кнопка в духе Duolingo: жёсткая тень снизу, сочный цвет.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.fullWidth = false,
    this.color = Palette.green,
    this.shadow = Palette.greenDark,
    this.textColor = Colors.white,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color color;
  final Color shadow;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Widget button = Material(
      color: enabled ? color : const Color(0xFFE5E5E5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  color: enabled ? textColor : const Color(0xFFAFAFAF),
                  size: 22,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: enabled ? textColor : const Color(0xFFAFAFAF),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: enabled ? shadow : const Color(0xFFCCCCCC),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: fullWidth
          ? SizedBox(width: double.infinity, child: Center(child: button))
          : button,
    );
  }
}

/// Плитка статистики для Профиля.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = Palette.green,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Palette.ink),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: Palette.inkSoft, height: 1.25),
          ),
        ],
      ),
    );
  }
}
