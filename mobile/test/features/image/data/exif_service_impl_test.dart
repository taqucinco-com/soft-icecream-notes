import 'package:flutter_test/flutter_test.dart';
import 'package:icecream_log/features/image/data/exif_service_impl.dart';

void main() {
  const exifService = ExifServiceImpl();

  test('Exif情報を持つ実店舗の写真から撮影日時とGPS位置情報を取得できる', () async {
    final metadata = await exifService('test/mock/sample.HEIC');

    expect(metadata.capturedAt, DateTime(2026, 8, 22, 13, 50, 14));
    expect(metadata.latitude, closeTo(35.678, 0.01));
    expect(metadata.longitude, closeTo(139.692, 0.01));
  });

  test('Exif情報を持たない写真では撮影日時・GPS位置情報がnullになる', () async {
    final metadata = await exifService('test/mock/no_exif.png');

    expect(metadata.capturedAt, isNull);
    expect(metadata.latitude, isNull);
    expect(metadata.longitude, isNull);
  });
}
