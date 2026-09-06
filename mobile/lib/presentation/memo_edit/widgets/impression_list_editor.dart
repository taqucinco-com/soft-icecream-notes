import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/memo/application/providers/memo_edit.dart';

/// Figma 03フレームの「感想（箇条書き）」欄。追加・削除ができる。
class ImpressionListEditor extends ConsumerStatefulWidget {
  const ImpressionListEditor({super.key});

  @override
  ConsumerState<ImpressionListEditor> createState() =>
      _ImpressionListEditorState();
}

class _ImpressionListEditorState extends ConsumerState<ImpressionListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final impressions = ref.watch(
      memoEditProvider.select((state) => state.impressions),
    );
    final notifier = ref.read(memoEditProvider.notifier);

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
                controller: _controller,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '感想を追加',
                ),
                onSubmitted: _submit,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _submit(_controller.text),
            ),
          ],
        ),
      ],
    );
  }

  void _submit(String text) {
    ref.read(memoEditProvider.notifier).addImpression(text);
    _controller.clear();
  }
}
