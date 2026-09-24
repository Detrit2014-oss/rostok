import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/pet.dart';
import '../services/focus_session_service.dart';
import '../services/pet_service.dart';
import '../widgets/common.dart';
import '../widgets/pet_canvas.dart';
import 'pet_selection_screen.dart';

/// Главный экран: сцена с питомцем + управление сессией детокса.
class PetScreen extends StatelessWidget {
  const PetScreen({super.key});

  String _fmt(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final PetService pet = context.watch<PetService>();
    final FocusSessionService session = context.watch<FocusSessionService>();
    final Pet? active = pet.activePet;

    return Scaffold(
      appBar: AppBar(title: const Text('Росток')),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: <Widget>[
                    _chip(context, Icons.schedule_rounded,
                        'Сегодня: ${pet.todayMinutes} мин'),
                    const SizedBox(width: 8),
                    _chip(context, Icons.local_fire_department_rounded,
                        'Серия: ${pet.streakDays}'),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: InfoCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: PetCanvas(
                        pets: pet.pets,
                        sleeping: session.isRunning,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: <Widget>[
                      if (session.isRunning)
                        _runningCard(context, session)
                      else
                        _idleCard(context, active),
                      const SizedBox(height: 12),
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Text('Мои питомцы',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                ),
                                Text('Взрослых: ${pet.adultCount}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Palette.inkSoft)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _petsWrap(pet),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Palette.greenDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Palette.ink),
          ),
        ],
      ),
    );
  }

  Widget _runningCard(BuildContext context, FocusSessionService session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Palette.greenDark, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'Телефон отдыхает — питомец растёт',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(session.elapsed),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          _statusLine(session),
          if (session.sessionScreenOnMs > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Экран горел: ${_fmt(Duration(milliseconds: session.sessionScreenOnMs))} — не в счёт',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 14),
          BigButton(
            label: 'Я вернулся',
            icon: Icons.check_circle_rounded,
            color: Palette.yellow,
            shadow: Palette.yellowDark,
            textColor: const Color(0xFF5B4300),
            onPressed: () => _stopSession(context),
          ),
        ],
      ),
    );
  }

  /// Живой статус: растёт ли питомец прямо сейчас.
  Widget _statusLine(FocusSessionService session) {
    if (session.timeMachine) {
      return const Text(
        'Тестовый режим: 1 секунда = 1 минута',
        style: TextStyle(
            color: Palette.yellow,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      );
    }
    if (session.countingNow) {
      return const Text(
        '🌱 Экран погашен — рост идёт',
        style: TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700),
      );
    }
    return const Text(
      '⏸ Счёт на паузе: экран включён. Сверните приложение — и питомец начнёт расти',
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600),
    );
  }

  Widget _idleCard(BuildContext context, Pet? active) {
    final FocusSessionService session = context.watch<FocusSessionService>();
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.pets_rounded, color: Palette.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active == null
                      ? 'Ждём новое яйцо'
                      : '${active.name} — ${active.stageName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              if (active != null)
                Text(
                  'до роста: ${active.minutesToNextStage()} мин',
                  style:
                      const TextStyle(fontSize: 12, color: Palette.inkSoft),
                ),
              if (active != null) ...<Widget>[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _renamePet(context, active),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_rounded,
                        size: 18, color: Palette.inkSoft),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: active?.stageProgress ?? 0,
              minHeight: 10,
              backgroundColor: const Color(0xFFEFEFEF),
              color: Palette.green,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: BigButton(
              label: active == null
                  ? 'Отложить телефон — растим питомца'
                  : 'Отложить телефон: растим ${active.name}',
              icon: Icons.phonelink_erase_rounded,
              fullWidth: true,
              onPressed: () => context.read<FocusSessionService>().start(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Рост идёт, пока экран телефона погашен'
              '${session.timeMachine ? '' : ' (а в Chrome — пока вкладка скрыта)'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, color: Palette.inkSoft),
            ),
          ),
          if (active == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PetSelectionScreen(canDismiss: true),
                    ),
                  ),
                  child: const Text('Выбрать нового питомца'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _petsWrap(PetService pet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final Pet p in pet.pets)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.isAdult ? Palette.greenSoft : const Color(0xFFFFF6E3),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: p.isAdult ? Palette.green : const Color(0xFFF0E0C0),
                width: 1.5,
              ),
            ),
            child: Text(
              '${_stageEmoji(p.stage)} ${p.name} · ${p.stageName}',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink),
            ),
          ),
      ],
    );
  }

  String _stageEmoji(int stage) {
    switch (stage) {
      case 3:
        return '🐾';
      case 2:
        return '🐣';
      case 1:
        return '🐥';
      default:
        return '🥚';
    }
  }

  Future<void> _stopSession(BuildContext context) async {
    final FocusSessionService session = context.read<FocusSessionService>();
    final PetService pet = context.read<PetService>();
    final int minutes = session.stop();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          minutes == 0
              ? 'Пока 0 мин — телефон не отдыхал 🙈 Питомец растёт, '
                  'когда приложение свёрнуто и экран погашен'
              : 'Отлично! Питомцу начислено $minutes мин без телефона. 💚',
        ),
      ),
    );
    final String? evolved = pet.lastEvolvedPetName;
    if (evolved != null) {
      pet.ackEvolution();
      _showEvolutionDialog(context, evolved);
    }
  }

  void _showEvolutionDialog(BuildContext context, String name) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Ура! 🎉'),
        content: Text(
          '«$name» вырос во взрослого питомца! На следующей прогулке '
          'появится новое яйцо — коллекция продолжается.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отлично!'),
          ),
        ],
      ),
    );
  }

  Future<void> _renamePet(BuildContext context, Pet pet) async {
    final TextEditingController ctrl = TextEditingController(text: pet.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Как зовут питомца?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'Имя питомца'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (newName == null || newName.isEmpty || !context.mounted) return;
    context.read<PetService>().renamePet(pet.id, newName);
  }
}
