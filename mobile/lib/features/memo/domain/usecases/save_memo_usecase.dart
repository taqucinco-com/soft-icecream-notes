import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/features/memo/domain/repositories/memo_repository.dart';

class SaveMemoUseCase {
  const SaveMemoUseCase(this._repository);

  final MemoRepository _repository;

  Future<void> call(Memo memo) => _repository.save(memo);
}
