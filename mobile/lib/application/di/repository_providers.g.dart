// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// data層（drift実装）が用意されるまでの間はモック実装をDIする。
/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。

@ProviderFor(memoRepository)
final memoRepositoryProvider = MemoRepositoryProvider._();

/// data層（drift実装）が用意されるまでの間はモック実装をDIする。
/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。

final class MemoRepositoryProvider
    extends $FunctionalProvider<MemoRepository, MemoRepository, MemoRepository>
    with $Provider<MemoRepository> {
  /// data層（drift実装）が用意されるまでの間はモック実装をDIする。
  /// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。
  MemoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoRepository create(Ref ref) {
    return memoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoRepository>(value),
    );
  }
}

String _$memoRepositoryHash() => r'e8c6f8013c379b7e6e41b696633137837d838b08';

@ProviderFor(storeSearchRepository)
final storeSearchRepositoryProvider = StoreSearchRepositoryProvider._();

final class StoreSearchRepositoryProvider
    extends
        $FunctionalProvider<
          StoreSearchRepository,
          StoreSearchRepository,
          StoreSearchRepository
        >
    with $Provider<StoreSearchRepository> {
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

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'8d941d3ae802c8d0c9c05b51d02c00b3e0531055';
