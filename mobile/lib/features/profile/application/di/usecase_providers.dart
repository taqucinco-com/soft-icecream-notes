import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/save_profile_usecase.dart';
import '../../domain/usecases/watch_profile_usecase.dart';
import 'repository_providers.dart';

part 'usecase_providers.g.dart';

@riverpod
SaveProfileUseCase saveProfileUseCase(Ref ref) {
  return SaveProfileUseCase(ref.watch(profileRepositoryProvider));
}

@riverpod
WatchProfileUseCase watchProfileUseCase(Ref ref) {
  return WatchProfileUseCase(ref.watch(profileRepositoryProvider));
}
