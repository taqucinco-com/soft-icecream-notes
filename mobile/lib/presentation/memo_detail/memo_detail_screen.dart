import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/memo_list.dart';
import '../../domain/entities/memo.dart';
import '../format/date_format.dart';
import 'widgets/taste_radar_chart.dart';

/// Figma 04フレーム（メモ詳細）。
class MemoDetailScreen extends ConsumerWidget {
  const MemoDetailScreen({super.key, required this.memoId});

  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ詳細'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('編集機能は今後実装予定です')),
              );
            },
            child: const Text('編集'),
          ),
        ],
      ),
      body: memosAsync.when(
        data: (memos) {
          final memo = memos.where((m) => m.id == memoId).firstOrNull;
          if (memo == null) {
            return const Center(child: Text('メモが見つかりません'));
          }
          return _DetailContent(memo: memo);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('読み込みに失敗しました: $error')),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.memo});

  final Memo memo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 220,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.icecream_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo.storeName ?? '店名未設定',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (memo.eatenDate != null) Text(formatYmd(memo.eatenDate!)),
                  if (memo.servingMachine != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        memo.servingMachine!,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text('感想', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (memo.impressions.isEmpty)
                const Text('感想はまだありません')
              else
                for (final impression in memo.impressions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6),
                        const SizedBox(width: 8),
                        Expanded(child: Text(impression)),
                      ],
                    ),
                  ),
              const SizedBox(height: 24),
              Text('味の5軸評価', style: Theme.of(context).textTheme.titleSmall),
              TasteRadarChart(rating: memo.tasteRating),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
