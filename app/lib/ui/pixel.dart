import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Tycoon arayüz takımı: kabartmalı panel, maliyet rozetli düğme, kaynak
/// kutucuğu, dilimli çubuk.
///
/// Neden ayrı takım: her ekran aynı kenar kalınlığını, aynı gölgeyi ve aynı
/// altın rengi kullansın. Material'ın düz kartı ve ince çerçeveli düğmesi
/// gösterge paneli gibi duruyordu; tycoon hissi kalın kenar, iri düğme ve
/// sayının yanında ikon ister.
abstract final class Px {
  /// Kenar kalınlığı. Pixel dünyada her şey bunun katı.
  static const unit = 3.0;

  // Zemin ve panel katmanları, koyudan açığa.
  static const bg = Color(0xFF0B100E);
  static const panel = Color(0xFF16201B);
  static const panelRaised = Color(0xFF1C2822);
  static const inset = Color(0xFF0F1613);

  // Kabartma: sol-üst ışık, sağ-alt gölge.
  static const light = Color(0xFF2E4036);
  static const shadow = Color(0xFF050807);

  static const gold = Color(0xFFFFD65C);
  static const goldDeep = Color(0xFFB8860B);
  static const goldDark = Color(0xFF96600C);
  static const ink = Color(0xFF1A1200);

  static const green = Color(0xFF2ECC71);
  static const red = Color(0xFFE5484D);
  static const amber = Color(0xFFF5A524);
  static const blue = Color(0xFF5B9BD5);

  static const text = Color(0xFFECEBE4);
  static const muted = Color(0xFF9AA69E);

  static const goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold, goldDeep],
  );
}

/// Kabartmalı kenar. `raised` doğruyken panel öne çıkar (ışık üstte),
/// yanlışken içe göçer (gölge üstte): çubuk yuvaları ve grafik zeminleri.
BoxDecoration pixelBevel({
  Color fill = Px.panel,
  bool raised = true,
  double width = Px.unit,
}) {
  final top = raised ? Px.light : Px.shadow;
  final bottom = raised ? Px.shadow : Px.light;
  return BoxDecoration(
    color: fill,
    border: Border(
      top: BorderSide(color: top, width: width),
      left: BorderSide(color: top, width: width),
      bottom: BorderSide(color: bottom, width: width),
      right: BorderSide(color: bottom, width: width),
    ),
  );
}

/// Panel. İsteğe bağlı başlık şeridi ve sağ üstte küçük bir rozet.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.title,
    this.badge,
    this.badgeColor,
    this.padding = const EdgeInsets.all(12),
    this.fill = Px.panel,
    this.raised = true,
    this.margin,
  });

  final Widget child;
  final String? title;
  final String? badge;
  final Color? badgeColor;
  final EdgeInsets padding;
  final Color fill;
  final bool raised;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: pixelBevel(fill: fill, raised: raised),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 5),
              decoration: const BoxDecoration(
                color: Px.inset,
                border: Border(
                  bottom: BorderSide(color: Px.shadow, width: Px.unit),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: AppSizes.displayBase,
                        height: 1,
                        color: Px.gold,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) PixelTag(badge!, color: badgeColor),
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Küçük etiket: "OLAY", "AÇIK", "KİLİTLİ".
class PixelTag extends StatelessWidget {
  const PixelTag(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Px.muted;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 6, 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        border: Border.all(color: c, width: 2),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: AppSizes.displayBase * 0.8,
          height: 1,
          color: c,
        ),
      ),
    );
  }
}

enum PixelButtonKind { primary, secondary, danger, ghost }

