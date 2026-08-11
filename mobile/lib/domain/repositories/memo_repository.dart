import '../entities/memo.dart';

abstract class MemoRepository {
  Stream<List<Memo>> watchAll({String? servingMachineFilter});
  Future<void> save(Memo memo);
}
