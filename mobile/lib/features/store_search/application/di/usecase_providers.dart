import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/search_nearby_stores_usecase.dart';
import 'repository_providers.dart';

part 'usecase_providers.g.dart';

@riverpod
SearchNearbyStoresUseCase searchNearbyStoresUseCase(Ref ref) {
  return SearchNearbyStoresUseCase(ref.watch(storeSearchRepositoryProvider));
}
