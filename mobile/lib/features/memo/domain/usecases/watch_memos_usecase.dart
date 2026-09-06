import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/features/memo/domain/repositories/memo_repository.dart';

class WatchMemosUseCase {
  const WatchMemosUseCase(this._repository);

  final MemoRepository _repository;

  Stream<List<Memo>> call({String? servingMachineFilter}) {
    return _repository.watchAll(servingMachineFilter: servingMachineFilter);
  }
}
