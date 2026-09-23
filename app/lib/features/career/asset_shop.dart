import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';
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
    final ctrl = ref.read(gameControllerProvider.notifier);
    final career = game.career;
    final theme = Theme.of(context);

    final capacity = career.launderCapacity(content.businesses);
    final readiness =
        career.escapeReadiness(content.escapeParts, content.contacts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelPanel(
          title: Tr.laundering,
          badge: capacity > 0 ? '${money(capacity)}${Tr.perWeekSuffix}' : '-',
          badgeColor: capacity > 0 ? Px.green : Px.muted,
          child: Text(
            capacity > 0 ? Tr.launderingNote : Tr.noLaunderCapacity,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 18),

        CareerHeading(Tr.businesses, note: Tr.businessesNote),
        for (final b in content.businesses)
          _ShopRow(
            title: b.name,
            pitch: b.pitch,
            price: b.price,
            owned: career.businesses.contains(b.id),
            affordable: career.cleanMoney >= b.price,
            chips: [
              if (b.launderPerWeek > 0)
                _Chip(Icons.local_laundry_service_outlined,
                    '${Tr.launderLabel} ${money(b.launderPerWeek)}${Tr.perWeekSuffix}',
                    Px.green),
              _Chip(
                b.weeklyIncome >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                '${Tr.weeklyIncomeLabel} ${b.weeklyIncome >= 0 ? '+' : ''}${money(b.weeklyIncome)}',
                b.weeklyIncome >= 0 ? Px.green : Px.red,
              ),
              if (b.suspicionRelief > 0)
                _Chip(Icons.shield_outlined, Tr.shieldLabel, Px.blue),
              if (b.unlocks.isNotEmpty)
                _Chip(
                  Icons.lock_open_outlined,
                  '${Tr.unlocksLabel}: ${b.unlocks.map((id) => content.scheme(id).name).join(', ')}',
                  Px.gold,
                ),
            ],
            onBuy: () => ctrl.buyBusiness(b.id),
          ),
        const SizedBox(height: 18),

        CareerHeading(Tr.contactsTitle, note: Tr.contactsNote),
        for (final c in content.contacts)
          _ShopRow(
            title: c.name,
            pitch: c.pitch,
            price: c.price,
            owned: career.contacts.contains(c.id),
            affordable: career.cleanMoney >= c.price,
            chips: [
              if (c.suspicionRelief != 0)
                _Chip(Icons.shield_outlined,
                    '${Tr.shieldLabel} ${pct(c.suspicionRelief, digits: 0)}',
                    Px.blue),
              if (c.escapeBonus > 0)
                _Chip(Icons.flight_takeoff_rounded,
                    '${Tr.escapeReadiness} +${pct(c.escapeBonus, digits: 0)}',
                    Px.amber),
            ],
            onBuy: () => ctrl.hireContact(c.id),
          ),
        const SizedBox(height: 18),

        CareerHeading(
          Tr.escapePlan,
          note: Tr.escapePlanNote,
          trailing: PixelTag(
            '${Tr.escapeReadiness} ${pct(readiness)}',
            color: readiness > 0.6 ? Px.green : Px.amber,
          ),
        ),
        PixelBar(
          value: readiness,
          color: readiness > 0.6 ? Px.green : Px.amber,
          segments: 20,
          height: 16,
        ),
        const SizedBox(height: 10),
        for (final p in content.escapeParts)
          _ShopRow(
            title: p.name,
            pitch: p.pitch,
            price: p.price,
            owned: career.escapeParts.contains(p.id),
            affordable: career.cleanMoney >= p.price,
            chips: [
              _Chip(Icons.flight_takeoff_rounded,
                  '${Tr.escapeReadiness} +${pct(p.weight, digits: 0)}',
                  Px.amber),
            ],
            onBuy: () => ctrl.buyEscapePart(p.id),
          ),
        const SizedBox(height: 18),

        CareerHeading(Tr.partner, note: Tr.partnerNote),
        _PartnerPicker(selected: career.partner),
      ],
    );
  }
}

/// Bir etkinin kısa özeti: ikon ve mono metin.
///
/// EffectChip yerine kendi satırı: "Açar: Klasik Ponzi, Kripto Borsası" gibi
/// uzun metinler dar telefonda sığmıyor, burada kırpılıyor.
class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: AppSizes.monoBase * 0.8,
                height: 1,
                color: color,
              ),
            ),
          ),
        ],
      );
}

/// Satın alınabilir tek bir kalem: ad, açıklama, etki etiketleri ve sağ
/// altta fiyat rozetli "Al" düğmesi ya da "VAR" etiketi.
class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.title,
    required this.pitch,
    required this.price,
    required this.owned,
    required this.affordable,
    required this.chips,
    required this.onBuy,
  });

  final String title;
  final String pitch;
  final double price;
  final bool owned;
  final bool affordable;
  final List<Widget> chips;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PixelPanel(
      margin: const EdgeInsets.only(bottom: 10),
      fill: owned ? Px.panel : Px.panelRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: AppSizes.displayBase * 1.1,
                    height: 1,
                    color: owned ? Px.muted : Px.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Fiyat başlıkta da duruyor: kapalı düğmenin rozeti griye
              // düşüyor, oysa "yetmiyor" hâli kırmızı görünmeli.
              if (owned)
                PixelTag(Tr.owned, color: Px.green)
              else
                PixelTag(money(price), color: affordable ? Px.gold : Px.red),
            ],
          ),
          const SizedBox(height: 6),
          Text(pitch, style: theme.textTheme.bodySmall),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 4, children: chips),
          ],
          if (!owned) ...[
            const SizedBox(height: 10),
            PixelButton(
              label: affordable ? Tr.buy : Tr.notEnoughMoney,
              kind: affordable
                  ? PixelButtonKind.secondary
                  : PixelButtonKind.ghost,
              icon: Icons.shopping_cart_outlined,
              cost: money(price),
              // Para yetmiyorsa fiyat kırmızı; düğme yine kapalı.
              costColor: affordable ? Px.gold : Px.red,
              onPressed: affordable ? onBuy : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ortak seçimi. Seçili olan altın düğme, diğerleri gri; radyo yok.
/// Seçim bölüm başlarken uygulanır, bölüm bitince sıfırlanır.
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
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelButton(
            label: Tr.partnerNone,
            kind: selected == null
                ? PixelButtonKind.primary
                : PixelButtonKind.secondary,
            icon: selected == null ? Icons.check_rounded : Icons.person_off_outlined,
            onPressed: () => ctrl.setPartner(null),
          ),
          for (final entry in _labels.entries) ...[
            const SizedBox(height: 8),
            PixelButton(
              label: entry.value.$1,
              kind: selected == entry.key
                  ? PixelButtonKind.primary
                  : PixelButtonKind.secondary,
              icon: selected == entry.key
                  ? Icons.check_rounded
                  : Icons.person_outline,
              onPressed: () => ctrl.setPartner(entry.key),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
              child: Text(entry.value.$2, style: theme.textTheme.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}
