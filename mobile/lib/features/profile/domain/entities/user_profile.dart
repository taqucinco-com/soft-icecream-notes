class UserProfile {
  const UserProfile({this.nickname, this.iconPath});

  final String? nickname;
  final String? iconPath;

  UserProfile copyWith({String? nickname, String? iconPath}) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
