import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user_profile.dart';
import '../di/usecase_providers.dart';

part 'profile.g.dart';

@riverpod
Stream<UserProfile> profile(Ref ref) {
  return ref.watch(watchProfileUseCaseProvider)();
}
