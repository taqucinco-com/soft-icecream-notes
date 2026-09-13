import 'package:icecream_log/features/store_search/domain/entities/store_candidate.dart';
import 'package:icecream_log/features/store_search/domain/repositories/store_search_repository.dart';

/// Figmaワイヤーフレーム（03_メモ作成編集）の「候補1: テオブロマ」「候補2: ミルク屋」に
/// 対応する固定候補を返すモック実装。本物のGoogle Places連携（[StoreSearchRepositoryImpl]相当）
/// が用意されるまでの間、presentation/application層を実装・検証するために使う。
class MockStoreSearchRepository implements StoreSearchRepository {
  @override
  Future<List<StoreCandidate>> searchNearby(double lat, double lng) async {
    return const [
      StoreCandidate(placeId: 'mock-place-1', name: 'テオブロマ'),
      StoreCandidate(placeId: 'mock-place-2', name: 'ミルク屋'),
    ];
  }
}
