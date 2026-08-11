import '../entities/store_candidate.dart';
import '../repositories/store_search_repository.dart';

class SearchNearbyStoresUseCase {
  const SearchNearbyStoresUseCase(this._repository);

  final StoreSearchRepository _repository;

  Future<List<StoreCandidate>> call(double lat, double lng) {
    return _repository.searchNearby(lat, lng);
  }
}
