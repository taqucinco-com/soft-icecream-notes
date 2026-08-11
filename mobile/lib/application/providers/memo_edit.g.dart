// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_edit.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MemoEdit)
final memoEditProvider = MemoEditProvider._();

final class MemoEditProvider
    extends $NotifierProvider<MemoEdit, MemoEditState> {
  MemoEditProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoEditProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoEditHash();

  @$internal
  @override
  MemoEdit create() => MemoEdit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoEditState>(value),
    );
  }
}

String _$memoEditHash() => r'121383fa8a51e7de6080d3df5a692de227a74b59';

abstract class _$MemoEdit extends $Notifier<MemoEditState> {
  MemoEditState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MemoEditState, MemoEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MemoEditState, MemoEditState>,
              MemoEditState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
