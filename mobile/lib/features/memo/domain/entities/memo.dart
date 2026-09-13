import 'package:icecream_log/features/memo/domain/entities/taste_rating.dart';

class Memo {
  const Memo({
    required this.id,
    this.photoPath,
    this.eatenDate,
    this.latitude,
    this.longitude,
    this.storeName,
    this.storePlaceId,
    this.servingMachine,
    this.impressions = const [],
    this.tasteRating,
  });

  final String id;
  final String? photoPath;
  final DateTime? eatenDate;
  final double? latitude;
  final double? longitude;
  final String? storeName;
  final String? storePlaceId;
  final String? servingMachine;
  final List<String> impressions;
  final TasteRating? tasteRating;

  bool get hasLocation => latitude != null && longitude != null;

  Memo copyWith({
    String? photoPath,
    DateTime? eatenDate,
    double? latitude,
    double? longitude,
    String? storeName,
    String? storePlaceId,
    String? servingMachine,
    List<String>? impressions,
    TasteRating? tasteRating,
  }) {
    return Memo(
      id: id,
      photoPath: photoPath ?? this.photoPath,
      eatenDate: eatenDate ?? this.eatenDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      storeName: storeName ?? this.storeName,
      storePlaceId: storePlaceId ?? this.storePlaceId,
      servingMachine: servingMachine ?? this.servingMachine,
      impressions: impressions ?? this.impressions,
      tasteRating: tasteRating ?? this.tasteRating,
    );
  }
}
