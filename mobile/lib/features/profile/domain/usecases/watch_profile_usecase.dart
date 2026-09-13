import 'package:icecream_log/features/profile/domain/entities/user_profile.dart';
import 'package:icecream_log/features/profile/domain/repositories/profile_repository.dart';

class WatchProfileUseCase {
  const WatchProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Stream<UserProfile> call() => _repository.watch();
}
