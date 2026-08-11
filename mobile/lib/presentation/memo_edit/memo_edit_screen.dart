import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/memo_edit.dart';
import '../../domain/entities/serving_machine.dart';
import '../format/date_format.dart';
import 'widgets/impression_list_editor.dart';
import 'widgets/store_candidate_picker.dart';
import 'widgets/taste_rating_input.dart';

/// Figma 03フレーム（メモ作成編集）。フルスクリーンモーダルとして開く。
class MemoEditScreen extends ConsumerWidget {
  const MemoEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(memoEditProvider.select((state) => state.isSaved), (
      previous,
      isSaved,
    ) {
      if (isSaved && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    final state = ref.watch(memoEditProvider);
    final notifier = ref.read(memoEditProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('メモを作成'),
        actions: [
          TextButton(
            onPressed: state.isSaving ? null : notifier.save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PhotoPicker(
            hasPhoto: state.photoPath != null,
            onTap: notifier.pickPhoto,
          ),
          const SizedBox(height: 24),
          const Text('食べた日 （Exifから自動取得）', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.eatenDate != null ? formatYmd(state.eatenDate!) : '未取得',
            ),
          ),
          const SizedBox(height: 24),
          const StoreCandidatePicker(),
          const SizedBox(height: 24),
          _ServingMachinePicker(
            selected: state.servingMachine,
            onSelected: notifier.setServingMachine,
          ),
          const SizedBox(height: 24),
          const ImpressionListEditor(),
          const SizedBox(height: 24),
          const TasteRatingInput(),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.hasPhoto, required this.onTap});

  final bool hasPhoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(hasPhoto ? '📷 写真を変更する' : '📷 写真を選択 / 撮影'),
      ),
    );
  }
}

class _ServingMachinePicker extends StatelessWidget {
  const _ServingMachinePicker({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('サービングマシン', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final machine in ServingMachine.presetValues)
              ChoiceChip(
                label: Text(machine),
                selected: selected == machine,
                onSelected: (_) => onSelected(machine),
              ),
            ChoiceChip(
              label: const Text('その他（自由入力）'),
              selected: selected != null &&
                  !ServingMachine.presetValues.contains(selected),
              onSelected: (_) => onSelected(''),
            ),
          ],
        ),
      ],
    );
  }
}
