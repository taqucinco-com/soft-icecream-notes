import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:icecream_log/composition/nearby_store_finder_provider.dart';
import 'package:icecream_log/features/memo/application/di/usecase_providers.dart';
import 'package:icecream_log/features/memo/application/providers/memo_edit_state.dart';
import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/features/memo/domain/entities/nearby_store_candidate.dart';
import 'package:icecream_log/features/memo/domain/entities/serving_machine.dart';
import 'package:icecream_log/features/memo/domain/entities/taste_rating.dart';

part 'generated/memo_edit.g.dart';

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
    List<NearbyStoreCandidate> candidates = const [];
    if (metadata.latitude != null && metadata.longitude != null) {
      candidates = await ref.read(nearbyStoreFinderProvider)(
        metadata.latitude!,
        metadata.longitude!,
      );
    }
    // copyWithの`?? this.value`パターンでは新しい写真にExif情報が無い場合に
    // 前の写真の位置情報・日付が残ってしまうため、ここでは明示的に全フィールドを再構築する。
    state = MemoEditState(
      photoPath: mockPhotoPath,
      eatenDate: metadata.capturedAt,
      latitude: metadata.latitude,
      longitude: metadata.longitude,
      storeCandidates: candidates,
      storeName: state.storeName,
      storePlaceId: state.storePlaceId,
      isManualStoreEntry: state.isManualStoreEntry,
      servingMachines: state.servingMachines,
      impressions: state.impressions,
      tasteRating: state.tasteRating,
      isSaving: state.isSaving,
      isSaved: state.isSaved,
    );
  }

  void setEatenDate(DateTime date) {
    state = state.copyWith(eatenDate: date);
  }

  void selectNearbyStoreCandidate(NearbyStoreCandidate candidate) {
    state = state.copyWith(
      storeName: candidate.name,
      storePlaceId: candidate.placeId,
      isManualStoreEntry: false,
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
      servingMachines: state.servingMachines,
      impressions: state.impressions,
      tasteRating: state.tasteRating,
    );
  }

  void setStoreName(String value) {
    state = state.copyWith(storeName: value);
  }

  void toggleServingMachine(String value) {
    final current = state.servingMachines;
    final updated = current.contains(value)
        ? current.where((machine) => machine != value).toList()
        : [...current, value];
    state = state.copyWith(servingMachines: updated);
  }

  /// 「その他（自由入力）」チップで入力されたテキストを、プリセット値はそのままに
  /// カスタム分だけ差し替える。空文字ならカスタム分を取り除く。
  void setCustomServingMachine(String value) {
    final presetsOnly = state.servingMachines
        .where(ServingMachine.presetValues.contains)
        .toList();
    final trimmed = value.trim();
    state = state.copyWith(
      servingMachines: trimmed.isEmpty
          ? presetsOnly
          : [...presetsOnly, trimmed],
    );
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
      storeName: _normalizeToNull(state.storeName),
      storePlaceId: state.storePlaceId,
      servingMachines: _normalizeServingMachines(state.servingMachines),
      impressions: state.impressions,
      tasteRating: state.tasteRating,
    );
    await ref.read(saveMemoUseCaseProvider)(memo);
    state = state.copyWith(isSaving: false, isSaved: true);
  }

  /// 未入力の自由入力欄（空文字）が空表示のまま永続化されるのを防ぐため、
  /// トリムして空ならnullに正規化する。
  String? _normalizeToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// カスタム自由入力の空要素・重複を取り除く。
  List<String> _normalizeServingMachines(List<String> values) {
    final trimmed = values.map((value) => value.trim()).where(
      (value) => value.isNotEmpty,
    );
    return trimmed.toSet().toList();
  }
}
