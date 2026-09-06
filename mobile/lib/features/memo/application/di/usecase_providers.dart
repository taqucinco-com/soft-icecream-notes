import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/features/memo/application/di/repository_providers.dart';
import 'package:icecream_log/features/memo/domain/usecases/extract_photo_metadata_usecase.dart';
import 'package:icecream_log/features/memo/domain/usecases/save_memo_usecase.dart';
import 'package:icecream_log/features/memo/domain/usecases/watch_memos_usecase.dart';

part 'generated/usecase_providers.g.dart';

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
