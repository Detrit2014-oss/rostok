# Экранное время: рост питомца только с погашенным экраном

С версии **1.1.0** сессия детокса привязана к экранному времени телефона.
Засчитываются только минуты, когда пользователя не было в приложении **и
экран был погашен**. Пока приложение открыто — счёт на паузе (вы же
смотрите в экран).

## Как это работает на каждой платформе

| Платформа | Точность | Механика |
|---|---|---|
| Android + разрешение «Доступ к использованию» | ★★★ точно | Из системных событий экрана (UsageStats) вычитается всё время с включённым экраном. Можно пользоваться другими приложениями — их время в рост не пойдёт. |
| Android без разрешения | ★★ | Считается всё время, когда приложение свёрнуто/закрыто. |
| iOS | ★★ | Считается всё время вне приложения. Системный Screen Time API закрыт entitlement'ами Apple (запрос отдельно). |
| Web (Chrome) | ★★ | Считается время, когда вкладка приложения скрыта/неактивна. |

Без нативного кода приложение работает сразу на всех платформах — просто
учёт на Android менее строгий. Подключите нативную часть ниже, чтобы
сделать его точным.

## Нативная часть для Android (5 минут)

### Шаг 1. Создайте MainActivity.kt

После `flutter create .` откройте
`android/app/src/main/kotlin/<ваш/пакет>/MainActivity.kt`
(путь к пакету смотрите в `android/app/build.gradle` → `applicationId`,
например `com.example.time_to_grow`) и замените содержимое файла:

```kotlin
package com.example.time_to_grow // ← подставьте свой applicationId!

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "time_to_grow/screen_time"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkSupport" -> result.success(
                        if (hasUsageAccess()) "granted" else "denied"
                    )
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "screenOnMillis" -> {
                        val start = call.argument<Long>("start") ?: 0L
                        val end = call.argument<Long>("end") ?: 0L
                        result.success(
                            if (hasUsageAccess()) screenOnMillis(start, end) else -1
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Выдан ли доступ «Доступ к использованию» (Usage Access). */
    private fun hasUsageAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Сколько миллисекунд в интервале [start, end] экран был ВКЛЮЧЁН.
     * События SCREEN_INTERACTIVE / SCREEN_NON_INTERACTIVE — с Android 11
     * (API 30). На более старых возвращаем -1: Dart-код засчитает весь фон.
     */
    private fun screenOnMillis(start: Long, end: Long): Long {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return -1L
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(start, end)
        val event = UsageEvents.Event()
        var lastOn = -1L
        var total = 0L
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.SCREEN_INTERACTIVE -> lastOn = event.timeStamp
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    if (lastOn > 0) total += (event.timeStamp - lastOn).coerceAtLeast(0)
                    lastOn = -1
                }
            }
        }
        if (lastOn > 0) {
            total += (minOf(System.currentTimeMillis(), end) - lastOn).coerceAtLeast(0)
        }
        return total
    }
}
```

### Шаг 2. Разрешение в манифесте

В `android/app/src/main/AndroidManifest.xml` добавьте внутрь `<manifest>`:

```xml
<uses-permission
    android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" />
```

и атрибут в корневой тег `<manifest xmlns:android="…" …>`:

```xml
xmlns:tools="http://schemas.android.com/tools"
```

### Шаг 3. Проверка

1. Запустите приложение: `flutter run -d <android-устройство>`.
2. Профиль → **Экранное время** → «Дать доступ (Android)» → включите
   «Время Расти» в системном списке.
3. Начните сессию «Отложить телефон», погасите экран на пару минут,
   потом разблокируйте и попользуйтесь другим приложением — вернувшись,
   увидите: `Экран горел: X мин — не в счёт`. В рост пойдут только
   минуты с погашенным экраном.

## Как тестируется на Web (Chrome)

Нативного канала нет → `ScreenTimeService` возвращает «недоступно»,
а сессия считает время, когда **вкладка приложения скрыта** (аналог
погашенного экрана). Это позволяет проверять механику прямо в Chrome:
сверните вкладку → счёт идёт, вернитесь → увидите накопленное время.
Для мгновенного теста без переключения вкладок включите машину времени
×60 в Профиле.

## Почему не iOS Screen Time API

Семейство API Screen Time (FamilyControls/DeviceActivity) требует
специального entitlement, который Apple выдаёт по заявке, и работает
только на iOS 15+. Это отдельная задача для релиза в App Store; текущий
механизм «время вне приложения» — стандартная честная альтернатива.
