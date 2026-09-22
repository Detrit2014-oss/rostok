import 'package:flutter/foundation.dart';

import '../models/diary_entry.dart';
import 'llm_service.dart';
import 'mood_ai.dart';
import 'storage_service.dart';

/// Дневник настроения: сохранение записей + анализ.
///
/// Стратегия двойного ответа:
///  1) мгновенно показываем офлайн-анализ (работает всегда);
///  2) если в Профиле настроен реальный LLM — асинхронно заменяем
///     ответ сгенерированным моделью, запись обновляется в списке.
class DiaryService extends ChangeNotifier {
  DiaryService(this._storage, this._llm);

  final StorageService _storage;
  final LlmService _llm;
  final List<DiaryEntry> _entries = <DiaryEntry>[];

  static const String _kEntries = 'diary_entries';

  List<DiaryEntry> get entries => List<DiaryEntry>.unmodifiable(_entries);

  void load() {
    final String raw = _storage.getString(_kEntries);
    if (raw.isEmpty) return;
    try {
      final dynamic decoded = _storage.decodeJson(raw);
      if (decoded is List) {
        _entries
          ..clear()
          ..addAll(decoded
              .whereType<Map<String, dynamic>>()
              .map((Map<String, dynamic> e) => DiaryEntry.fromJson(e)));
        _entries.sort(
            (DiaryEntry a, DiaryEntry b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (_) {
      // Повреждённые записи игнорируем — дневник начнётся заново.
    }
  }

  Future<DiaryEntry> addEntry(String text) async {
    final MoodAnalysis local = MoodAI.analyze(text);
    DiaryEntry entry = DiaryEntry(
      id: 'd${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: text,
      moodScore: local.score,
      tags: local.tags,
      aiReply: local.reply,
      source: 'local',
    );
    _entries.insert(0, entry);
    _persist();
    notifyListeners();

    final String? llmReply = await _llm.diaryReply(text);
    if (llmReply != null && llmReply.trim().isNotEmpty) {
      entry = entry.copyWith(aiReply: llmReply.trim(), source: 'llm');
      _entries[0] = entry;
      _persist();
      notifyListeners();
    }
    return entry;
  }

  void _persist() {
    _storage.setString(
      _kEntries,
      _storage.encodeJson(_entries.map((DiaryEntry e) => e.toJson()).toList()),
    );
  }

  void reset() {
    _entries.clear();
    _storage.setString(_kEntries, '');
    notifyListeners();
  }
}
