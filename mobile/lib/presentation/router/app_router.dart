import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../memo_detail/memo_detail_screen.dart';
import '../memo_edit/memo_edit_screen.dart';
import '../notes/notes_tab_screen.dart';
import '../settings/settings_screen.dart';
import '../shell/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/notes',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notes',
              builder: (context, state) => const NotesTabScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:memoId',
                  builder: (context, state) => MemoDetailScreen(
                    memoId: state.pathParameters['memoId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/memo/new',
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: MemoEditScreen(),
      ),
    ),
  ],
);
