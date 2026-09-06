import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/memo.dart';
import '../di/usecase_providers.dart';
import 'serving_machine_filter.dart';

part 'memo_list.g.dart';

@riverpod
Stream<List<Memo>> memoList(Ref ref) {
  final filter = ref.watch(servingMachineFilterProvider);
  final watchMemos = ref.watch(watchMemosUseCaseProvider);
  return watchMemos(servingMachineFilter: filter);
}
