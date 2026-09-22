# Как работают обновления «Время Расти»

Выбранная схема — **гибрид**: сейчас проверка статического `version.json` по URL
(бесплатно, без бэкенда), интерфейс под Firebase Remote Config уже зарезервирован
в коде (`lib/services/update_source.dart`) для v2.

## 1. Что видит пользователь

- При запуске (через 3 секунды) и далее раз в 6 часов приложение читает `version.json`.
- Если версия на сервере новее установленной — на **всех экранах** появляется
  баннер «Доступна версия X — нажмите, чтобы узнать, что нового».
- Тап по баннеру → подробности: описание изменений и ссылки на Google Play / App Store.
- Нет сети или файл недоступен → приложение молча продолжает работать.
- Проверить вручную: Профиль → «Проверить обновления».

## 2. Файл version.json

Лежит в архиве: `update/version.json`. Поля:

| Поле | Назначение |
|---|---|
| `latest_version` | самая свежая опубликованная версия, например `1.1.0` |
| `min_supported_version` | ниже этой версии обновление обязательное |
| `notes` | текст «Что нового» — показывается в диалоге баннера |
| `force_update` | `true` — баннер красный, обновление обязательно |
| `android_url` | ссылка на страницу в Google Play |
| `ios_url` | ссылка на страницу в App Store |

## 3. Где хостить файл бесплатно (5 минут)

GitHub Pages — рекомендуемый вариант:

1. Создайте публичный репозиторий, например `time-to-grow-updates`.
2. Положите туда `update/version.json` (в корень репозитория).
3. Settings → Pages → Branch: `main` → Save.
4. Адрес файла: `https://ВАШ_НИК.github.io/time-to-grow-updates/version.json`
5. Впишите его в `lib/core/app_version.dart` → `kDefaultUpdateUrl`
   (или временно прямо в приложении: Профиль → «URL проверки обновлений»).

Альтернатива: `raw.githubusercontent.com/ВАШ_НИК/РЕПО/main/version.json`.

> Примечание для веб-версии: хостинг должен отдавать заголовок
> `Access-Control-Allow-Origin` — GitHub Pages и raw.githubusercontent это делают.

## 4. Релиз новой версии — чек-лист

1. `pubspec.yaml` → `version: 1.1.0+2`.
2. `lib/core/app_version.dart` → `kAppVersion = '1.1.0'`, `kAppBuildNumber = 2`.
3. `CHANGELOG.md` → описать изменения.
4. Собрать и опубликовать сборки (Play Console / App Store Connect).
5. Обновить `version.json` на хостинге (`latest_version` + `notes` + ссылки).
6. Готово: устройства покажут баннер при следующем запуске либо в течение 6 часов.

## 5. Проверить механику прямо сейчас (без сервера)

Профиль → переключатель «Симулировать обновление» → баннер появится мгновенно
на всех экранах. Выключается тем же переключателем. Так работает полный путь
баннера: показ → диалог «Что нового» → ссылки на магазины.

## 6. Remote Config (план v2)

Интерфейс готов: `UpdateSource` → реализуйте `RemoteConfigUpdateSource`:

```dart
final String raw = FirebaseRemoteConfig.instance.getString('version_info');
return AppUpdateInfo.fromJson(jsonDecode(raw));
```

Затем в `UpdateService.check()` подмените `JsonHttpUpdateSource` на
`RemoteConfigUpdateSource`. Плюсы: правка текста обновления без коммита,
аудит изменений, таргетинг по платформам и странам.
