import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/mock/mock_memo_repository.dart';
import '../../data/mock/mock_profile_repository.dart';
import '../../data/mock/mock_store_search_repository.dart';
import '../../domain/repositories/memo_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/store_search_repository.dart';

part 'repository_providers.g.dart';

/// data層（drift実装）が用意されるまでの間はモック実装をDIする。
/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。
@Riverpod(keepAlive: true)
MemoRepository memoRepository(Ref ref) => MockMemoRepository();

@Riverpod(keepAlive: true)
StoreSearchRepository storeSearchRepository(Ref ref) =>
    MockStoreSearchRepository();

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => MockProfileRepository();
