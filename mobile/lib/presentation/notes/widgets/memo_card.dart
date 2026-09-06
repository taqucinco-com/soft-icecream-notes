import 'package:flutter/material.dart';

import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/presentation/format/date_format.dart';

class MemoCard extends StatelessWidget {
  const MemoCard({super.key, required this.memo, required this.onTap});

  final Memo memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 64,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.icecream_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo.storeName ?? '店名未設定',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    memo.eatenDate != null
                        ? formatYmd(memo.eatenDate!)
                        : '日付未設定',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (memo.servingMachine != null) ...[
                    const SizedBox(height: 6),
                    _ServingMachineTag(label: memo.servingMachine!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServingMachineTag extends StatelessWidget {
  const _ServingMachineTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
