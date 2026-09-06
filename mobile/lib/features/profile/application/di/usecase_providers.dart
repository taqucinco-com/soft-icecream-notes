import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/features/profile/application/di/repository_providers.dart';
import 'package:icecream_log/features/profile/domain/usecases/save_profile_usecase.dart';
import 'package:icecream_log/features/profile/domain/usecases/watch_profile_usecase.dart';

part 'generated/usecase_providers.g.dart';

@riverpod
SaveProfileUseCase saveProfileUseCase(Ref ref) {
  return SaveProfileUseCase(ref.watch(profileRepositoryProvider));
}

@riverpod
WatchProfileUseCase watchProfileUseCase(Ref ref) {
  return WatchProfileUseCase(ref.watch(profileRepositoryProvider));
}
