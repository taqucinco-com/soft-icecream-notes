import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:icecream_log/features/memo/application/providers/memo_edit.dart';
import 'package:icecream_log/features/memo/domain/entities/serving_machine.dart';
import 'package:icecream_log/presentation/format/date_format.dart';
import 'package:icecream_log/presentation/memo_edit/widgets/impression_list_editor.dart';
import 'package:icecream_log/presentation/memo_edit/widgets/store_candidate_picker.dart';
import 'package:icecream_log/presentation/memo_edit/widgets/taste_rating_input.dart';

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
            selected: state.servingMachines,
            onToggle: notifier.toggleServingMachine,
            onCustomChanged: notifier.setCustomServingMachine,
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

class _ServingMachinePicker extends StatefulWidget {
  const _ServingMachinePicker({
    required this.selected,
    required this.onToggle,
    required this.onCustomChanged,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onCustomChanged;

  @override
  State<_ServingMachinePicker> createState() => _ServingMachinePickerState();
}

class _ServingMachinePickerState extends State<_ServingMachinePicker> {
  late final TextEditingController _controller;
  bool _customFieldVisible = false;

  String get _customValue => widget.selected.firstWhere(
    (machine) => !ServingMachine.presetValues.contains(machine),
    orElse: () => '',
  );

  @override
  void initState() {
    super.initState();
    _customFieldVisible = _customValue.isNotEmpty;
    _controller = TextEditingController(text: _customValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customValue = _customValue;
    final isCustomActive = _customFieldVisible || customValue.isNotEmpty;
    // ユーザーの入力によるものではなく、外部要因（保存後のリセット等）で
    // 値が変わった場合のみコントローラを同期する。
    if (_controller.text != customValue) {
      _controller.value = TextEditingValue(
        text: customValue,
        selection: TextSelection.collapsed(offset: customValue.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('サービングマシン（複数選択可）', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final machine in ServingMachine.presetValues)
              FilterChip(
                label: Text(machine),
                selected: widget.selected.contains(machine),
                onSelected: (_) => widget.onToggle(machine),
              ),
            FilterChip(
              label: const Text('その他（自由入力）'),
              selected: isCustomActive,
              onSelected: (selected) {
                setState(() => _customFieldVisible = selected);
                if (!selected) {
                  widget.onCustomChanged('');
                }
              },
            ),
          ],
        ),
        if (isCustomActive) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'サービングマシン名を入力',
            ),
            onChanged: widget.onCustomChanged,
          ),
        ],
      ],
    );
  }
}
