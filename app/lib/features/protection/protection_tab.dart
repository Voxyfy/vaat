import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vaat_sim/vaat_sim.dart';

import '../../core/content.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../game/game_controller.dart';

/// Koruma: şüphe ve panik ayrıntısı, KAÇ butonu. Tanıdıklar destesi ve
/// kaçış planı parçaları kariyer katmanıyla gelecek.
class ProtectionTab extends ConsumerWidget {
  const ProtectionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final s = game.scheme;
    final type = ref.read(contentProvider).scheme(game.schemeTypeId);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(Tr.suspicionDetail, style: theme.textTheme.titleMedium),
        Text('${s.suspicion.toStringAsFixed(1)} / 100',
            style: monoStyle(context, scale: 2.4)),
        const SizedBox(height: 16),
        Text(Tr.panic, style: theme.textTheme.titleMedium),
        Text('×${s.panic.toStringAsFixed(2)}', style: monoStyle(context, scale: 2)),
        if (s.bankRun)
          Text(Tr.bankRun,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: Colors.redAccent)),
        const SizedBox(height: 32),
        Text(Tr.exitOptions, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _ExitTile(
          label: Tr.sell,
          hint: canSell(s, type)
              ? '${Tr.sellHint}\n${Tr.sellValue}: ${money(saleValue(s, type))}'
              : Tr.sellLocked,
          enabled: canSell(s, type),
          confirmTitle: Tr.sellConfirmTitle,
          confirmAction: Tr.confirmSell,
          onConfirmed: ref.read(gameControllerProvider.notifier).sell,
        ),
        _ExitTile(
          label: Tr.handOver,
          hint: canHandOver(s) ? Tr.handOverHint : Tr.handOverLocked,
          enabled: canHandOver(s),
          confirmTitle: Tr.handOverConfirmTitle,
          confirmAction: Tr.confirmHandOver,
          onConfirmed: ref.read(gameControllerProvider.notifier).handOver,
        ),
        const SizedBox(height: 32),
        Center(
          child: GestureDetector(
            // Basılı tutma: yanlışlıkla kaçış olmasın ama oyuncu her turda
            // bu butona baksın.
            onLongPress: s.isOver ? null : () => _confirmFlee(context, ref),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.isOver ? Colors.grey : Colors.red.shade700,
              ),
              alignment: Alignment.center,
              child: Text(Tr.flee,
                  style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(Tr.fleeHint,
            textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
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
              child: const Text(Tr.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(Tr.confirmFlee)),
        ],
      ),
    );
    if (ok == true) ref.read(gameControllerProvider.notifier).flee();
  }
}

/// Sat ve Devret için ortak satır: koşul tutmuyorsa neden tutmadığını yazar.
class _ExitTile extends StatelessWidget {
  const _ExitTile({
    required this.label,
    required this.hint,
    required this.enabled,
    required this.confirmTitle,
    required this.confirmAction,
    required this.onConfirmed,
  });

  final String label;
  final String hint;
  final bool enabled;
  final String confirmTitle;
  final String confirmAction;
  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: enabled ? () => _confirm(context) : null,
            child: Text(label),
          ),
          const SizedBox(height: 4),
          Text(hint, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(hint),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(Tr.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmAction)),
        ],
      ),
    );
    if (ok == true) onConfirmed();
  }
}
