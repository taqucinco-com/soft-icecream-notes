import 'package:icecream_log/features/memo/domain/entities/exif_metadata.dart';

/// 本物の`ExifService`（`exif`パッケージ）が用意されるまでの間、固定のサンプル値を返す。
/// 写真取り込みフローの体裁を確認するためのモック実装。
class ExtractPhotoMetadataUseCase {
  const ExtractPhotoMetadataUseCase();

  ExifMetadata call(String photoPath) {
    return ExifMetadata(
      capturedAt: DateTime(2026, 8, 5),
      latitude: 35.6586,
      longitude: 139.7454,
    );
  }
}
