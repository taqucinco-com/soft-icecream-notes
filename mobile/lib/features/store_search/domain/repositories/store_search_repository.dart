import 'package:icecream_log/features/store_search/domain/entities/store_candidate.dart';

abstract class StoreSearchRepository {
  Future<List<StoreCandidate>> searchNearby(double lat, double lng);
}
