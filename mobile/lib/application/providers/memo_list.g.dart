// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_list.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memoList)
final memoListProvider = MemoListProvider._();

final class MemoListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Memo>>,
          List<Memo>,
          Stream<List<Memo>>
        >
    with $FutureModifier<List<Memo>>, $StreamProvider<List<Memo>> {
  MemoListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoListHash();

  @$internal
  @override
  $StreamProviderElement<List<Memo>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Memo>> create(Ref ref) {
    return memoList(ref);
  }
}

String _$memoListHash() => r'a34e1546842596eb72f99c4306637d94e936e90f';
