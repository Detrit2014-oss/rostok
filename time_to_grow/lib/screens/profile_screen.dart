import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_version.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../services/challenge_service.dart';
import '../services/diary_service.dart';
import '../services/focus_session_service.dart';
import '../services/llm_service.dart';
import '../services/pet_service.dart';
import '../services/screen_time_service.dart';
import '../services/update_service.dart';
import '../widgets/common.dart';

/// Профиль: статистика, настройки обновлений, настройка LLM,
/// машина времени для тестов и сброс прогресса.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Пересчёт достижений при каждом открытии профиля — быстрая операция.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) context.read<AchievementService>().recompute();
    });
  }

  Future<void> _checkUpdates() async {
    final UpdateService update = context.read<UpdateService>();
    await update.check(manual: true);
    if (!mounted) return;
    String msg;
    if (update.simulateUpdate) {
      msg = 'Демо-режим: баннер обновления показан сверху';
    } else if (update.available != null) {
      msg = 'Доступна версия ${update.available!.latestVersion}';
    } else if (update.lastError != null) {
      msg = update.lastError!;
    } else {
      msg = 'У вас последняя версия $kAppVersion';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editUrl() async {
    final UpdateService update = context.read<UpdateService>();
    final TextEditingController ctrl =
        TextEditingController(text: update.customUrl);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('URL проверки обновлений'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://…/version.json',
            helperText:
                'Например, файл на GitHub Pages. Пусто — использовать URL из кода.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('ok'),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    final String value = ctrl.text.trim();
    ctrl.dispose();
    if (result == 'ok' && mounted) {
      update.setCustomUrl(value);
    }
  }

  Future<void> _editLlm() async {
    final LlmService llm = context.read<LlmService>();
    final TextEditingController baseCtrl =
        TextEditingController(text: llm.config.baseUrl);
    final TextEditingController keyCtrl =
        TextEditingController(text: llm.config.apiKey);
    final TextEditingController modelCtrl =
        TextEditingController(text: llm.config.model);

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('ИИ-дневник (LLM)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Подойдёт любой API, совместимый с OpenAI: OpenAI, OpenRouter, '
                'Groq или ваш прокси.',
                style: TextStyle(fontSize: 13, color: Palette.inkSoft),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseCtrl,
                decoration:
                    const InputDecoration(labelText: 'Base URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Модель (например, gpt-4o-mini)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'API-ключ'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ключ хранится только на этом устройстве. Для релиза '
                'используйте прокси-бэкенд (см. README).',
                style: TextStyle(fontSize: 12, color: Palette.inkSoft),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    final String baseUrl = baseCtrl.text;
    final String apiKey = keyCtrl.text;
    final String model = modelCtrl.text;
    baseCtrl.dispose();
    keyCtrl.dispose();
    modelCtrl.dispose();

    if (ok == true && mounted) {
      llm.saveConfig(baseUrl: baseUrl, apiKey: apiKey, model: model);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiKey.trim().isEmpty
                ? 'LLM не настроен — работает офлайн-анализ'
                : 'LLM подключён: ${model.trim().isEmpty ? 'gpt-4o-mini' : model.trim()}',
          ),
        ),
      );
    }
  }

  Future<void> _resetAll() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Сбросить весь прогресс?'),
        content: const Text(
            'Питомцы, дневник и статистика будут удалены безвозвратно.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сбросить',
                style: TextStyle(color: Palette.coral)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<FocusSessionService>().reset();
    context.read<PetService>().reset();
    context.read<DiaryService>().reset();
    context.read<ChallengeService>().resetLocally();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Прогресс сброшен — выберите нового питомца 🐣')),
    );
  }

  String _screenTimeText(ScreenTimeSupport support) {
    switch (support) {
      case ScreenTimeSupport.granted:
        return 'Точный учёт Android: засчитываются только минуты '
            'с погашенным экраном — время с включённым экраном '
            'вычитается по системным данным.';
      case ScreenTimeSupport.denied:
        return 'Чтобы вычитать время с включённым экраном, выдайте '
            'приложению доступ к данным об использовании '
            '(Настройки → Доступ к использованию).';
      case ScreenTimeSupport.unavailable:
        return 'Здесь засчитывается всё время вне приложения. '
            'На Android учёт точнее — по системному экранному времени '
            '(как подключить: docs/SCREEN_TIME.md).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final PetService pet = context.watch<PetService>();
    final DiaryService diary = context.watch<DiaryService>();
    final FocusSessionService focus = context.watch<FocusSessionService>();
    final UpdateService update = context.watch<UpdateService>();
    final LlmService llm = context.watch<LlmService>();
    final AchievementService achievements = context.watch<AchievementService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: <Widget>[
                StatTile(
                  icon: Icons.schedule_rounded,
                  value: formatDurationMinutes(pet.totalMinutes),
                  label: 'вне телефона всего',
                ),
                StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${pet.streakDays}',
                  label: 'дней серии',
                  color: Palette.orange,
                ),
                StatTile(
                  icon: Icons.paid_rounded,
                  value: '${pet.coins}',
                  label: 'монеток 🪙',
                  color: Palette.yellowDark,
                ),
                StatTile(
                  icon: Icons.pets_rounded,
                  value: '${pet.adultCount}',
                  label: 'взрослых питомцев',
                  color: Palette.purple,
                ),
                StatTile(
                  icon: Icons.edit_note_rounded,
                  value: '${diary.entries.length}',
                  label: 'записей в дневнике',
                  color: Palette.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text('Достижения',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      Text(
                        '${achievements.count}/${achievements.total}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Palette.inkSoft),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Открываются сами: за серию, питомцев, уровень и дневник.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.4, color: Palette.inkSoft),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final Achievement a in Achievement.kAchievements)
                        Tooltip(
                          message: achievements.unlocked.contains(a.id)
                              ? '${a.title} — ${a.description}'
                              : '${a.title} — ещё не открыто',
                          child: Opacity(
                            opacity: achievements.unlocked.contains(a.id)
                                ? 1
                                : 0.32,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: achievements.unlocked.contains(a.id)
                                    ? Palette.greenSoft
                                    : const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: achievements.unlocked.contains(a.id)
                                      ? Palette.green
                                      : Palette.border,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  a.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Экранное время',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    _screenTimeText(focus.screenTimeSupport),
                    style: const TextStyle(
                        fontSize: 13, height: 1.45, color: Palette.inkSoft),
                  ),
                  if (focus.screenTimeSupport == ScreenTimeSupport.denied) ...<Widget>[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ScreenTimeService.openUsageAccessSettings();
                        if (!mounted) return;
                        await context
                            .read<FocusSessionService>()
                            .refreshSupport();
                      },
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('Дать доступ (Android)'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Обновления',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Версия $kAppVersion (сборка $kAppBuildNumber)',
                    style: const TextStyle(
                        color: Palette.inkSoft, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _checkUpdates,
                    icon: const Icon(Icons.system_update_alt_rounded,
                        size: 18),
                    label: const Text('Проверить обновления'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Симулировать обновление',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Демо: показать баннер без сервера',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    value: update.simulateUpdate,
                    activeColor: Palette.green,
                    onChanged: (bool v) =>
                        context.read<UpdateService>().setSimulate(v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.link_rounded, size: 20),
                    title: const Text(
                      'URL проверки обновлений',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      update.customUrl.isEmpty
                          ? 'по умолчанию — из кода приложения'
                          : update.customUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    onTap: _editUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Настройки',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.smart_toy_rounded,
                        size: 20, color: Palette.purple),
                    title: const Text(
                      'ИИ-дневник (LLM)',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      llm.config.isConfigured
                          ? 'Подключена модель: ${llm.config.model}'
                          : 'Не настроено — работает офлайн-анализ',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    onTap: _editLlm,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Машина времени ×60',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      '1 сек = 1 мин, считает всё время (обходит экранное время) — быстрый тест в Chrome',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    value: focus.timeMachine,
                    activeColor: Palette.green,
                    onChanged: (bool v) => context
                        .read<FocusSessionService>()
                        .setTimeMachine(v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.delete_forever_rounded,
                        size: 20, color: Palette.coral),
                    title: const Text(
                      'Сбросить прогресс',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Palette.coral),
                    ),
                    onTap: _resetAll,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text('О приложении',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 6),
                  Text(
                    '«Росток» — цифровая гигиена в игровой форме: '
                    'откладываете телефон — растёт питомец, вечером ведёте '
                    'дневник с ИИ-садовником, а в челленджах соревнуетесь '
                    'с друзьями по часам цифрового детокса.',
                    style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Palette.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
