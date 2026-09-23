import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';
import 'asset_shop.dart';
import 'end_banner.dart';
import 'retire_section.dart';

/// "Aradaki hayat": bölüm bitti, para sayılıyor, sıradaki iş seçiliyor.
///
/// Neden ayrı tam ekran: burada zaman akmıyor, HUD'un ve sekmelerin anlamı
/// yok. Oyuncu istediği kadar kalır.
class BetweenScreen extends ConsumerWidget {
  const BetweenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final content = ref.read(contentProvider);
    final theme = Theme.of(context);
    final career = game.career;
    final last = career.chapters.last;

    final recordColor = career.record > 75
        ? Px.red
        : career.record > 50
            ? Px.amber
            : Px.blue;

    return Scaffold(
      backgroundColor: Px.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            EndBanner(end: last.end),
            const SizedBox(height: 14),

            PixelPanel(
              title: Tr.chapterSummary,
              badge: '${Tr.chapterShort}${career.chapters.length}',
              badgeColor: Px.gold,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: Tr.week,
                          value: '${last.weeks}',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: StatTile(
                          label: Tr.totalInflow,
                          value: money(last.collected),
                          icon: Icons.download_outlined,
                          color: Px.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: Tr.victims,
                          value: '${last.victims}',
                          icon: Icons.groups_outlined,
                          color: Px.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: StatTile(
                          label: Tr.tookHome,
                          value: money(last.tookHome),
                          icon: Icons.luggage_outlined,
                          color: Px.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            CareerHeading(Tr.betweenTitle),
            PixelPanel(
              title: Tr.vault,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: Tr.cleanMoney,
                          value: money(career.cleanMoney),
                          icon: Icons.account_balance_outlined,
                          color: Px.green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: StatTile(
                          label: Tr.dirtyMoney,
                          value: money(career.dirtyMoney),
                          icon: Icons.work_outline,
                          color: Px.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  StatTile(
                    label: Tr.usableCapital,
                    value: money(career.usableCapital),
                    icon: Icons.rocket_launch_outlined,
                    color: Px.gold,
                  ),
                  const SizedBox(height: 8),
                  Text(Tr.dirtyNote, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),

            PixelPanel(
              title: Tr.record,
              badge: career.record.toStringAsFixed(0),
              badgeColor: recordColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PixelBar(
                    value: career.record / 100,
                    color: recordColor,
                    segments: 20,
                    height: 16,
                  ),
                  const SizedBox(height: 8),
                  Text(Tr.recordNote, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const AssetShop(),
            const SizedBox(height: 18),

            CareerHeading(Tr.chooseScheme, note: Tr.chooseSchemeNote),
            for (final id in game.offers)
              _SchemeCard(
                type: content.scheme(id),
                onPick: () => ctrl.chooseScheme(id),
              ),
            const SizedBox(height: 18),

            // En altta: önce sıradaki işi göster, çekilmeyi en son sor.
            const RetireSection(),
          ],
        ),
      ),
    );
  }
}

/// Şema teklifi. Başlık şeridinde tür adı, rozette kılıf.
class _SchemeCard extends StatelessWidget {
  const _SchemeCard({required this.type, required this.onPick});

  final SchemeType type;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PixelPanel(
      title: type.name,
      badge: Tr.schemeOffer,
      badgeColor: Px.gold,
      fill: Px.panelRaised,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(type.pitch, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          StatRow(Tr.schemeCover, type.cover, numeric: false),
          StatRow(Tr.schemeStartRate, pct(type.startRateWeekly, digits: 2)),
          StatRow(Tr.schemeCeiling, pct(type.maxRateWeekly, digits: 1)),
          const SizedBox(height: 10),
          PixelButton(
            label: Tr.schemeStart,
            kind: PixelButtonKind.primary,
            icon: Icons.play_arrow_rounded,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}
