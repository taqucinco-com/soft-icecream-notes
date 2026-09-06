import 'dart:async';

import 'package:icecream_log/features/profile/domain/entities/user_profile.dart';
import 'package:icecream_log/features/profile/domain/repositories/profile_repository.dart';

/// Figmaワイヤーフレーム（05_設定）の「ソフト太郎」を初期値にしたモック実装。
class MockProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(nickname: 'ソフト太郎');
  final StreamController<UserProfile> _controller =
      StreamController<UserProfile>.broadcast();

  @override
  Stream<UserProfile> watch() {
    return Stream.multi((controller) {
      controller.add(_profile);
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> save(UserProfile profile) async {
    _profile = profile;
    _controller.add(_profile);
  }
}
