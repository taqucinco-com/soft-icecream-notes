import 'package:icecream_log/features/memo/domain/entities/nearby_store_candidate.dart';
import 'package:icecream_log/features/memo/domain/entities/taste_rating.dart';

class MemoEditState {
  const MemoEditState({
    this.photoPath,
    this.eatenDate,
    this.latitude,
    this.longitude,
    this.storeCandidates = const [],
    this.storeName,
    this.storePlaceId,
    this.isManualStoreEntry = false,
    this.servingMachines = const [],
    this.impressions = const [],
    this.tasteRating,
    this.isSaving = false,
    this.isSaved = false,
  });

  final String? photoPath;
  final DateTime? eatenDate;
  final double? latitude;
  final double? longitude;
  final List<NearbyStoreCandidate> storeCandidates;
  final String? storeName;
  final String? storePlaceId;
  final bool isManualStoreEntry;
  final List<String> servingMachines;
  final List<String> impressions;
  final TasteRating? tasteRating;
  final bool isSaving;
  final bool isSaved;

  MemoEditState copyWith({
    String? photoPath,
    DateTime? eatenDate,
    double? latitude,
    double? longitude,
    List<NearbyStoreCandidate>? storeCandidates,
    String? storeName,
    String? storePlaceId,
    bool? isManualStoreEntry,
    List<String>? servingMachines,
    List<String>? impressions,
    TasteRating? tasteRating,
    bool? isSaving,
    bool? isSaved,
  }) {
    return MemoEditState(
      photoPath: photoPath ?? this.photoPath,
      eatenDate: eatenDate ?? this.eatenDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      storeCandidates: storeCandidates ?? this.storeCandidates,
      storeName: storeName ?? this.storeName,
      storePlaceId: storePlaceId ?? this.storePlaceId,
      isManualStoreEntry: isManualStoreEntry ?? this.isManualStoreEntry,
      servingMachines: servingMachines ?? this.servingMachines,
      impressions: impressions ?? this.impressions,
      tasteRating: tasteRating ?? this.tasteRating,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
