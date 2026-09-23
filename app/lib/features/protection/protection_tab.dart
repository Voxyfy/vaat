import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';
import '../../ui/pixel.dart';

/// Koruma: şüphe ve panik göstergesi, çıkış hamleleri (Sat, Devret) ve KAÇ.
///
/// Kompakt kurulu: HUD ve alt blok ekranın yarısını alıyor, KAÇ düğmesi ilk
/// bakışta görünmek zorunda. Uzun açıklamalar onay penceresine bırakıldı.
class ProtectionTab extends ConsumerWidget {
  const ProtectionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final s = game.scheme;
    final content = ref.read(contentProvider);
    final type = content.scheme(game.schemeTypeId);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final readiness = game.career.escapeReadiness(
      content.escapeParts,
      content.contacts,
    );

    final suspicionColor = s.suspicion < 40
        ? Px.blue
        : s.suspicion < 70
        ? Px.amber
        : Px.red;
    // Panik 1,0'da sakin; 2,0 ve üstü çöküş eşiği. Çubuk bu aralığı gösterir.
    final panicValue = ((s.panic - 1.0) / 1.0).clamp(0.0, 1.0);
    final panicColor = s.panic < 1.3
        ? Px.green
        : s.panic < 1.8
        ? Px.amber
        : Px.red;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // İki gösterge aynı iskelette kurulu, yükseklikleri kendiliğinden
        // eşit. IntrinsicHeight ile eşitlemek FittedBox'ın doğal yüksekliğini
        // sayıyor ve çubuğun altında boşluk bırakıyordu.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Gauge(
                title: Tr.suspicionDetail,
                value: '${s.suspicion.toStringAsFixed(0)} / 100',
                bar: s.suspicion / 100,
                color: suspicionColor,
                icon: Icons.visibility_outlined,
                tag: s.suspicion < 40
                    ? Tr.suspicionLow
                    : (s.suspicion < 70 ? Tr.suspicionMid : Tr.suspicionHigh),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Gauge(
                title: Tr.panic,
                value: '×${s.panic.toStringAsFixed(2)}',
                bar: panicValue,
                color: panicColor,
                icon: Icons.local_fire_department_outlined,
                tag: s.bankRun
                    ? Tr.bankRun
                    : (s.panic < 1.3 ? Tr.panicCalm : Tr.panicHigh),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PixelPanel(
          title: Tr.exitOptions,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExitAction(
                label: Tr.sell,
                icon: Icons.sell_outlined,
                enabled: canSell(s, type),
                cost: canSell(s, type) ? money(saleValue(s, type)) : null,
                costColor: Px.green,
                hint: canSell(s, type) ? Tr.sellHint : Tr.sellLocked,
                confirmTitle: Tr.sellConfirmTitle,
                confirmBody:
                    '${Tr.sellHint}\n${Tr.sellValue}: ${money(saleValue(s, type))}',
                confirmAction: Tr.confirmSell,
                onConfirmed: ctrl.sell,
              ),
              const SizedBox(height: 8),
              _ExitAction(
                label: Tr.handOver,
                icon: Icons.handshake_outlined,
                enabled: canHandOver(s),
                hint: canHandOver(s) ? Tr.handOverHint : Tr.handOverLocked,
                confirmTitle: Tr.handOverConfirmTitle,
                confirmBody: Tr.handOverHint,
                confirmAction: Tr.confirmHandOver,
                onConfirmed: ctrl.handOver,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _FleeButton(
          enabled: !s.isOver,
          onHold: () => _confirmFlee(context, ref),
        ),
        const SizedBox(height: 6),
        Text(
          Tr.fleeHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        // Kaçış hazırlığı kariyer katmanında alınır; burada yalnız gösterilir
        // ki oyuncu KAÇ'a basmadan önce neyle kaçacağını bilsin.
        PixelPanel(
          title: Tr.escapePlanShort,
          badge: pct(readiness),
          badgeColor: readiness >= 0.6
              ? Px.green
              : readiness > 0
              ? Px.amber
              : Px.red,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PixelBar(
                value: readiness,
                color: readiness >= 0.6
                    ? Px.green
                    : readiness > 0
                    ? Px.amber
                    : Px.red,
              ),
              if (readiness == 0) ...[
                const SizedBox(height: 6),
                Text(
                  Tr.noEscapePlan,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmFlee(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Tr.fleeConfirmTitle),
        content: const Text(Tr.fleeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(Tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(Tr.confirmFlee),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(gameControllerProvider.notifier).flee();
  }
}

/// Şüphe ve panik göstergesi: başlık, iri sayı ve yanında durum etiketi,
/// altta dilimli çubuk. İki kart aynı iskeleti kullanır ki yan yana simetrik
/// dursunlar; etiket bu yüzden ayrı satır değil, sayının yanında.
class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.title,
    required this.value,
    required this.bar,
    required this.color,
    required this.icon,
    required this.tag,
  });

  final String title;
  final String value;
  final double bar;
  final Color color;
  final IconData icon;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      title: title,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sayı satırı sabit yükseklikte: FittedBox küçültse de kutu
          // büyümesin, iki kart aynı boyda kalsın.
          SizedBox(
            height: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: monoStyle(context, scale: 1.5, color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Etiket sayının hemen yanında; dar kartta sığmazsa küçülür.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: PixelTag(tag, color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          PixelBar(value: bar, color: color, segments: 10),
        ],
      ),
    );
  }
}

/// Sat ve Devret: düğme, kilitliyse altında neden.
class _ExitAction extends StatelessWidget {
  const _ExitAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.hint,
    required this.confirmTitle,
    required this.confirmBody,
    required this.confirmAction,
    required this.onConfirmed,
    this.cost,
    this.costColor,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final String hint;
  final String confirmTitle;
  final String confirmBody;
  final String confirmAction;
  final VoidCallback onConfirmed;
  final String? cost;
  final Color? costColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelButton(
          label: label,
          icon: icon,
          cost: cost,
          costColor: costColor,
          onPressed: enabled ? () => _confirm(context) : null,
        ),
        const SizedBox(height: 3),
        Text(
          hint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Px.muted),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(Tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmAction),
          ),
        ],
      ),
    );
    if (ok == true) onConfirmed();
  }
}

