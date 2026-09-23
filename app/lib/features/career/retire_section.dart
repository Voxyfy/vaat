import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';
import 'end_banner.dart';

/// Kariyer sonlarının metinleri tek yerde: aradaki hayat listesi ve kariyer
/// sonu ekranı aynı adı, aynı notu göstermeli.
abstract final class EndingTexts {
  static String name(CareerEnding e) => switch (e) {
        CareerEnding.farm => Tr.endingFarm,
        CareerEnding.balkan => Tr.endingBalkan,
        CareerEnding.corporate => Tr.endingCorporate,
        CareerEnding.informant => Tr.endingInformant,
        CareerEnding.confession => Tr.endingConfession,
        CareerEnding.poverty => Tr.endingPoverty,
        CareerEnding.prison => Tr.endingPrison,
      };

  static String note(CareerEnding e) => switch (e) {
        CareerEnding.farm => Tr.endingFarmNote,
        CareerEnding.balkan => Tr.endingBalkanNote,
        CareerEnding.corporate => Tr.endingCorporateNote,
        CareerEnding.informant => Tr.endingInformantNote,
        CareerEnding.confession => Tr.endingConfessionNote,
        CareerEnding.poverty => Tr.endingPovertyNote,
        CareerEnding.prison => Tr.endingPrisonNote,
      };

  /// Kilitli sonun ne istediği. Hapis seçilemez, bu yüzden metni yok.
  static String requirement(CareerEnding e) => switch (e) {
        CareerEnding.farm => Tr.endingFarmReq,
        CareerEnding.balkan => Tr.endingBalkanReq,
        CareerEnding.corporate => Tr.endingCorporateReq,
        CareerEnding.informant => Tr.endingInformantReq,
        CareerEnding.confession => Tr.endingConfessionReq,
        CareerEnding.poverty => Tr.endingPovertyReq,
        CareerEnding.prison => '',
      };

  static IconData icon(CareerEnding e) => switch (e) {
        CareerEnding.farm => Icons.agriculture_outlined,
        CareerEnding.balkan => Icons.coffee_outlined,
        CareerEnding.corporate => Icons.apartment_outlined,
        CareerEnding.informant => Icons.record_voice_over_outlined,
        CareerEnding.confession => Icons.family_restroom_outlined,
        CareerEnding.poverty => Icons.nightlight_outlined,
        CareerEnding.prison => Icons.gavel_outlined,
      };
}

/// "Masadan kalk": aradaki hayatta kariyeri bitirme seçenekleri.
///
/// Kilitli sonlar da listede, koşuluyla birlikte. Neden: oyuncu bir sonraki
/// bölümde neyi hedefleyeceğini burada görür; gizli tutulan hedef hedef değil.
class RetireSection extends ConsumerWidget {
  const RetireSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final career = ref.watch(gameControllerProvider.select((g) => g.career));
    final endings = [
      for (final e in CareerEnding.values)
        if (e.voluntary) e,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CareerHeading(Tr.retireTitle, note: Tr.retireNote),
        StatTile(
          label: Tr.retireScoreNow,
          value: money(career.score),
          icon: Icons.emoji_events_outlined,
          color: Px.gold,
        ),
        const SizedBox(height: 10),
        for (final e in endings)
          _EndingCard(
            ending: e,
            unlocked: career.canEnd(e),
            onPick: () => _confirm(context, ref, e),
          ),
      ],
    );
  }

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, CareerEnding e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Px.panel,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(Tr.retireConfirmTitle),
        content: Text('${EndingTexts.name(e)}\n\n${Tr.retireConfirmBody}'),
        actions: [
          PixelButton(
            label: Tr.cancel,
            dense: true,
            expand: false,
            kind: PixelButtonKind.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          PixelButton(
            label: Tr.confirmRetire,
            dense: true,
            expand: false,
            kind: PixelButtonKind.danger,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(gameControllerProvider.notifier).retire(e);
  }
}

class _EndingCard extends StatelessWidget {
  const _EndingCard({
    required this.ending,
    required this.unlocked,
    required this.onPick,
  });

  final CareerEnding ending;
  final bool unlocked;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PixelPanel(
      title: EndingTexts.name(ending),
      badge: unlocked
          ? '${Tr.retireMultiplier} ×${ending.multiplier.toStringAsFixed(1)}'
          : Tr.retireLocked,
      badgeColor: unlocked ? Px.gold : Px.muted,
      fill: unlocked ? Px.panelRaised : Px.panel,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(EndingTexts.icon(ending),
                  size: 22, color: unlocked ? Px.gold : Px.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  unlocked
                      ? EndingTexts.note(ending)
                      : EndingTexts.requirement(ending),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PixelButton(
            label: unlocked ? Tr.confirmRetire : Tr.retireLocked,
            kind: unlocked ? PixelButtonKind.danger : PixelButtonKind.ghost,
            icon: unlocked ? Icons.logout_rounded : Icons.lock_outline,
            dense: true,
            onPressed: unlocked ? onPick : null,
          ),
        ],
      ),
    );
  }
}
