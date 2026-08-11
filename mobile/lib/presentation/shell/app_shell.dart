import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'bottom_nav_bar.dart';

/// go_routerの`StatefulShellRoute`のbuilderに渡すシェル。
/// 「メモ一覧」「設定」はタブとしてブランチを持つが、中央の「+」はブランチ化せず
/// フルスクリーンモーダル（/memo/new）を`push`する。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onCreateTap: () => context.push('/memo/new'),
      ),
    );
  }
}
