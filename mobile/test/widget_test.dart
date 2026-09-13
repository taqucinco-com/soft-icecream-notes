import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icecream_log/main.dart';

void main() {
  testWidgets('起動するとメモ一覧タブにモックデータが表示される', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('メモ一覧'), findsWidgets);
    expect(find.text('ジェラテリア　テオブロマ'), findsOneWidget);
  });

  testWidgets('ボトムナビゲーションで設定タブに切り替えられる', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    expect(find.text('ニックネーム'), findsOneWidget);
  });
}
