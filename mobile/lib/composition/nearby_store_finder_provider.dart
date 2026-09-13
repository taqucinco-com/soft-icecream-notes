import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/features/memo/domain/entities/nearby_store_candidate.dart';
import 'package:icecream_log/features/memo/domain/repositories/nearby_store_finder.dart';
import 'package:icecream_log/features/store_search/application/di/usecase_providers.dart';
import 'package:icecream_log/features/store_search/domain/usecases/search_nearby_stores_usecase.dart';

part 'generated/nearby_store_finder_provider.g.dart';

/// memo機能の[NearbyStoreFinder]をstore_search機能の実装に結びつけるアダプタ。
/// memo機能とstore_search機能のどちらもこのファイルを知らなくてよいように、
/// 両者を横断する結線はcomposition層に閉じ込める。
class NearbyStoreFinderAdapter implements NearbyStoreFinder {
  const NearbyStoreFinderAdapter(this._searchNearbyStores);

  final SearchNearbyStoresUseCase _searchNearbyStores;

  @override
  Future<List<NearbyStoreCandidate>> call(
    double latitude,
    double longitude,
  ) async {
    final candidates = await _searchNearbyStores(latitude, longitude);
    return [
      for (final candidate in candidates)
        NearbyStoreCandidate(placeId: candidate.placeId, name: candidate.name),
    ];
  }
}

@riverpod
NearbyStoreFinder nearbyStoreFinder(Ref ref) {
  return NearbyStoreFinderAdapter(ref.watch(searchNearbyStoresUseCaseProvider));
}
