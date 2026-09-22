import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import 'end_banner.dart';

/// "Aradaki hayat" ekranının alışveriş bölümü: aklama, işler, tanıdıklar,
/// kaçış planı ve ortak.
///
/// Hepsi temiz parayla alınır. Kara parayla açıkça şirket almak zaten şüphe
/// çeker; oyuncuyu önce aklamaya zorlayan şey bu.
class AssetShop extends ConsumerWidget {
  const AssetShop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final content = ref.read(contentProvider);
    final career = game.career;
    final theme = Theme.of(context);

    final capacity = career.launderCapacity(content.businesses);
    final readiness =
        career.escapeReadiness(content.escapeParts, content.contacts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Tr.laundering, style: theme.textTheme.titleLarge),
        Text(capacity > 0 ? Tr.launderingNote : Tr.noLaunderCapacity,
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        StatRow(Tr.launderCapacity,
            capacity > 0 ? '${money(capacity)} / hafta' : '-'),
        const SizedBox(height: 24),

        Text(Tr.businesses, style: theme.textTheme.titleLarge),
        Text(Tr.businessesNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final b in content.businesses)
          _ShopCard(
            title: b.name,
            pitch: b.pitch,
            price: b.price,
            owned: career.businesses.contains(b.id),
            affordable: career.cleanMoney >= b.price,
            details: [
              (Tr.launderLabel, '${money(b.launderPerWeek)} / hafta'),
              (
                Tr.weeklyIncomeLabel,
                '${b.weeklyIncome >= 0 ? '+' : ''}${money(b.weeklyIncome)}'
              ),
              if (b.unlocks.isNotEmpty)
                (
                  Tr.unlocksLabel,
                  b.unlocks.map((id) => content.scheme(id).name).join(', ')
                ),
            ],
            onBuy: () =>
                ref.read(gameControllerProvider.notifier).buyBusiness(b.id),
          ),
        const SizedBox(height: 24),

        Text(Tr.contactsTitle, style: theme.textTheme.titleLarge),
        Text(Tr.contactsNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final c in content.contacts)
          _ShopCard(
            title: c.name,
            pitch: c.pitch,
            price: c.price,
            owned: career.contacts.contains(c.id),
            affordable: career.cleanMoney >= c.price,
            details: [
              if (c.suspicionRelief != 0)
                (Tr.shieldLabel, pct(c.suspicionRelief, digits: 0)),
              if (c.escapeBonus > 0)
                (Tr.escapeReadiness, '+${pct(c.escapeBonus, digits: 0)}'),
            ],
            onBuy: () =>
                ref.read(gameControllerProvider.notifier).hireContact(c.id),
          ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
                child:
                    Text(Tr.escapePlan, style: theme.textTheme.titleLarge)),
            Text('${Tr.escapeReadiness} ${pct(readiness)}',
                style: monoStyle(context,
                    color: readiness > 0.6 ? Colors.green : Colors.orange)),
          ],
        ),
        Text(Tr.escapePlanNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final p in content.escapeParts)
          _ShopCard(
            title: p.name,
            pitch: p.pitch,
            price: p.price,
            owned: career.escapeParts.contains(p.id),
            affordable: career.cleanMoney >= p.price,
            details: [(Tr.escapeReadiness, '+${pct(p.weight, digits: 0)}')],
            onBuy: () =>
                ref.read(gameControllerProvider.notifier).buyEscapePart(p.id),
          ),
        const SizedBox(height: 24),

        Text(Tr.partner, style: theme.textTheme.titleLarge),
        Text(Tr.partnerNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        _PartnerPicker(selected: career.partner),
      ],
    );
  }
}

/// Satın alınabilir tek bir kalem.
class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.title,
    required this.pitch,
    required this.price,
    required this.owned,
    required this.affordable,
    required this.details,
    required this.onBuy,
  });

  final String title;
  final String pitch;
  final double price;
  final bool owned;
  final bool affordable;
  final List<(String, String)> details;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text(title, style: theme.textTheme.titleSmall)),
                const SizedBox(width: 8),
                Text(money(price), style: monoStyle(context, scale: 0.9)),
              ],
            ),
            const SizedBox(height: 4),
            Text(pitch, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final (label, value) in details)
              StatRow(label, value, numeric: false),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: owned
                  ? OutlinedButton(
                      onPressed: null, child: const Text(Tr.owned))
                  : FilledButton(
                      onPressed: affordable ? onBuy : null,
                      child: Text(affordable ? Tr.buy : Tr.notEnoughMoney),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortak seçimi. Seçim bölüm başlarken uygulanır, bölüm bitince sıfırlanır.
class _PartnerPicker extends ConsumerWidget {
  const _PartnerPicker({required this.selected});

  final PartnerKind? selected;

  static const _labels = <PartnerKind, (String, String)>{
    PartnerKind.capital: (Tr.partnerCapital, Tr.partnerCapitalNote),
    PartnerKind.political: (Tr.partnerPolitical, Tr.partnerPoliticalNote),
    PartnerKind.celebrity: (Tr.partnerCelebrity, Tr.partnerCelebrityNote),
    PartnerKind.insider: (Tr.partnerInsider, Tr.partnerInsiderNote),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final theme = Theme.of(context);
    // RadioGroup: groupValue ve onChanged Flutter 3.32'den beri kullanım dışı.
    return RadioGroup<PartnerKind?>(
      groupValue: selected,
      onChanged: ctrl.setPartner,
      child: Column(
        children: [
          const RadioListTile<PartnerKind?>(
            value: null,
            contentPadding: EdgeInsets.zero,
            title: Text(Tr.partnerNone),
          ),
          for (final entry in _labels.entries)
            RadioListTile<PartnerKind?>(
              value: entry.key,
              contentPadding: EdgeInsets.zero,
              title: Text(entry.value.$1),
              subtitle:
                  Text(entry.value.$2, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
