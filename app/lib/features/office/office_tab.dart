import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/prefs.dart';
import '../../core/strings.dart';
import '../../game/game_controller.dart';
import '../../game/office_game.dart';
import '../../ui/pixel.dart';

/// Ofis: Flame sahnesi ve masaya düşen olay dosyaları.
class OfficeTab extends ConsumerWidget {
  const OfficeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final pending = game.scheme.pendingEventIds;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      children: [
        PixelPanel(
          title: Tr.tabOffice,
          badge: '${game.scheme.investorCount} ${Tr.investors}',
          padding: EdgeInsets.zero,
          child: const _OfficeScene(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                ref.read(onboardingVisibleProvider.notifier).show(),
            child: const Text(Tr.onboardingReplay),
          ),
        ),
        SectionHeader(Tr.pendingEvents, trailing: '${pending.length}'),
        if (pending.isEmpty)
          PixelPanel(
            fill: Px.inset,
            raised: false,
            child: Row(
              children: [
                const Icon(Icons.coffee_outlined, color: Px.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(Tr.noEvents, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        for (final id in pending)
          _EventCard(
            eventId: id,
            answer: game.answers[id],
            onAnswer: (i) => ctrl.answerEvent(id, i),
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
    final game = _game ??= OfficeGame(background: Px.inset);
    game.update2(snapshot);

    return AspectRatio(
      aspectRatio: OfficeGame.sceneWidth / OfficeGame.sceneHeight,
      child: GameWidget(game: game),
    );
  }
}

/// Olay dosyası. Başlıkta kırmızı "OLAY" rozeti, metin, altında seçenekler.
///
/// Seçeneklerde yalnız nakit bedeli açık yazılır; şüphe ve panik yön okuyla
/// gösterilir, sayısı gizli. Neden: para somut, oyuncu bütçe yapabilsin;
/// itibar etkilerinin tam sayısı ise kartı bir hesap tablosuna çevirir.
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
    return PixelPanel(
      title: def.title,
      badge: answer == null ? Tr.eventTag : Tr.answered,
      badgeColor: answer == null ? Px.red : Px.green,
      margin: const EdgeInsets.only(bottom: 12),
      fill: Px.panelRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(def.text, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (var i = 0; i < def.options.length; i++) ...[
            _OptionButton(
              option: def.options[i],
              selected: answer == i,
              onTap: () => onAnswer(i),
            ),
            if (i < def.options.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final EventOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = option.effects;
    final chips = <Widget>[
      if (e.suspicion != 0)
        EffectChip(
          icon: e.suspicion > 0
              ? Icons.arrow_drop_up_rounded
              : Icons.arrow_drop_down_rounded,
          text: Tr.suspicion,
          color: e.suspicion > 0 ? Px.red : Px.green,
        ),
      if (e.panic != 0)
        EffectChip(
          icon: e.panic > 0
              ? Icons.arrow_drop_up_rounded
              : Icons.arrow_drop_down_rounded,
          text: Tr.panic,
          color: e.panic > 0 ? Px.red : Px.green,
        ),
      if (e.channelMult != null)
        EffectChip(
          icon: e.channelMult! > 1
              ? Icons.arrow_drop_up_rounded
              : Icons.arrow_drop_down_rounded,
          text: Tr.inflowShort,
          color: e.channelMult! > 1 ? Px.green : Px.red,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelButton(
          label: option.label,
          kind: selected ? PixelButtonKind.primary : PixelButtonKind.secondary,
          icon: selected ? Icons.check_rounded : null,
          cost: e.cash != 0 ? money(e.cash) : null,
          costColor: e.cash > 0 ? Px.green : (selected ? Px.ink : Px.amber),
          onPressed: onTap,
        ),
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 0, 0),
            child: Wrap(spacing: 10, children: chips),
          ),
      ],
    );
  }
}
