import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/mock/mock_memo_repository.dart';
import '../../domain/repositories/memo_repository.dart';

part 'repository_providers.g.dart';

/// data層（drift実装）が用意されるまでの間はモック実装をDIする。
/// アプリ全体で使い回すシングルトンとして扱うため`keepAlive: true`とする。
@Riverpod(keepAlive: true)
MemoRepository memoRepository(Ref ref) => MockMemoRepository();
