import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Общий кэш декодированных спрайтов: главный экран, карточки выбора,
/// мини-игра кормления — все берут картинку отсюда один раз.
class SpriteCache {
  SpriteCache._();

  static final Map<String, ui.Image> _cache = <String, ui.Image>{};
  static final Set<String> _loading = <String>{};

  static ui.Image? get(String asset) => _cache[asset];

  static bool contains(String asset) => _cache.containsKey(asset);

  /// Снимок кэша для painters (чтобы рисовать по актуальному набору).
  static Map<String, ui.Image> snapshot() =>
      Map<String, ui.Image>.of(_cache);

  /// Гарантирует, что спрайт загружен. Когда загрузка завершится,
  /// вызовет [onLoaded] (обычно setState).
  static void ensure(String asset, VoidCallback onLoaded) {
    if (_cache.containsKey(asset) || _loading.contains(asset)) return;
    _loading.add(asset);
    rootBundle.load(asset).then((ByteData data) async {
      final ui.Codec codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      _cache[asset] = frame.image;
      _loading.remove(asset);
      onLoaded();
    }).catchError((Object e) {
      _loading.remove(asset);
    });
  }
}
