import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/memo/application/providers/view_mode.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'widgets/serving_machine_filter_bar.dart';
import 'widgets/view_toggle.dart';

/// 「メモ一覧」ブランチのルート画面（Figma 01/02フレーム）。
/// [ViewToggle]でリスト/マップを切り替える。
class NotesTabScreen extends ConsumerWidget {
  const NotesTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(viewModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ一覧'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: ViewToggle()),
        ],
      ),
      body: Column(
        children: [
          const ServingMachineFilterBar(),
          const Divider(height: 1),
          Expanded(
            child: mode == NotesViewMode.list
                ? const ListScreen()
                : const MapScreen(),
          ),
        ],
      ),
    );
  }
}
