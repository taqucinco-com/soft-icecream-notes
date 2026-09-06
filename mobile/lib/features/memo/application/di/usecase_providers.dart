import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/extract_photo_metadata_usecase.dart';
import '../../domain/usecases/save_memo_usecase.dart';
import '../../domain/usecases/watch_memos_usecase.dart';
import 'repository_providers.dart';

part 'usecase_providers.g.dart';

@riverpod
ExtractPhotoMetadataUseCase extractPhotoMetadataUseCase(Ref ref) {
  return const ExtractPhotoMetadataUseCase();
}

@riverpod
SaveMemoUseCase saveMemoUseCase(Ref ref) {
  return SaveMemoUseCase(ref.watch(memoRepositoryProvider));
}

@riverpod
WatchMemosUseCase watchMemosUseCase(Ref ref) {
  return WatchMemosUseCase(ref.watch(memoRepositoryProvider));
}
