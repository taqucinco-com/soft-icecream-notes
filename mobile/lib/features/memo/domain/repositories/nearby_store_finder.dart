import 'package:icecream_log/features/memo/domain/entities/nearby_store_candidate.dart';

/// メモ作成フローが必要とする「位置情報から近隣店舗候補を探す」という能力の抽象。
/// 実際の検索手段（store_search機能・Google Places等）はmemo機能から隠蔽し、
/// composition層でこのインターフェースに実装を注入する（DIP）。
abstract class NearbyStoreFinder {
  Future<List<NearbyStoreCandidate>> call(double latitude, double longitude);
}
