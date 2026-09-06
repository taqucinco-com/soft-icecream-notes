import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:icecream_log/features/memo/application/providers/memo_edit.dart';

/// Figma 03フレームの「お店」欄。フォーム内インラインの候補チップとして表示し、
/// 「手動で入力」を選ぶと自由入力欄に切り替わる（独立したダイアログ/シートにはしない）。
class StoreCandidatePicker extends ConsumerStatefulWidget {
  const StoreCandidatePicker({super.key});

  @override
  ConsumerState<StoreCandidatePicker> createState() =>
      _StoreCandidatePickerState();
}

class _StoreCandidatePickerState extends ConsumerState<StoreCandidatePicker> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(memoEditProvider).storeName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoEditProvider);
    final notifier = ref.read(memoEditProvider.notifier);

    // ユーザーの入力によるものではなく、外部要因（手動入力への切り替え等）で
    // storeNameが変わった場合のみコントローラを同期する。
    final storeName = state.storeName ?? '';
    if (state.isManualStoreEntry && _controller.text != storeName) {
      _controller.value = TextEditingValue(
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
            controller: _controller,
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
