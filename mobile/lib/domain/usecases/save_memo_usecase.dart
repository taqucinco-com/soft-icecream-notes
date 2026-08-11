import '../entities/memo.dart';
import '../repositories/memo_repository.dart';

class SaveMemoUseCase {
  const SaveMemoUseCase(this._repository);

  final MemoRepository _repository;

  Future<void> call(Memo memo) => _repository.save(memo);
}
