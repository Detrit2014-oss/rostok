# Челленджи с друзьями: подключение Firebase (план v2.0)

В v1.0.0 челленджи работают в локальном демо-режиме (друзья-боты + ваш реальный
прогресс), чтобы приложение запускалось в Chrome без предварительной настройки.
Весь код для реальной синхронизации готов: интерфейс `ChallengeBackend` уже
подключён, ниже — пошаговое включение Firestore (~15 минут).

## Шаг 1. Проект Firebase

1. console.firebase.google.com → «Добавить проект».
2. Build → Firestore Database → «Создать базу» → режим тестирования (на время разработки).
3. Добавьте приложения: Android (applicationId после `flutter create` —
   в `android/app/build.gradle`) и iOS; для веба — Web App (`</>` в консоли).

## Шаг 2. Конфигурация платформ

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Команда создаст `lib/firebase_options.dart`, скачает `google-services.json`
(Android → `android/app/`) и `GoogleService-Info.plist` (iOS → `ios/Runner/`),
а также подскажет строки для `web/index.html` (скрипты Firebase JS SDK).

## Шаг 3. Зависимости

В `pubspec.yaml` раскомментируйте:

```yaml
  firebase_core: ^3.6.0
  cloud_firestore: ^5.4.4
```

и выполните `flutter pub get`.

## Шаг 4. Инициализация

В `lib/main.dart` до `runApp`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

## Шаг 5. Готовый бэкенд-класс

Создайте файл `lib/services/firestore_challenge_backend.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/challenge.dart';
import 'challenge_backend.dart';

/// Реальный бэкенд челленджей на Firestore.
class FirestoreChallengeBackend implements ChallengeBackend {
  FirestoreChallengeBackend({required this.roomCode});

  /// Код комнаты — его же вводят друзья в диалоге «Вступить по коду».
  final String roomCode;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      FirebaseFirestore.instance.collection('challenge_rooms');

  @override
  Future<Challenge?> load() async {
    final doc = await _rooms.doc(roomCode).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return Challenge.fromJson(data);
  }

  @override
  Future<void> save(Challenge challenge) async {
    await _rooms.doc(roomCode).set(challenge.toJson(), SetOptions(merge: true));
  }

  /// Присоединение к комнате друга.
  Future<void> joinByCode(String code, String myName, String myEmoji) async {
    await _rooms.doc(code.toUpperCase()).set(<String, dynamic>{
      'participants': FieldValue.arrayUnion(<Map<String, dynamic>>[
        <String, dynamic>{
          'name': myName,
          'emoji': myEmoji,
          'isUser': false,
          'minutes': 0,
        },
      ]),
    }, SetOptions(merge: true));
  }
}
```

## Шаг 6. Переключение сервиса

В `lib/main.dart` замените:

```dart
ChallengeService(petService, DemoChallengeBackend(storage))
```

на:

```dart
ChallengeService(petService, FirestoreChallengeBackend(roomCode: myRoomCode))
```

Код комнаты генерируйте один раз и делитесь им с друзьями — в v2.0 диалог
«Вступить по коду» вызовет `joinByCode`.

## Шаг 7. Правила безопасности Firestore (минимум)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /challenge_rooms/{roomId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Для боевого запуска добавьте Firebase Auth (анонимный вход или Google Sign-In)
и уточните правила под схему участников.

## Что это даёт

- Реальные друзья вместо ботов, живой лидерборд недели.
- Код комнаты: друг вводит код и попадает в ваше соревнование.
- Прогресс синхронизируется автоматически — минуты детокса каждого участника.
