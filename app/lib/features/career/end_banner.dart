import 'package:flutter/material.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../ui/pixel.dart';

/// Gazete kâğıdı: uygulamadaki tek açık zemin. Manşet gazete olduğu için
/// koyu paneller arasında kâğıt gibi durur.
abstract final class Paper {
  static const fill = Color(0xFFE9E2CC);
  static const shade = Color(0xFFC9BFA0);
  static const light = Color(0xFFF7F2E3);
  static const ink = Px.ink;
  static const mutedInk = Color(0xFF5A5040);
}

/// Bölüm sonu manşeti. Gazete logosu, sonuç kelimesi, tek satır alt başlık;
/// hepsi krem kâğıt üstünde, kabartmalı çerçevede.
class EndBanner extends StatelessWidget {
  const EndBanner({super.key, required this.end})
      : customTitle = null,
        customSub = null;

  /// Şema sonu olmayan manşet: kariyeri kendi bitiren oyuncunun sonu.
  const EndBanner.custom({super.key, required String title, required String sub})
      : end = null,
        customTitle = title,
        customSub = sub;

  final SchemeEnd? end;
  final String? customTitle;
  final String? customSub;

  static (String, String) textsFor(SchemeEnd end) => switch (end) {
        SchemeEnd.bankRun => (Tr.endBankRun, Tr.endSubBankRun),
        SchemeEnd.raid => (Tr.endRaid, Tr.endSubRaid),
        SchemeEnd.fled => (Tr.endFled, Tr.endSubFled),
        SchemeEnd.sold => (Tr.endSold, Tr.endSubSold),
        SchemeEnd.handedOver => (Tr.endHandedOver, Tr.endSubHandedOver),
      };

  /// Şema sonunun rengi. Defter satırlarında ve rozetlerde aynı eşleme.
  static Color colorFor(SchemeEnd end) => switch (end) {
        SchemeEnd.fled => Px.amber,
        SchemeEnd.sold => Px.green,
        SchemeEnd.handedOver => Px.blue,
        SchemeEnd.bankRun || SchemeEnd.raid => Px.red,
      };

  @override
  Widget build(BuildContext context) {
    final (title, sub) =
        end != null ? textsFor(end!) : (customTitle!, customSub!);
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Paper.fill,
        border: Border(
          top: BorderSide(color: Paper.light, width: Px.unit),
          left: BorderSide(color: Paper.light, width: Px.unit),
          bottom: BorderSide(color: Paper.shade, width: Px.unit),
          right: BorderSide(color: Paper.shade, width: Px.unit),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gazete logosu parodisi: blackletter pixel. Yalnız burada.
          Text(Tr.newspaperName,
              style: const TextStyle(
                  fontFamily: AppFonts.masthead,
                  fontSize: 34,
                  height: 1,
                  color: Paper.ink)),
          const SizedBox(height: 6),
          Container(height: 2, color: Paper.ink),
          const SizedBox(height: 2),
          Container(height: Px.unit, color: Paper.ink),
          const SizedBox(height: 10),
          Text(title,
              style: theme.textTheme.displayMedium?.copyWith(color: Paper.ink)),
          const SizedBox(height: 4),
          Text(sub,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Paper.mutedInk)),
        ],
      ),
    );
  }
}

/// Kariyer ekranlarının bölüm başlığı. SectionHeader metni büyük harfe
/// çeviriyor; burada metin olduğu gibi kalır, çünkü testler ve öğretici
/// bu başlıklara birebir atıf yapıyor.
class CareerHeading extends StatelessWidget {
  const CareerHeading(this.title, {super.key, this.trailing, this.note});

  final String title;
  final Widget? trailing;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 6, height: 20, color: Px.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: AppSizes.displayBase * 1.3,
                    height: 1,
                    color: Px.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
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
