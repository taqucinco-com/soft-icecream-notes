import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:icecream_log/features/memo/application/providers/memo_list.dart';
import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/presentation/format/date_format.dart';

/// APIキーが無くても確認できるよう、`google_maps_flutter`の代わりに
/// プレースホルダー画像（グレー背景＋ピン風のドット）で表現する（design.md 既知のリスク参照）。
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memoListProvider);
    return memosAsync.when(
      data: (memos) {
        final pinned = memos.where((memo) => memo.hasLocation).toList();
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Text(
                    '[ Google Map ]',
                    style: TextStyle(color: Colors.black45),
                  ),
                ),
              ),
            ),
            for (final entry in pinned.asMap().entries)
              _MapPin(
                index: entry.key,
                onTap: () => context.push('/notes/detail/${entry.value.id}'),
              ),
            if (pinned.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: _PreviewCard(
                  memo: pinned.first,
                  onTap: () => context.push('/notes/detail/${pinned.first.id}'),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('読み込みに失敗しました: $error')),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.index, required this.onTap});

  final int index;
  final VoidCallback onTap;

  // ワイヤーフレーム（02_メモ一覧_マップ）のピン位置を模した固定配置。
  static const _positions = [
    Offset(80, 160),
    Offset(220, 260),
    Offset(140, 400),
    Offset(280, 480),
    Offset(60, 340),
  ];

  @override
  Widget build(BuildContext context) {
    final position = _positions[index % _positions.length];
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.icecream, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.memo, required this.onTap});

  final Memo memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (memo.eatenDate != null) formatYmd(memo.eatenDate!),
                        if (memo.servingMachine != null) memo.servingMachine!,
                      ].join(' ・ '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
