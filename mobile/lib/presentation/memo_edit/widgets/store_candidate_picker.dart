import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:icecream_log/features/memo/application/providers/memo_edit.dart';

/// Figma 03フレームの「お店」欄。フォーム内インラインの候補チップとして表示し、
/// 「手動で入力」を選ぶと自由入力欄に切り替わる（独立したダイアログ/シートにはしない）。
class StoreCandidatePicker extends HookConsumerWidget {
  const StoreCandidatePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoEditProvider);
    final notifier = ref.read(memoEditProvider.notifier);
    final controller = useTextEditingController(
      text: ref.read(memoEditProvider).storeName,
    );

    // ユーザーの入力によるものではなく、外部要因（手動入力への切り替え等）で
    // storeNameが変わった場合のみコントローラを同期する。
    final storeName = state.storeName ?? '';
    if (state.isManualStoreEntry && controller.text != storeName) {
      controller.value = TextEditingValue(
        text: storeName,
        selection: TextSelection.collapsed(offset: storeName.length),
      );
    }

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
            controller: controller,
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
                onPressed: () =>
                    notifier.selectNearbyStoreCandidate(entry.value),
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
