// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// data層（Google Places実装）が用意されるまでの間はモック実装をDIする。
/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。

@ProviderFor(storeSearchRepository)
final storeSearchRepositoryProvider = StoreSearchRepositoryProvider._();

/// data層（Google Places実装）が用意されるまでの間はモック実装をDIする。
/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。

final class StoreSearchRepositoryProvider
    extends
        $FunctionalProvider<
          StoreSearchRepository,
          StoreSearchRepository,
          StoreSearchRepository
        >
    with $Provider<StoreSearchRepository> {
  /// data層（Google Places実装）が用意されるまでの間はモック実装をDIする。
  /// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。
  StoreSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storeSearchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storeSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<StoreSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StoreSearchRepository create(Ref ref) {
    return storeSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoreSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoreSearchRepository>(value),
    );
  }
}

String _$storeSearchRepositoryHash() =>
    r'e7ca7401adb6be6146b822941afd1bd1020f069b';
