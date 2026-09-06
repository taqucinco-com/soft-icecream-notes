// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serving_machine_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServingMachineFilter)
final servingMachineFilterProvider = ServingMachineFilterProvider._();

final class ServingMachineFilterProvider
    extends $NotifierProvider<ServingMachineFilter, String?> {
  ServingMachineFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servingMachineFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servingMachineFilterHash();

  @$internal
  @override
  ServingMachineFilter create() => ServingMachineFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$servingMachineFilterHash() =>
    r'c7c142a1bbb1aac4b47fed52a23eddc39e893420';

abstract class _$ServingMachineFilter extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
