import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content.dart';
import '../../core/prefs.dart';
import '../../core/strings.dart';
import '../../game/game_controller.dart';
import '../../game/office_game.dart';

/// Ofis: ileride Flame sahnesi, şimdilik olay kartlarının düştüğü masa.
class OfficeTab extends ConsumerWidget {
  const OfficeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final content = ref.read(gameControllerProvider.notifier);
    final pending = game.scheme.pendingEventIds;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _OfficeScene(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                ref.read(onboardingVisibleProvider.notifier).show(),
            child: const Text(Tr.onboardingReplay),
          ),
        ),
        const SizedBox(height: 8),
        Text(Tr.pendingEvents, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          Text(Tr.noEvents, style: theme.textTheme.bodyMedium),
        for (final id in pending)
          _EventCard(
            eventId: id,
            answer: game.answers[id],
            onAnswer: (i) => content.answerEvent(id, i),
          ),
      ],
    );
  }
}

/// Ofis sahnesi. Oyunun sayıları buraya görüntü olarak yansır: kalabalık
/// büyür, mekân değişir, şüphe yükselince kapıya biri diker.
class _OfficeScene extends ConsumerStatefulWidget {
  const _OfficeScene();

  @override
  ConsumerState<_OfficeScene> createState() => _OfficeSceneState();
}

class _OfficeSceneState extends ConsumerState<_OfficeScene> {
  OfficeGame? _game;

  @override
  Widget build(BuildContext context) {
    final scheme = ref.watch(gameControllerProvider.select((g) => g.scheme));
    final snapshot = OfficeSnapshot(
      investors: scheme.investorCount,
      suspicion: scheme.suspicion,
      bankRun: scheme.bankRun,
    );
    // Oyun nesnesi bir kez kurulur; sonraki değişiklikler ona itilir, sahne
    // baştan yaratılmaz.
    final game = _game ??= OfficeGame(
      background: Theme.of(context).colorScheme.surfaceContainer,
    );
    game.update2(snapshot);

    return AspectRatio(
      aspectRatio: OfficeGame.sceneWidth / OfficeGame.sceneHeight,
      child: GameWidget(game: game),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({
    required this.eventId,
    required this.answer,
    required this.onAnswer,
  });

  final String eventId;
  final int? answer;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = ref.read(contentProvider).events.byId(eventId);
    if (def == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(def.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(def.text),
            const SizedBox(height: 12),
            for (var i = 0; i < def.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: answer == i
                    ? FilledButton(
                        onPressed: () => onAnswer(i),
                        child: Text('${def.options[i].label}  ·  ${Tr.answered}'),
                      )
                    : OutlinedButton(
                        onPressed: () => onAnswer(i),
                        child: Text(def.options[i].label),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
