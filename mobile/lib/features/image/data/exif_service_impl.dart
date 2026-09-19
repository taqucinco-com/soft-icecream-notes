import 'dart:io';

import 'package:exif/exif.dart';

import 'package:icecream_log/features/image/domain/entities/exif_metadata.dart';
import 'package:icecream_log/features/image/domain/repositories/exif_service.dart';

/// `exif`パッケージを使い、写真ファイルのExifタグから撮影日時・GPS位置情報を抽出する。
/// 対象タグがファイルに存在しない場合は、該当フィールドをnullのまま返す。
class ExifServiceImpl implements ExifService {
  const ExifServiceImpl();

  @override
  Future<ExifMetadata> call(String photoPath) async {
    final tags = await readExifFromFile(File(photoPath));

    return ExifMetadata(
      capturedAt: _readCapturedAt(tags),
      latitude: _readCoordinate(
        tags['GPS GPSLatitude']?.values,
        isNegative: tags['GPS GPSLatitudeRef']?.toString() == 'S',
      ),
      longitude: _readCoordinate(
        tags['GPS GPSLongitude']?.values,
        isNegative: tags['GPS GPSLongitudeRef']?.toString() == 'W',
      ),
    );
  }

  DateTime? _readCapturedAt(Map<String, IfdTag> tags) {
    final raw =
        tags['EXIF DateTimeOriginal']?.toString() ??
        tags['Image DateTime']?.toString();
    if (raw == null) return null;

    // Exifの日時は"yyyy:MM:dd HH:mm:ss"形式のため、日付部の区切りを`-`に変換してから解釈する。
    final normalized = raw.replaceFirst(':', '-').replaceFirst(':', '-');
    return DateTime.tryParse(normalized);
  }

  /// GPS緯度・経度は度分秒（DMS）の`IfdRatios`として格納されているため、10進の度数に変換する。
  double? _readCoordinate(IfdValues? values, {required bool isNegative}) {
    if (values == null || values is! IfdRatios) return null;

    var degrees = 0.0;
    var unit = 1.0;
    for (final ratio in values.ratios) {
      degrees += ratio.toDouble() * unit;
      unit /= 60.0;
    }
    return isNegative ? -degrees : degrees;
  }
}
