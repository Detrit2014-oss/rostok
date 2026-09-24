import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../services/llm_service.dart';
import '../services/quest_service.dart';
import '../widgets/common.dart';

/// Вечерний дневник настроения: короткая запись → ответ ИИ-садовника.
/// Офлайн-анализ приходит мгновенно; если настроен LLM (Профиль),
/// ответ генерирует настоящая модель.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    final DiaryService diary = context.read<DiaryService>();
    final LlmService llm = context.read<LlmService>();
    // Задание «Вечерняя заметка» (v1.7.0).
    context.read<QuestService>().addProgress('diary_1', 1);
    _controller.clear();
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => _ReplySheet(
        future: diary.addEntry(text),
        llmConfigured: llm.config.isConfigured,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DiaryService diary = context.watch<DiaryService>();
    final List<DiaryEntry> entries = diary.entries;

    return Scaffold(
      appBar: AppBar(title: const Text('Дневник настроения')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: entries.isEmpty
                  ? const _EmptyHint()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: entries.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MoodStrip(
                                entries: entries.take(7).toList()),
                          );
                        }
                        final DiaryEntry e = entries[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EntryCard(entry: e),
                        );
                      },
                    ),
            ),
            _Composer(controller: _controller, onSave: _save),
          ],
        ),
      ),
    );
  }
}

// ── Композер ─────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSave});

  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.card,
        border: Border(top: BorderSide(color: Palette.border, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.mic_none_rounded, size: 24),
                color: Palette.inkSoft,
                disabledColor: const Color(0xFFC9C9C9),
                tooltip: 'Голосовые заметки появятся в v1.1 (на телефонах)',
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Как прошёл день? Пара честных предложений…',
                    hintMaxLines: 2,
                    filled: true,
                    fillColor: const Color(0xFFF7F7F2),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Palette.border, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Palette.blue, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSave,
                style: IconButton.styleFrom(backgroundColor: Palette.green),
                color: Colors.white,
                icon: const Icon(Icons.auto_awesome_rounded, size: 22),
                tooltip: 'Спросить ИИ-садовника',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Шторка с ответом ИИ ──────────────────────────────────────────────

class _ReplySheet extends StatelessWidget {
  const _ReplySheet({required this.future, required this.llmConfigured});

  final Future<DiaryEntry> future;
  final bool llmConfigured;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: FutureBuilder<DiaryEntry>(
          future: future,
          builder: (BuildContext context, AsyncSnapshot<DiaryEntry> snap) {
            if (!snap.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.spa_rounded,
                      color: Palette.green, size: 30),
                  const SizedBox(height: 12),
                  Text(
                    llmConfigured ? 'ИИ-садовник думает…' : 'Записываем…',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Спасибо, что делитесь вечером',
                    style: TextStyle(color: Palette.inkSoft, fontSize: 13),
                  ),
                ],
              );
            }
            return _ReplyContent(entry: snap.data!);
          },
        ),
      ),
    );
  }
}

/// Анимация «печатающегося» ответа.
class _ReplyContent extends StatefulWidget {
  const _ReplyContent({required this.entry});

  final DiaryEntry entry;

  @override
  State<_ReplyContent> createState() => _ReplyContentState();
}

class _ReplyContentState extends State<_ReplyContent> {
  int _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 22), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_shown >= widget.entry.aiReply.length) {
        t.cancel();
      } else {
        setState(() => _shown += 2);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DiaryEntry entry = widget.entry;
    final String full = entry.aiReply;
    final int safeEnd = _shown.clamp(0, full.length).toInt();
    final String shown = full.substring(0, safeEnd);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.spa_rounded, color: Palette.green),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('ИИ-садовник',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: entry.source == 'llm'
                    ? Palette.greenSoft
                    : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                entry.source == 'llm' ? 'LLM' : 'офлайн-ИИ',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Palette.inkSoft),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(shown, style: const TextStyle(fontSize: 15, height: 1.55)),
        const SizedBox(height: 18),
        BigButton(
          label: 'Спасибо, спокойной ночи',
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ── Карточки записей ─────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(moodIcon(entry.moodScore),
                  color: moodColor(entry.moodScore), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatRuDateTime(entry.createdAt),
                  style: const TextStyle(
                      color: Palette.inkSoft, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14.5, height: 1.4),
          ),
          if (entry.tags.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String tag in entry.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1E6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                          fontSize: 11.5, color: Palette.inkSoft),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Palette.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.spa_rounded,
                    size: 16, color: Palette.greenDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.aiReply,
                    style: const TextStyle(
                        fontSize: 13, height: 1.45, color: Palette.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodStrip extends StatelessWidget {
  const _MoodStrip({required this.entries});

  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Настроение за последние дни',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (final DiaryEntry e in entries.reversed)
                Column(
                  children: <Widget>[
                    Icon(moodIcon(e.moodScore),
                        color: moodColor(e.moodScore), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '${DateTime.fromMillisecondsSinceEpoch(e.createdAt).day}',
                      style: const TextStyle(
                          fontSize: 10, color: Palette.inkSoft),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.nightlight_round, size: 44, color: Palette.purple),
          SizedBox(height: 12),
          Text(
            'Здесь появится история ваших вечеров',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Каждый вечер — пара честных предложений о том, как прошёл день. '
            'ИИ-садовник мягко подскажет, как лучше спать и меньше тревожиться.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }
}
