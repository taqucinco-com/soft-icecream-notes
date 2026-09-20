import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:icecream_log/features/memo/application/providers/memo_edit.dart';

/// Figma 03フレームの「感想（箇条書き）」欄。追加・削除ができる。
class ImpressionListEditor extends HookConsumerWidget {
  const ImpressionListEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impressions = ref.watch(
      memoEditProvider.select((state) => state.impressions),
    );
    final notifier = ref.read(memoEditProvider.notifier);
    final controller = useTextEditingController();

    void submit(String text) {
      notifier.addImpression(text);
      controller.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('感想（箇条書き）', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        for (final entry in impressions.asMap().entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.value)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  onPressed: () => notifier.removeImpressionAt(entry.key),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '感想を追加',
                ),
                onSubmitted: submit,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => submit(controller.text),
            ),
          ],
        ),
      ],
    );
  }
}
