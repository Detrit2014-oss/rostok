/// Одна запись вечернего дневника настроения.
class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.createdAt,
    required this.text,
    required this.moodScore,
    required this.tags,
    required this.aiReply,
    this.source = 'local',
  });

  final String id;
  final int createdAt; // мс с начала эпохи
  final String text;

  /// Оценка настроения от -100 до 100.
  final int moodScore;

  /// Темы, распознанные в записи: стресс, сон, экран, радость…
  final List<String> tags;

  /// Ответ ИИ-садовника.
  final String aiReply;

  /// Кто подготовил ответ: 'local' (офлайн-анализ) или 'llm' (реальная модель).
  final String source;

  DiaryEntry copyWith({
    int? moodScore,
    List<String>? tags,
    String? aiReply,
    String? source,
  }) =>
      DiaryEntry(
        id: id,
        createdAt: createdAt,
        text: text,
        moodScore: moodScore ?? this.moodScore,
        tags: tags ?? this.tags,
        aiReply: aiReply ?? this.aiReply,
        source: source ?? this.source,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt,
        'text': text,
        'moodScore': moodScore,
        'tags': tags,
        'aiReply': aiReply,
        'source': source,
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'] as String? ?? 'd0',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        moodScore: (json['moodScore'] as num?)?.toInt() ?? 0,
        tags: ((json['tags'] as List?) ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
        aiReply: json['aiReply'] as String? ?? '',
        source: json['source'] as String? ?? 'local',
      );
}
