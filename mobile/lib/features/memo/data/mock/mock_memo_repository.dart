import 'dart:async';

import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/features/memo/domain/entities/serving_machine.dart';
import 'package:icecream_log/features/memo/domain/entities/taste_rating.dart';
import 'package:icecream_log/features/memo/domain/repositories/memo_repository.dart';

/// Figmaワイヤーフレーム（01_メモ一覧_リスト）のサンプルデータをそのまま初期値にしたモック実装。
/// 本物のdrift実装（[MemoRepositoryImpl]相当）が用意されるまでの間、presentation/application層を
/// 実装・検証するために使う。
class MockMemoRepository implements MemoRepository {
  MockMemoRepository() : _memos = _seedMemos();

  final List<Memo> _memos;
  final StreamController<List<Memo>> _controller =
      StreamController<List<Memo>>.broadcast();

  @override
  Stream<List<Memo>> watchAll({String? servingMachineFilter}) {
    return Stream.multi((controller) {
      controller.add(_filtered(servingMachineFilter));
      final subscription = _controller.stream.listen(
        (_) => controller.add(_filtered(servingMachineFilter)),
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> save(Memo memo) async {
    final index = _memos.indexWhere((m) => m.id == memo.id);
    if (index >= 0) {
      _memos[index] = memo;
    } else {
      _memos.add(memo);
    }
    _controller.add(_memos);
  }

  List<Memo> _filtered(String? servingMachineFilter) {
    final sorted = [..._memos]
      ..sort(
        (a, b) =>
            (b.eatenDate ?? DateTime(0)).compareTo(a.eatenDate ?? DateTime(0)),
      );
    if (servingMachineFilter == null) return sorted;
    return sorted
        .where((memo) => memo.servingMachine == servingMachineFilter)
        .toList();
  }

  static List<Memo> _seedMemos() => [
    Memo(
      id: '1',
      eatenDate: DateTime(2026, 8, 5),
      latitude: 35.6586,
      longitude: 139.7454,
      storeName: 'ジェラテリア　テオブロマ',
      servingMachine: ServingMachine.calpigiani,
      impressions: const ['ミルク感が強く後味がすっきり', 'バニラの香りが上品', 'テクスチャがなめらか'],
      tasteRating: const TasteRating(
        mouthfeel: 4,
        ingredientUse: 5,
        uniqueness: 3,
        flavorQuality: 5,
        temperatureControl: 4,
      ),
    ),
    Memo(
      id: '2',
      eatenDate: DateTime(2026, 7, 28),
      latitude: 35.6702,
      longitude: 139.7016,
      storeName: 'ソフトクリーム専門店 雪',
      servingMachine: ServingMachine.nissei,
      impressions: const ['きめ細かい口当たり'],
      tasteRating: const TasteRating(
        mouthfeel: 5,
        ingredientUse: 4,
        uniqueness: 4,
        flavorQuality: 4,
        temperatureControl: 5,
      ),
    ),
    Memo(
      id: '3',
      eatenDate: DateTime(2026, 7, 20),
      latitude: 35.6280,
      longitude: 139.7387,
      storeName: '牧場カフェ　のどか',
      servingMachine: ServingMachine.other,
    ),
    Memo(
      id: '4',
      eatenDate: DateTime(2026, 7, 12),
      storeName: '店名未設定（位置情報なし）',
      servingMachine: ServingMachine.calpigiani,
    ),
    Memo(
      id: '5',
      eatenDate: DateTime(2026, 6, 30),
      latitude: 35.7100,
      longitude: 139.8107,
      storeName: 'ミルクスタンド　白樺',
      servingMachine: ServingMachine.nissei,
    ),
  ];
}
