import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version.g.dart';

/// `package_info_plus`未導入のため固定値を返すモック実装（Figma 05_設定の表示値と一致させる）。
@riverpod
String appVersion(Ref ref) => '1.0.0';
