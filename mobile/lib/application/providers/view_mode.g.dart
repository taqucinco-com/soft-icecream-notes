// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ViewMode)
final viewModeProvider = ViewModeProvider._();

final class ViewModeProvider
    extends $NotifierProvider<ViewMode, NotesViewMode> {
  ViewModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewModeHash();

  @$internal
  @override
  ViewMode create() => ViewMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotesViewMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotesViewMode>(value),
    );
  }
}

String _$viewModeHash() => r'e5abf40ed3f625c17b2fe5cf90eb2c971afc4bfd';

abstract class _$ViewMode extends $Notifier<NotesViewMode> {
  NotesViewMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NotesViewMode, NotesViewMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotesViewMode, NotesViewMode>,
              NotesViewMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
