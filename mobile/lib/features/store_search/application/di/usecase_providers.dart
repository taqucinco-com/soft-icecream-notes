import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/features/store_search/application/di/repository_providers.dart';
import 'package:icecream_log/features/store_search/domain/usecases/search_nearby_stores_usecase.dart';

part 'generated/usecase_providers.g.dart';

@riverpod
SearchNearbyStoresUseCase searchNearbyStoresUseCase(Ref ref) {
  return SearchNearbyStoresUseCase(ref.watch(storeSearchRepositoryProvider));
}
