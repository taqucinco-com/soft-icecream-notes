import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/mock/mock_store_search_repository.dart';
import '../../domain/repositories/store_search_repository.dart';

part 'repository_providers.g.dart';

/// data層（Google Places実装）が用意されるまでの間はモック実装をDIする。
/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。
@Riverpod(keepAlive: true)
StoreSearchRepository storeSearchRepository(Ref ref) =>
    MockStoreSearchRepository();
