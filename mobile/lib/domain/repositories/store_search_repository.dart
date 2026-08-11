import '../entities/store_candidate.dart';

abstract class StoreSearchRepository {
  Future<List<StoreCandidate>> searchNearby(double lat, double lng);
}
