// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usecase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(extractPhotoMetadataUseCase)
final extractPhotoMetadataUseCaseProvider =
    ExtractPhotoMetadataUseCaseProvider._();

final class ExtractPhotoMetadataUseCaseProvider
    extends
        $FunctionalProvider<
          ExtractPhotoMetadataUseCase,
          ExtractPhotoMetadataUseCase,
          ExtractPhotoMetadataUseCase
        >
    with $Provider<ExtractPhotoMetadataUseCase> {
  ExtractPhotoMetadataUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'extractPhotoMetadataUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$extractPhotoMetadataUseCaseHash();

  @$internal
  @override
  $ProviderElement<ExtractPhotoMetadataUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExtractPhotoMetadataUseCase create(Ref ref) {
    return extractPhotoMetadataUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExtractPhotoMetadataUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExtractPhotoMetadataUseCase>(value),
    );
  }
}

String _$extractPhotoMetadataUseCaseHash() =>
    r'd0739cd43befd031f31b446597677a42a48759e2';

@ProviderFor(saveMemoUseCase)
final saveMemoUseCaseProvider = SaveMemoUseCaseProvider._();

final class SaveMemoUseCaseProvider
    extends
        $FunctionalProvider<SaveMemoUseCase, SaveMemoUseCase, SaveMemoUseCase>
    with $Provider<SaveMemoUseCase> {
  SaveMemoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveMemoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveMemoUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveMemoUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SaveMemoUseCase create(Ref ref) {
    return saveMemoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveMemoUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveMemoUseCase>(value),
    );
  }
}

String _$saveMemoUseCaseHash() => r'd1d4cbdd822a310ffb7b141b8cb0e5cce6cf47fd';

@ProviderFor(watchMemosUseCase)
final watchMemosUseCaseProvider = WatchMemosUseCaseProvider._();

final class WatchMemosUseCaseProvider
    extends
        $FunctionalProvider<
          WatchMemosUseCase,
          WatchMemosUseCase,
          WatchMemosUseCase
        >
    with $Provider<WatchMemosUseCase> {
  WatchMemosUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchMemosUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchMemosUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchMemosUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchMemosUseCase create(Ref ref) {
    return watchMemosUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMemosUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchMemosUseCase>(value),
    );
  }
}

String _$watchMemosUseCaseHash() => r'7c877186e8c618584c3345812d45a79249208cfc';
