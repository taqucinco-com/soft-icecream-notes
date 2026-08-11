import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/serving_machine_filter.dart';
import '../../../domain/entities/serving_machine.dart';

/// Figma 01/02フレームの「すべて / カルピジャーニ / 日世 / その他」フィルタ。
class ServingMachineFilterBar extends ConsumerWidget {
  const ServingMachineFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(servingMachineFilterProvider);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _FilterChip(
            label: 'すべて',
            selected: selected == null,
            onTap: () =>
                ref.read(servingMachineFilterProvider.notifier).set(null),
          ),
          for (final machine in ServingMachine.presetValues) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: machine,
              selected: selected == machine,
              onTap: () => ref
                  .read(servingMachineFilterProvider.notifier)
                  .set(machine),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
