import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/pet_catalog.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../widgets/common.dart';
import '../widgets/pet_canvas.dart';

/// Большой экран выбора питомца.
///
/// Показывается:
///  • при первом запуске (коллекция пуста) — вместо главного экрана;
///  • после взросления питомца — по кнопке «Выбрать нового питомца».
///
/// С v1.2.0 — десять видов на прокручиваемой сетке больших живых
/// карточек + кубик «Случайный питомец» для любителей сюрпризов.
class PetSelectionScreen extends StatefulWidget {
  const PetSelectionScreen({super.key, this.canDismiss = false});

  /// true — экран открыт поверх существующей коллекции (есть кнопка «Позже»).
  /// false — первый запуск, без выбора дальше не пройти.
  final bool canDismiss;

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  PetType? _selected;

  /// Превью-питомец стадии «Малыш» — показывает, кем станет яйцо.
  Pet _preview(PetType type) => Pet(
        id: 'preview-${type.name}',
        name: speciesOfType(type).name,
        type: type,
        bornAt: 0,
        growthMinutes: Pet.stageThresholds[1],
      );

  void _confirm() {
    final PetType? type = _selected;
    if (type == null) return;
    context.read<PetService>().createPet(type);
    if (widget.canDismiss && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Кубик: сразу создаём случайного питомца — приятный сюрприз.
  void _random() {
    final PetType type =
        PetType.values[Random().nextInt(PetType.values.length)];
    context.read<PetService>().createPet(type);
    if (widget.canDismiss && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Palette.skyTop, Palette.skyBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Выбери питомца! 🐣',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Он вырастет, пока вы отдыхаете от телефона. '
                          'Всего видов: ${kPetCatalog.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Palette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    // В Chrome/планшете карточки остаются крупными,
                    // но не растягиваются на весь монитор.
                    final double maxW = c.maxWidth >= 560 ? 520 : c.maxWidth;
                    return Center(
                      child: SizedBox(
                        width: maxW,
                        child: GridView.count(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                          children: <Widget>[
                            for (final PetSpecies s in kPetCatalog)
                              _card(s),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  12 + MediaQuery.of(context).padding.bottom * 0.4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BigButton(
                      label: _selected == null
                          ? 'Выберите питомца'
                          : 'Встречаем «${speciesOfType(_selected!).accusative}»!',
                      icon: Icons.emoji_nature_rounded,
                      fullWidth: true,
                      onPressed: _selected == null ? null : _confirm,
                    ),
                    TextButton.icon(
                      onPressed: _random,
                      icon: const Icon(Icons.casino_rounded, size: 18),
                      label: const Text('Случайный питомец 🎲'),
                    ),
                    if (widget.canDismiss)
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Позже'),
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

  Widget _card(PetSpecies s) {
    final bool selected = _selected == s.type;
    return InkWell(
      onTap: () => setState(() => _selected = s.type),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Palette.green : Palette.border,
            width: selected ? 3 : 2,
          ),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(color: Palette.greenDark, offset: Offset(0, 3)),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: PetCanvas(pets: <Pet>[_preview(s.type)]),
                    ),
                    if (selected)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Palette.green,
                          child: Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${s.emoji} ${s.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Palette.inkSoft,
                      ),
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
}
