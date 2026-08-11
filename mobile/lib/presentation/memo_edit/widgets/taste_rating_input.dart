import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/memo_edit.dart';
import '../../../domain/entities/taste_rating.dart';

const _defaultRating = TasteRating(
  mouthfeel: 1,
  ingredientUse: 1,
  uniqueness: 1,
  flavorQuality: 1,
  temperatureControl: 1,
);

/// Figma 03フレームの「味の5軸評価（1〜5）」欄。各軸を5段階のドットで入力する。
class TasteRatingInput extends ConsumerWidget {
  const TasteRatingInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(
      memoEditProvider.select((state) => state.tasteRating),
    );
    final notifier = ref.read(memoEditProvider.notifier);
    final current = rating ?? _defaultRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('味の5軸評価（1〜5）', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        _AxisRow(
          label: '口当たり',
          value: current.mouthfeel,
          onChanged: (v) =>
              notifier.setTasteRating(current.copyWith(mouthfeel: v)),
        ),
        _AxisRow(
          label: '素材の活かし方',
          value: current.ingredientUse,
          onChanged: (v) =>
              notifier.setTasteRating(current.copyWith(ingredientUse: v)),
        ),
        _AxisRow(
          label: '個性的',
          value: current.uniqueness,
          onChanged: (v) =>
              notifier.setTasteRating(current.copyWith(uniqueness: v)),
        ),
        _AxisRow(
          label: 'フレーバーの良さ',
          value: current.flavorQuality,
          onChanged: (v) =>
              notifier.setTasteRating(current.copyWith(flavorQuality: v)),
        ),
        _AxisRow(
          label: '温度管理',
          value: current.temperatureControl,
          onChanged: (v) => notifier.setTasteRating(
            current.copyWith(temperatureControl: v),
          ),
        ),
      ],
    );
  }
}

class _AxisRow extends StatelessWidget {
  const _AxisRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          const Spacer(),
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Icon(
                    i <= value ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
