import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/features/memo/application/di/usecase_providers.dart';
import 'package:icecream_log/features/memo/application/providers/serving_machine_filter.dart';
import 'package:icecream_log/features/memo/domain/entities/memo.dart';

part 'generated/memo_list.g.dart';

@riverpod
Stream<List<Memo>> memoList(Ref ref) {
  final filter = ref.watch(servingMachineFilterProvider);
  final watchMemos = ref.watch(watchMemosUseCaseProvider);
  return watchMemos(servingMachineFilter: filter);
}
