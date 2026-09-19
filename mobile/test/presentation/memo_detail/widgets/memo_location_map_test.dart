import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:icecream_log/features/memo/domain/entities/memo.dart';
import 'package:icecream_log/presentation/memo_detail/widgets/memo_location_map.dart';

void main() {
  testWidgets('位置情報を持つメモではスケルトン表示後にGoogleMapが表示される', (tester) async {
    const memo = Memo(id: '1', latitude: 35.6586, longitude: 139.7454);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MemoLocationMap(memo: memo))),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(GoogleMap), findsOneWidget);
  });

  testWidgets('位置情報が無いメモではその旨のメッセージが表示される', (tester) async {
    const memo = Memo(id: '2');

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MemoLocationMap(memo: memo))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GoogleMap), findsNothing);
    expect(find.text('位置情報がありません'), findsOneWidget);
  });
}
