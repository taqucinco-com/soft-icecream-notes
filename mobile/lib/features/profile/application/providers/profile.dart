import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/features/profile/application/di/usecase_providers.dart';
import 'package:icecream_log/features/profile/domain/entities/user_profile.dart';

part 'generated/profile.g.dart';

@riverpod
Stream<UserProfile> profile(Ref ref) {
  return ref.watch(watchProfileUseCaseProvider)();
}