/// KAÇ. Ekranın en görünür kırmızı öğesi; yalnız basılı tutmayla çalışır.
/// Tek dokunuşla kaçış olmaz, ama oyuncu her turda bu düğmeye bakar.
class _FleeButton extends StatefulWidget {
  const _FleeButton({required this.enabled, required this.onHold});

  final bool enabled;
  final VoidCallback onHold;

  @override
  State<_FleeButton> createState() => _FleeButtonState();
}

class _FleeButtonState extends State<_FleeButton> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final pressed = _down && enabled;
    const light = Color(0xFFFF8A8E);
    const deep = Color(0xFF7A1418);
    return Padding(
      padding: EdgeInsets.only(top: pressed ? Px.unit : 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onLongPressEnd: enabled ? (_) => setState(() => _down = false) : null,
        // Basılı tutma: yanlışlıkla kaçış olmasın.
        onLongPress: enabled ? widget.onHold : null,
        child: Container(
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? Px.red : Px.inset,
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF25C61), Color(0xFFB8232A)],
                  )
                : null,
            border: Border(
              top: BorderSide(
                color: enabled ? light : Px.shadow,
                width: Px.unit,
              ),
              left: BorderSide(
                color: enabled ? light : Px.shadow,
                width: Px.unit,
              ),
              right: BorderSide(
                color: enabled ? deep : Px.shadow,
                width: Px.unit,
              ),
              bottom: BorderSide(
                color: enabled ? deep : Px.shadow,
                width: Px.unit + (pressed ? 0 : Px.unit),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_run_rounded,
                size: 28,
                color: enabled ? Colors.white : Px.muted,
              ),
              const SizedBox(width: 10),
              Text(
                Tr.flee,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: AppSizes.displayBase * 2,
                  height: 1,
                  letterSpacing: 4,
                  color: enabled ? Colors.white : Px.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
