class ChallengeParticipant {
  ChallengeParticipant({
    required this.name,
    required this.emoji,
    this.minutes = 0,
    this.isUser = false,
  });

  final String name;
  final String emoji;

  /// Минуты детокса за неделю.
  int minutes;
  final bool isUser;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'emoji': emoji,
        'minutes': minutes,
        'isUser': isUser,
      };

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) =>
      ChallengeParticipant(
        name: json['name'] as String? ?? 'Участник',
        emoji: json['emoji'] as String? ?? '🐾',
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
        isUser: json['isUser'] as bool? ?? false,
      );
}

class Challenge {
  Challenge({
    required this.id,
    required this.title,
    required this.goalHours,
    required this.weekStartMs,
    required this.participants,
    this.isDemo = true,
  });

  final String id;
  final String title;
  final int goalHours;

  /// Понедельник недели старта (мс) — для ротации «Детокс-недели».
  final int weekStartMs;
  final List<ChallengeParticipant> participants;

  /// true — локальный демо-режим (боты), false — реальный бэкенд (v2.0).
  final bool isDemo;

  int get goalMinutes => goalHours * 60;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'goalHours': goalHours,
        'weekStartMs': weekStartMs,
        'isDemo': isDemo,
        'participants':
            participants.map((ChallengeParticipant p) => p.toJson()).toList(),
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String? ?? 'w0',
        title: json['title'] as String? ?? 'Челлендж',
        goalHours: (json['goalHours'] as num?)?.toInt() ?? 10,
        weekStartMs: (json['weekStartMs'] as num?)?.toInt() ?? 0,
        isDemo: json['isDemo'] as bool? ?? true,
        participants: ((json['participants'] as List?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> p) => ChallengeParticipant.fromJson(p))
            .toList(),
      );
}
