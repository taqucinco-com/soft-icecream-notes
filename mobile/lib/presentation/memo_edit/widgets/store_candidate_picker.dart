import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/memo_edit.dart';

/// Figma 03フレームの「お店」欄。フォーム内インラインの候補チップとして表示し、
/// 「手動で入力」を選ぶと自由入力欄に切り替わる（独立したダイアログ/シートにはしない）。
class StoreCandidatePicker extends ConsumerWidget {
  const StoreCandidatePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoEditProvider);
    final notifier = ref.read(memoEditProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('お店（位置情報から候補を提示）', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        if (state.isManualStoreEntry)
          TextField(
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: '店名を入力',
            ),
            controller: TextEditingController(text: state.storeName)
              ..selection = TextSelection.collapsed(
                offset: state.storeName?.length ?? 0,
              ),
            onChanged: notifier.setStoreName,
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(state.storeName ?? '未選択'),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in state.storeCandidates.asMap().entries)
              ActionChip(
                label: Text('候補${entry.key + 1}: ${entry.value.name}'),
                onPressed: () => notifier.selectStoreCandidate(entry.value),
              ),
            ActionChip(
              label: const Text('手動で入力'),
              onPressed: notifier.enterStoreManually,
            ),
          ],
        ),
      ],
    );
  }
}
