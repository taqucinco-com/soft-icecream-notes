import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class WatchProfileUseCase {
  const WatchProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Stream<UserProfile> call() => _repository.watch();
}
