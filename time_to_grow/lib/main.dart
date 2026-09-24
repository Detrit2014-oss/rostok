import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/achievement_service.dart';
import 'services/challenge_backend.dart';
import 'services/challenge_service.dart';
import 'services/diary_service.dart';
import 'services/focus_session_service.dart';
import 'services/llm_service.dart';
import 'services/pet_service.dart';
import 'services/quest_service.dart';
import 'services/sleep_service.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';
import 'services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Инициализация сервисов ─────────────────────────────────────────
  final StorageService storage = StorageService();
  await storage.init();

  final LlmService llmService = LlmService(storage)..load();
  final PetService petService = PetService(storage)..load();
  final FocusSessionService focusService =
      FocusSessionService(petService, storage)..load();
  final DiaryService diaryService = DiaryService(storage, llmService)..load();

  // Челленджи: локальный демо-бэкенд сейчас, Firestore — в v2.0
  // (готовый код и инструкция: docs/FIREBASE.md).
  final ChallengeService challengeService =
      ChallengeService(petService, DemoChallengeBackend(storage));
  challengeService.load();

  final UpdateService updateService = UpdateService(storage)..load();

  // Достижения (v1.5.0): считаются по статистике питомцев и дневника.
  final AchievementService achievementService =
      AchievementService(storage, petService)
        ..diaryCountProvider = () => diaryService.entries.length
        ..load();

  // Задания, сон и погода (v1.7.0). QuestService сам слушает PetService:
  // минуты сессий капают в задания session_10/session_30.
  final QuestService questService = QuestService(storage, petService)..load();
  final SleepService sleepService = SleepService(storage, petService)..load();
  final WeatherService weatherService = WeatherService(storage)..load();

  // Сессия детокса считается по реальному времени: приложение свёрнуто —
  // телефон отложен — питомец растёт. Следим за жизненным циклом.
  WidgetsBinding.instance.addObserver(focusService);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<LlmService>.value(value: llmService),
        ChangeNotifierProvider<PetService>.value(value: petService),
        ChangeNotifierProvider<FocusSessionService>.value(value: focusService),
        ChangeNotifierProvider<DiaryService>.value(value: diaryService),
        ChangeNotifierProvider<ChallengeService>.value(value: challengeService),
        ChangeNotifierProvider<UpdateService>.value(value: updateService),
        ChangeNotifierProvider<AchievementService>.value(
            value: achievementService),
        ChangeNotifierProvider<QuestService>.value(value: questService),
        ChangeNotifierProvider<SleepService>.value(value: sleepService),
        ChangeNotifierProvider<WeatherService>.value(value: weatherService),
      ],
      child: const TimeToGrowApp(),
    ),
  );

  // Первая проверка обновлений — через 3 секунды, без блокировки UI.
  Future<void>.delayed(const Duration(seconds: 3), () {
    updateService.check();
    achievementService.recompute();
    weatherService.refresh();
  });
}
