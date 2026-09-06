// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usecase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searchNearbyStoresUseCase)
final searchNearbyStoresUseCaseProvider = SearchNearbyStoresUseCaseProvider._();

final class SearchNearbyStoresUseCaseProvider
    extends
        $FunctionalProvider<
          SearchNearbyStoresUseCase,
          SearchNearbyStoresUseCase,
          SearchNearbyStoresUseCase
        >
    with $Provider<SearchNearbyStoresUseCase> {
  SearchNearbyStoresUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchNearbyStoresUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchNearbyStoresUseCaseHash();

  @$internal
  @override
  $ProviderElement<SearchNearbyStoresUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchNearbyStoresUseCase create(Ref ref) {
    return searchNearbyStoresUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchNearbyStoresUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchNearbyStoresUseCase>(value),
    );
  }
}

String _$searchNearbyStoresUseCaseHash() =>
    r'28038a6670ed3e13686a35c473d6331eacfa60d4';
