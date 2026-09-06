import '../../../store_search/domain/entities/store_candidate.dart';
import '../../domain/entities/taste_rating.dart';

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
    this.servingMachine,
    this.impressions = const [],
    this.tasteRating,
    this.isSaving = false,
    this.isSaved = false,
  });

  final String? photoPath;
  final DateTime? eatenDate;
  final double? latitude;
  final double? longitude;
  final List<StoreCandidate> storeCandidates;
  final String? storeName;
  final String? storePlaceId;
  final bool isManualStoreEntry;
  final String? servingMachine;
  final List<String> impressions;
  final TasteRating? tasteRating;
  final bool isSaving;
  final bool isSaved;

  MemoEditState copyWith({
    String? photoPath,
    DateTime? eatenDate,
    double? latitude,
    double? longitude,
    List<StoreCandidate>? storeCandidates,
    String? storeName,
    String? storePlaceId,
    bool? isManualStoreEntry,
    String? servingMachine,
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
      servingMachine: servingMachine ?? this.servingMachine,
      impressions: impressions ?? this.impressions,
      tasteRating: tasteRating ?? this.tasteRating,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
