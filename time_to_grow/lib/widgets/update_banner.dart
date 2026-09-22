import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_version.dart';
import '../core/theme.dart';
import '../models/app_update.dart';
import '../services/update_service.dart';

/// Глобальный баннер «Доступно обновление».
/// Показывается на всех экранах (сверху, над контентом), пока
/// UpdateService.available != null. Тап → подробности «Что нового».
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final UpdateService update = context.watch<UpdateService>();
    final AppUpdateInfo? info = update.available;
    if (info == null) return const SizedBox.shrink();

    return Material(
      color: info.forceUpdate ? Palette.coral : Palette.blue,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () => _showDetails(context, info),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: <Widget>[
                const Icon(Icons.system_update_alt_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Доступна версия ${info.latestVersion} — нажмите, чтобы '
                    'узнать, что нового',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.85)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, AppUpdateInfo info) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.system_update_alt_rounded,
                  color: info.forceUpdate ? Palette.coral : Palette.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Обновление до версии ${info.latestVersion}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Установлена версия $kAppVersion.',
              style: const TextStyle(color: Palette.inkSoft, fontSize: 13),
            ),
            if ((info.notes ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                info.notes!,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (info.androidUrl != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _copyLink(context, 'Google Play', info.androidUrl!),
                    icon: const Icon(Icons.android_rounded, size: 18),
                    label: const Text('Ссылка (Android)'),
                  ),
                if (info.iosUrl != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _copyLink(context, 'App Store', info.iosUrl!),
                    icon: const Icon(Icons.phone_iphone_rounded, size: 18),
                    label: const Text('Ссылка (iOS)'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'В мобильных сборках кнопка будет открывать магазин (url_launcher); '
              'в веб-версии — скопируйте ссылку.',
              style: TextStyle(fontSize: 12, color: Palette.inkSoft),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.read<UpdateService>().clearAvailable();
                },
                child: const Text('Напомнить позже'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink(BuildContext context, String store, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ссылка на $store скопирована')),
    );
  }
}
