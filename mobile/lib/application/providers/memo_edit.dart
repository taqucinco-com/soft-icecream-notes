import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/memo.dart';
import '../../domain/entities/store_candidate.dart';
import '../../domain/entities/taste_rating.dart';
import '../di/usecase_providers.dart';
import 'memo_edit_state.dart';

part 'memo_edit.g.dart';

@riverpod
class MemoEdit extends _$MemoEdit {
  @override
  MemoEditState build() => const MemoEditState();

  /// 写真取り込み〜Exif抽出〜店舗候補検索までを一括で行うモックフロー。
  /// 実際の`image_picker`/`ExifService`/Google Places連携ができるまでの代替。
  Future<void> pickPhoto() async {
    const mockPhotoPath = 'mock://selected-photo.jpg';
    final metadata = ref.read(extractPhotoMetadataUseCaseProvider)(
      mockPhotoPath,
    );
    List<StoreCandidate> candidates = const [];
    if (metadata.latitude != null && metadata.longitude != null) {
      candidates = await ref.read(searchNearbyStoresUseCaseProvider)(
        metadata.latitude!,
        metadata.longitude!,
      );
    }
    state = state.copyWith(
      photoPath: mockPhotoPath,
      eatenDate: metadata.capturedAt,
      latitude: metadata.latitude,
      longitude: metadata.longitude,
      storeCandidates: candidates,
    );
  }

  void setEatenDate(DateTime date) {
    state = state.copyWith(eatenDate: date);
  }

  void selectStoreCandidate(StoreCandidate candidate) {
    state = state.copyWith(
      storeName: candidate.name,
      storePlaceId: candidate.placeId,
    );
  }

  void enterStoreManually() {
    state = MemoEditState(
      photoPath: state.photoPath,
      eatenDate: state.eatenDate,
      latitude: state.latitude,
      longitude: state.longitude,
      storeCandidates: state.storeCandidates,
      storeName: '',
      isManualStoreEntry: true,
      servingMachine: state.servingMachine,
      impressions: state.impressions,
      tasteRating: state.tasteRating,
    );
  }

  void setStoreName(String value) {
    state = state.copyWith(storeName: value);
  }

  void setServingMachine(String value) {
    state = state.copyWith(servingMachine: value);
  }

  void addImpression(String text) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(impressions: [...state.impressions, text.trim()]);
  }

  void removeImpressionAt(int index) {
    final updated = [...state.impressions]..removeAt(index);
    state = state.copyWith(impressions: updated);
  }

  void setTasteRating(TasteRating rating) {
    state = state.copyWith(tasteRating: rating);
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);
    final memo = Memo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      photoPath: state.photoPath,
      eatenDate: state.eatenDate,
      latitude: state.latitude,
      longitude: state.longitude,
      storeName: state.storeName,
      storePlaceId: state.storePlaceId,
      servingMachine: state.servingMachine,
      impressions: state.impressions,
      tasteRating: state.tasteRating,
    );
    await ref.read(saveMemoUseCaseProvider)(memo);
    state = state.copyWith(isSaving: false, isSaved: true);
  }
}
