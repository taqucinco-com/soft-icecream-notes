import 'package:icecream_log/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile> watch();
  Future<void> save(UserProfile profile);
}
