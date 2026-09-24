import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../services/quest_service.dart';
import '../widgets/common.dart';

/// Магазин «Ростка» (v1.5.0+): тратим монетки, заработанные паузами.
///  • Декоративные рамки для активного питомца.
///  • Гардероб (v1.9.0): шапки, шарфы, очки и окрасы-скины.
///  • Заморозка серии 🧊 (v1.7.0) — спасает streak при пропуске дня.
///
/// v1.9.0: эмодзи 🪙 заменён рисованой монеткой CoinIcon — на части
/// устройств Android он показывался пустым квадратом.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const List<_FrameItem> _frames = <_FrameItem>[
    _FrameItem('none', 'Без рамки', '✨', 0, 'Просто и мило'),
    _FrameItem('gold', 'Золотая', '🥇', 150, 'Блеск чемпионов'),
    _FrameItem('neon', 'Неоновая', '💠', 250, 'Свет в темноте'),
    _FrameItem('flower', 'Цветочная', '🌸', 200, 'Весна круглый год'),
  ];

  /// Каталог гардероба (v1.9.0): slot → hat|neck|face|skin.
  static const List<_WardrobeItem> _wardrobe = <_WardrobeItem>[
    _WardrobeItem('cap', 'hat', 'Кепка', '🧢', 80, 'Спортивный стиль'),
    _WardrobeItem('beanie', 'hat', 'Шапочка', '🧶', 120, 'Тепло в холода'),
    _WardrobeItem('crown', 'hat', 'Корона', '👑', 400, 'Для особенных питомцев'),
    _WardrobeItem('scarf', 'neck', 'Шарф', '🧣', 100, 'В полосочку, тёплый'),
    _WardrobeItem('bow', 'neck', 'Бантик', '🎀', 90, 'Мило и нарядно'),
    _WardrobeItem('glasses', 'face', 'Очки', '👓', 150, 'Умный взгляд'),
    _WardrobeItem('shades', 'face', 'Тёмные очки', '🕶️', 200, 'Звезда лужайки'),
    _WardrobeItem('golden', 'skin', 'Золотой окрас', '🌟', 500, 'Сияет как монетка'),
    _WardrobeItem('mint', 'skin', 'Мятный окрас', '🌿', 300, 'Свежесть после дождя'),
    _WardrobeItem('rose', 'skin', 'Розовый окрас', '🌸', 300, 'Нежность и доброта'),
  ];

  static const Map<String, String> _slotTitles = <String, String>{
    'hat': 'Головные уборы',
    'neck': 'Шея',
    'face': 'Лицо',
    'skin': 'Окрасы',
  };

  void _buyFrame(BuildContext context, Pet pet, _FrameItem f) {
    final PetService petService = context.read<PetService>();
    final bool ok = petService.buyFrame(pet, f.id, f.price);
    if (ok && f.price > 0) {
      // ignore: use_build_context_synchronously
      context.read<QuestService>().addProgress('shop_1', 1);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Рамка «${f.title}» надета!' : 'Не хватает монеток',
        ),
      ),
    );
  }

  void _buyWardrobe(BuildContext context, Pet pet, _WardrobeItem w) {
    final PetService petService = context.read<PetService>();
    final bool owned = petService.wardrobe.contains(w.id);
    if (owned) {
      // Уже куплено — надеваем/снимаем.
      petService.equipItem(pet, w.slot, w.id);
      return;
    }
    final bool ok = petService.buyWardrobeItem(w.id, w.price);
    if (ok) {
      petService.equipItem(pet, w.slot, w.id);
      // ignore: use_build_context_synchronously
      context.read<QuestService>().addProgress('shop_1', 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${w.title} — новое в гардеробе!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не хватает монеток')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PetService petService = context.watch<PetService>();
    final Pet? active = petService.activePet;

    return Scaffold(
      appBar: AppBar(title: const Text('Магазин')),
      body: Container(
        color: Palette.bg,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // Кошелёк
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Palette.yellow, Color(0xFFFFB000)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Palette.yellowDark, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    const CoinIcon(size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${petService.coins}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'монеток · серия ${petService.streakDays} дн. · 🧊 ×${petService.freezes}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Гардероб (v1.9.0) ──
              const Text(
                'Гардероб питомца',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              if (active == null)
                const Text(
                  'Сначала выберите питомца — тогда его можно будет нарядить.',
                  style: TextStyle(color: Palette.inkSoft, fontSize: 13),
                )
              else
                _buildWardrobeSection(context, petService, active),

              const SizedBox(height: 18),
              const Text(
                'Рамки для питомца',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              if (active != null)
                ..._frames.map((_FrameItem f) {
                  final bool worn = active.frame == f.id;
                  return InfoCard(
                    child: Row(
                      children: <Widget>[
                        Text(f.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                f.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Palette.ink,
                                ),
                              ),
                              Text(
                                f.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Palette.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (worn)
                          const Chip(
                            label: Text('Надета'),
                            backgroundColor: Palette.greenSoft,
                            labelStyle: TextStyle(
                              color: Palette.greenDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: () => _buyFrame(context, active, f),
                            icon: const Icon(Icons.paid_rounded, size: 16),
                            label: f.price == 0
                                ? const Text('Снять')
                                : CoinText(f.price, fontSize: 14),
                          ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 18),
              const Text(
                'Защита серии',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              InfoCard(
                child: Row(
                  children: <Widget>[
                    const Text('🧊', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Заморозка серии',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: Palette.ink,
                            ),
                          ),
                          Text(
                            'Пропустили день? 🧊 сохранит streak. В запасе: '
                            '${petService.freezes}/2',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Palette.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: petService.freezes >= 2
                          ? null
                          : () => _buyFreeze(context),
                      icon: const Icon(Icons.ac_unit_rounded, size: 16),
                      label: CoinText(PetService.kFreezePrice, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeSection(
      BuildContext context, PetService petService, Pet active) {
    final List<String> slots = <String>['hat', 'neck', 'face', 'skin'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String slot in slots) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              _slotTitles[slot] ?? slot,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Palette.inkSoft,
              ),
            ),
          ),
          ..._wardrobe
              .where((_WardrobeItem w) => w.slot == slot)
              .map((_WardrobeItem w) {
            final bool owned = petService.wardrobe.contains(w.id);
            final bool worn = switch (w.slot) {
              'hat' => active.hat == w.id,
              'neck' => active.neck == w.id,
              'face' => active.face == w.id,
              'skin' => active.skin == w.id,
              _ => false,
            };
            return InfoCard(
              child: Row(
                children: <Widget>[
                  Text(w.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          w.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Palette.ink,
                          ),
                        ),
                        Text(
                          w.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (worn)
                    const Chip(
                      label: Text('Надето'),
                      backgroundColor: Palette.greenSoft,
                      labelStyle: TextStyle(
                        color: Palette.greenDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    )
                  else if (owned)
                    TextButton(
                      onPressed: () =>
                          petService.equipItem(active, w.slot, w.id),
                      child: const Text('Надеть'),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => _buyWardrobe(context, active, w),
                      icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                      label: CoinText(w.price, fontSize: 14),
                    ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  void _buyFreeze(BuildContext context) {
    final PetService petService = context.read<PetService>();
    final bool ok = petService.buyFreeze();
    if (ok) {
      context.read<QuestService>().addProgress('shop_1', 1);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Заморозка 🧊 куплена! Серия спасена от пропуска.'
              : petService.freezes >= 2
                  ? 'В запасе уже 2 заморозки'
                  : 'Не хватает монеток',
        ),
      ),
    );
  }
}

class _FrameItem {
  const _FrameItem(this.id, this.title, this.emoji, this.price, this.subtitle);
  final String id;
  final String title;
  final String emoji;
  final int price;
  final String subtitle;
}

class _WardrobeItem {
  const _WardrobeItem(
      this.id, this.slot, this.title, this.emoji, this.price, this.subtitle);
  final String id;
  final String slot;
  final String title;
  final String emoji;
  final int price;
  final String subtitle;
}
