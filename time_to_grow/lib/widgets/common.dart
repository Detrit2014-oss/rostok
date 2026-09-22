import 'package:flutter/material.dart';

import '../core/theme.dart';

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
