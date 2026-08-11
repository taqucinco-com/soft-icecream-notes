import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/extract_photo_metadata_usecase.dart';
import '../../domain/usecases/save_memo_usecase.dart';
import '../../domain/usecases/save_profile_usecase.dart';
import '../../domain/usecases/search_nearby_stores_usecase.dart';
import '../../domain/usecases/watch_memos_usecase.dart';
import '../../domain/usecases/watch_profile_usecase.dart';
import 'repository_providers.dart';

part 'usecase_providers.g.dart';

@riverpod
ExtractPhotoMetadataUseCase extractPhotoMetadataUseCase(Ref ref) {
  return const ExtractPhotoMetadataUseCase();
}

@riverpod
SearchNearbyStoresUseCase searchNearbyStoresUseCase(Ref ref) {
  return SearchNearbyStoresUseCase(ref.watch(storeSearchRepositoryProvider));
}

@riverpod
SaveMemoUseCase saveMemoUseCase(Ref ref) {
  return SaveMemoUseCase(ref.watch(memoRepositoryProvider));
}

@riverpod
WatchMemosUseCase watchMemosUseCase(Ref ref) {
  return WatchMemosUseCase(ref.watch(memoRepositoryProvider));
}

@riverpod
SaveProfileUseCase saveProfileUseCase(Ref ref) {
  return SaveProfileUseCase(ref.watch(profileRepositoryProvider));
}

@riverpod
WatchProfileUseCase watchProfileUseCase(Ref ref) {
  return WatchProfileUseCase(ref.watch(profileRepositoryProvider));
}