/// Tycoon düğmesi: iri, kabartmalı, basılınca çöker. Sağda isteğe bağlı
/// maliyet rozeti ("-50K TL") ve solda ikon.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = PixelButtonKind.secondary,
    this.icon,
    this.cost,
    this.costColor,
    this.dense = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PixelButtonKind kind;
  final IconData? icon;
  final String? cost;
  final Color? costColor;
  final bool dense;
  final bool expand;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (Color fill, Color fg, Gradient? grad) = switch (widget.kind) {
      PixelButtonKind.primary => (Px.goldDeep, Px.ink, Px.goldGradient),
      PixelButtonKind.secondary => (Px.panelRaised, Px.text, null),
      PixelButtonKind.danger => (Px.red, Colors.white, null),
      PixelButtonKind.ghost => (Colors.transparent, Px.muted, null),
    };
    final pressed = _down && enabled;
    final height = widget.dense ? 38.0 : 46.0;
    // Basılı düğme 3 piksel aşağı iner ve alt gölgesini kaybeder.
    final drop = pressed ? 0.0 : Px.unit;

    final body = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: widget.dense ? 10 : 14),
      decoration: BoxDecoration(
        color: enabled ? fill : Px.inset,
        gradient: enabled ? grad : null,
        border: Border(
          top: BorderSide(
            color: enabled
                ? (widget.kind == PixelButtonKind.primary
                    ? const Color(0xFFFFF0B8)
                    : Px.light)
                : Px.shadow,
            width: Px.unit,
          ),
          left: BorderSide(
            color: enabled
                ? (widget.kind == PixelButtonKind.primary
                    ? const Color(0xFFFFF0B8)
                    : Px.light)
                : Px.shadow,
            width: Px.unit,
          ),
          right: const BorderSide(color: Px.shadow, width: Px.unit),
          bottom: BorderSide(color: Px.shadow, width: Px.unit + drop),
        ),
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20, color: enabled ? fg : Px.muted),
            const SizedBox(width: 8),
          ],
          Flexible(
            fit: widget.expand ? FlexFit.tight : FlexFit.loose,
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: widget.cost == null && widget.expand
                  ? TextAlign.center
                  : TextAlign.start,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: AppSizes.displayBase *
                    (widget.kind == PixelButtonKind.primary ? 1.15 : 1),
                height: 1,
                color: enabled ? fg : Px.muted,
              ),
            ),
          ),
          if (widget.cost != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(7, 4, 7, 3),
              color: Colors.black.withValues(alpha: 0.35),
              child: Text(
                widget.cost!,
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: AppSizes.monoBase * 0.85,
                  height: 1,
                  color: enabled ? (widget.costColor ?? Px.gold) : Px.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      // Basılı hâlde düğme aşağı kayar ama toplam yüksekliği değişmez.
      padding: EdgeInsets.only(top: pressed ? Px.unit : 0),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: body,
      ),
    );
  }
}

/// Kaynak kutucuğu: ikon kutusu, küçük etiket, iri sayı.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.sub,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Px.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
      decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.withValues(alpha: 0.8)),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      height: 1.1,
                      color: Px.muted,
                    ),
                  ),
                ),
                // Sayı sığmazsa kısaltılmaz, küçülür: "245 bi…" hiçbir şey
                // söylemiyor.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: AppSizes.monoBase * 1.05,
                      height: 1.05,
                      color: c,
                    ),
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      height: 1.1,
                      color: Px.muted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dilimli kaynak çubuğu. Sürekli çubuk yerine 12 dilim: pixel dünyaya
/// oturur ve yüzdeyi göz kararı okutur.
class PixelBar extends StatelessWidget {
  const PixelBar({
    super.key,
    required this.value,
    required this.color,
    this.label,
    this.text,
    this.segments = 12,
    this.height = 14,
  });

  final double value;
  final Color color;
  final String? label;
  final String? text;
  final int segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * segments).round();
    final bar = Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: pixelBevel(fill: Px.inset, raised: false, width: 2),
      child: Row(
        children: [
          for (var i = 0; i < segments; i++) ...[
            Expanded(
              child: Container(
                color: i < filled ? color : color.withValues(alpha: 0.10),
              ),
            ),
            if (i < segments - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
    if (label == null && text == null) return bar;
    return Row(
      children: [
        if (label != null)
          Expanded(
            flex: 30,
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        Expanded(flex: 55, child: bar),
        if (text != null) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 15,
            child: Text(
              text!,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(context, scale: 0.9, color: color),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bölüm başlığı: solda altın blok, büyük harf başlık, sağda isteğe bağlı
/// sayı veya not.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Container(width: 6, height: 18, color: Px.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: AppSizes.displayBase * 1.2,
                height: 1,
                color: Px.text,
                letterSpacing: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: monoStyle(context, scale: 0.9, color: Px.muted)),
        ],
      ),
    );
  }
}

/// Bir etkinin yönünü gösteren küçük parça: "Şüphe ▲5", "Panik ▼".
class EffectChip extends StatelessWidget {
  const EffectChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: AppSizes.monoBase * 0.8,
            height: 1,
            color: color,
          ),
        ),
      ],
    );
  }
}
