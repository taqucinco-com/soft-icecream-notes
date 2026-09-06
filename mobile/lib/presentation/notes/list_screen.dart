import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:icecream_log/features/memo/application/providers/memo_list.dart';
import 'package:icecream_log/presentation/notes/widgets/memo_card.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memoListProvider);
    return memosAsync.when(
      data: (memos) {
        if (memos.isEmpty) {
          return const Center(child: Text('まだメモがありません'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index];
            return MemoCard(
              memo: memo,
              onTap: () => context.push('/notes/detail/${memo.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('読み込みに失敗しました: $error')),
    );
  }
}
