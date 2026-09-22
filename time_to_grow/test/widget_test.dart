import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:time_to_grow/app.dart';
import 'package:time_to_grow/services/challenge_backend.dart';
import 'package:time_to_grow/services/challenge_service.dart';
import 'package:time_to_grow/services/diary_service.dart';
import 'package:time_to_grow/services/focus_session_service.dart';
import 'package:time_to_grow/services/llm_service.dart';
import 'package:time_to_grow/services/pet_service.dart';
import 'package:time_to_grow/services/storage_service.dart';
import 'package:time_to_grow/services/update_service.dart';

void main() {
  testWidgets('Приложение запускается и показывает главный экран',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final StorageService storage = StorageService();
    await storage.init();

    final LlmService llm = LlmService(storage)..load();
    final PetService pet = PetService(storage)..load();
    final FocusSessionService focus = FocusSessionService(pet, storage)..load();
    final DiaryService diary = DiaryService(storage, llm)..load();
    final ChallengeService challenge =
        ChallengeService(pet, DemoChallengeBackend(storage));
    await challenge.load();
    final UpdateService update = UpdateService(storage)..load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LlmService>.value(value: llm),
          ChangeNotifierProvider<PetService>.value(value: pet),
          ChangeNotifierProvider<FocusSessionService>.value(value: focus),
          ChangeNotifierProvider<DiaryService>.value(value: diary),
          ChangeNotifierProvider<ChallengeService>.value(value: challenge),
          ChangeNotifierProvider<UpdateService>.value(value: update),
        ],
        child: const TimeToGrowApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Время Расти'), findsWidgets);
  });
}
