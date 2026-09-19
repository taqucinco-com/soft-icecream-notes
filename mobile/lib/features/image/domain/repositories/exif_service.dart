import 'package:icecream_log/features/image/domain/entities/exif_metadata.dart';

abstract class ExifService {
  Future<ExifMetadata> call(String photoPath);
}
