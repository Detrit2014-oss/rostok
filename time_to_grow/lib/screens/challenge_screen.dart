import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/challenge.dart';
import '../services/challenge_service.dart';
import '../widgets/common.dart';

/// Челленджи с друзьями. v1.0.0 — демо-режим: дружелюбные боты +
/// ваш реальный прогресс. Реальные комнаты друзей — v2.0 на Firebase
/// (готовый код: docs/FIREBASE.md).
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChallengeService>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChallengeService service = context.watch<ChallengeService>();
    final Challenge? weekly = service.weekly;

    return Scaffold(
      appBar: AppBar(title: const Text('Челленджи')),
      body: SafeArea(
        child: weekly == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                weekly.title,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F1E6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Демо-режим',
                                style: TextStyle(
                                    fontSize: 11, color: Palette.inkSoft),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Цель недели: ${weekly.goalHours} ч вне телефона · '
                          'осталось ${service.daysLeft} дн.',
                          style: const TextStyle(
                              color: Palette.inkSoft, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        ..._leaderboardTiles(service),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: BigButton(
                          label: 'Свой челлендж',
                          icon: Icons.add_rounded,
                          onPressed: () => _createChallenge(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _joinByCode(context),
                          icon: const Icon(Icons.group_add_rounded,
                              size: 20),
                          label: const Text('По коду'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'В демо-режиме соперники — дружелюбные боты, а ваш прогресс '
                    'считается из реальных минут детокса. Настоящие комнаты друзей '
                    'появятся в v2.0 вместе с Firebase-синхронизацией.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Palette.inkSoft,
                        fontSize: 12.5,
                        height: 1.5),
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _leaderboardTiles(ChallengeService service) {
    final List<ChallengeParticipant> board = service.leaderboard;
    final int goalMinutes = service.weekly?.goalMinutes ?? 1;
    final List<Widget> tiles = <Widget>[];

    for (int i = 0; i < board.length; i++) {
      final ChallengeParticipant p = board[i];
      final double progress =
          (p.minutes / goalMinutes).clamp(0.0, 1.0);
      String medal;
      switch (i) {
        case 0:
          medal = '🥇';
          break;
        case 1:
          medal = '🥈';
          break;
        case 2:
          medal = '🥉';
          break;
        default:
          medal = '${i + 1}';
      }

      tiles.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 26,
                    child: Text(medal,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  Text(p.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.isUser ? 'Вы' : p.name,
                      style: TextStyle(
                        fontWeight:
                            p.isUser ? FontWeight.w800 : FontWeight.w600,
                        color: p.isUser ? Palette.greenDark : Palette.ink,
                      ),
                    ),
                  ),
                  Text(
                    formatDurationMinutes(p.minutes),
                    style: const TextStyle(
                        fontSize: 13, color: Palette.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEE9D8),
                  color: p.isUser ? Palette.green : const Color(0xFFB9CDBB),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return tiles;
  }

  Future<void> _createChallenge(BuildContext context) async {
    final TextEditingController titleCtrl = TextEditingController();
    int goal = 10;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setState) =>
            AlertDialog(
          title: const Text('Новый челлендж'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Например: «Без ленты перед сном»',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Text('Цель, часов в неделю: '),
                  DropdownButton<int>(
                    value: goal,
                    items: <int>[3, 5, 7, 10, 15, 20]
                        .map((int v) => DropdownMenuItem<int>(
                              value: v,
                              child: Text('$v'),
                            ))
                        .toList(),
                    onChanged: (int? v) => setState(() => goal = v ?? 10),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    if (ok == true && context.mounted) {
      context
          .read<ChallengeService>()
          .createChallenge(titleCtrl.text, goal);
    }
  }

  Future<void> _joinByCode(BuildContext context) async {
    final TextEditingController ctrl = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Вступить по коду'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Попросите у друга код комнаты и введите его здесь.',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'Например: GARDEN-42'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Вступить'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (ok != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Демо: реальные комнаты друзей появятся в v2.0 вместе с Firebase'),
      ),
    );
  }
}
