import 'package:flutter/material.dart';

/// Русские названия месяцев (родительный падеж) — без зависимости от intl.
const List<String> kMonthsRu = <String>[
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

String formatRuDateTime(int ms) {
  final DateTime d = DateTime.fromMillisecondsSinceEpoch(ms);
  final String hh = d.hour.toString().padLeft(2, '0');
  final String mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${kMonthsRu[d.month - 1]}, $hh:$mm';
}

String formatDurationMinutes(int minutes) {
  if (minutes < 60) return '$minutes мин';
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return m == 0 ? '$h ч' : '$h ч $m мин';
}

IconData moodIcon(int score) {
  if (score >= 40) return Icons.sentiment_very_satisfied_rounded;
  if (score >= 10) return Icons.sentiment_satisfied_rounded;
  if (score > -30) return Icons.sentiment_neutral_rounded;
  if (score > -60) return Icons.sentiment_dissatisfied_rounded;
  return Icons.sentiment_very_dissatisfied_rounded;
}

Color moodColor(int score) {
  if (score >= 40) return const Color(0xFF4CB944);
  if (score >= 10) return const Color(0xFF90D26D);
  if (score > -30) return const Color(0xFFE0A800);
  if (score > -60) return const Color(0xFFFF9600);
  return const Color(0xFFFF6B6B);
}
