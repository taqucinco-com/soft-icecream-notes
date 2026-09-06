import 'package:icecream_log/features/profile/domain/entities/user_profile.dart';
import 'package:icecream_log/features/profile/domain/repositories/profile_repository.dart';

class SaveProfileUseCase {
  const SaveProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call(UserProfile profile) => _repository.save(profile);
}
