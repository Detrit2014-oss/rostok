/// ─────────────────────────────────────────────────────────────────────
/// Текущая версия приложения.
///
/// ⚠️ ПРИ КАЖДОМ РЕЛИЗЕ обновлять вместе с pubspec.yaml (version:):
///   1) kAppVersion      — совпадает с версией в pubspec
///   2) kAppBuildNumber  — совпадает с build-номером в pubspec (+N)
///   3) CHANGELOG.md     — описать изменения
///   4) version.json на хостинге — см. docs/UPDATE_FLOW.md
/// ─────────────────────────────────────────────────────────────────────
const String kAppVersion = '2.0.0';

const int kAppBuildNumber = 9;

/// URL файла version.json для проверки обновлений.
/// Замените на свой адрес (GitHub Pages / любой статический хостинг):
/// инструкция — в docs/UPDATE_FLOW.md. Также URL можно поменять на лету
/// в приложении: Профиль → «URL проверки обновлений».
const String kDefaultUpdateUrl =
    'https://your-username.github.io/time-to-grow-updates/version.json';

/// Интервал фоновой проверки обновлений (в часах).
const int kUpdateCheckIntervalHours = 6;
