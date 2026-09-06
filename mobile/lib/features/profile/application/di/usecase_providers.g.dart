// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usecase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(saveProfileUseCase)
final saveProfileUseCaseProvider = SaveProfileUseCaseProvider._();

final class SaveProfileUseCaseProvider
    extends
        $FunctionalProvider<
          SaveProfileUseCase,
          SaveProfileUseCase,
          SaveProfileUseCase
        >
    with $Provider<SaveProfileUseCase> {
  SaveProfileUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveProfileUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveProfileUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveProfileUseCase create(Ref ref) {
    return saveProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveProfileUseCase>(value),
    );
  }
}

String _$saveProfileUseCaseHash() =>
    r'894e8b434156649c0e4355ed2ed275e84776cc20';

@ProviderFor(watchProfileUseCase)
final watchProfileUseCaseProvider = WatchProfileUseCaseProvider._();

final class WatchProfileUseCaseProvider
    extends
        $FunctionalProvider<
          WatchProfileUseCase,
          WatchProfileUseCase,
          WatchProfileUseCase
        >
    with $Provider<WatchProfileUseCase> {
  WatchProfileUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchProfileUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchProfileUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchProfileUseCase create(Ref ref) {
    return watchProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchProfileUseCase>(value),
    );
  }
}

String _$watchProfileUseCaseHash() =>
    r'553692dd015af7a4863324f7f41ec0481d1de2bd';
