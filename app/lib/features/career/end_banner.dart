import 'package:flutter/material.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';

/// Bölüm sonu manşeti. Gazete logosu, sonuç kelimesi, tek satır alt başlık.
class EndBanner extends StatelessWidget {
  const EndBanner({super.key, required this.end});

  final SchemeEnd end;

  static (String, String) textsFor(SchemeEnd end) => switch (end) {
        SchemeEnd.bankRun => (Tr.endBankRun, Tr.endSubBankRun),
        SchemeEnd.raid => (Tr.endRaid, Tr.endSubRaid),
        SchemeEnd.fled => (Tr.endFled, Tr.endSubFled),
        SchemeEnd.sold => (Tr.endSold, Tr.endSubSold),
        SchemeEnd.handedOver => (Tr.endHandedOver, Tr.endSubHandedOver),
      };

  @override
  Widget build(BuildContext context) {
    final (title, sub) = textsFor(end);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gazete logosu parodisi: blackletter pixel. Yalnız burada.
        Text(Tr.newspaperName,
            style: const TextStyle(
                fontFamily: AppFonts.masthead, fontSize: 34, height: 1)),
        const Divider(),
        Text(title, style: theme.textTheme.displayMedium),
        const SizedBox(height: 4),
        Text(sub, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Etiket solda, değer sağda.
///
/// Sayılar tek aralıklı fontla hizalı durur; `numeric: false` verilen metin
/// değerleri gövde fontuyla yazılır ve sarar. İki taraf da esnek, çünkü dar
/// telefonda "Katılım esaslı ortaklık" gibi uzun bir değer satırı taşırıyor.
class StatRow extends StatelessWidget {
  const StatRow(
    this.label,
    this.value, {
    super.key,
    this.color,
    this.numeric = true,
  });

  final String label;
  final String value;
  final Color? color;
  final bool numeric;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: Text(label)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: numeric
                    ? monoStyle(context, color: color)
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      );
}
