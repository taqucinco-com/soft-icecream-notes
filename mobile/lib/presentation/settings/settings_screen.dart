import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/di/usecase_providers.dart';
import '../../application/providers/app_version.dart';
import '../../application/providers/profile.dart';
import '../../domain/entities/user_profile.dart';

/// Figma 05フレーム（設定）。ニックネーム編集・アイコン変更・アプリバージョン表示（REQ-9）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final appVersion = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: profileAsync.when(
        data: (profile) => _SettingsContent(
          profile: profile,
          appVersion: appVersion,
          onNicknameChanged: (nickname) {
            ref
                .read(saveProfileUseCaseProvider)(
                  profile.copyWith(nickname: nickname),
                );
          },
          onChangeIconTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('アイコン変更機能は今後実装予定です')),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('読み込みに失敗しました: $error')),
      ),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent({
    required this.profile,
    required this.appVersion,
    required this.onNicknameChanged,
    required this.onChangeIconTap,
  });

  final UserProfile profile;
  final String appVersion;
  final ValueChanged<String> onNicknameChanged;
  final VoidCallback onChangeIconTap;

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.profile.nickname,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 44,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onChangeIconTap,
                child: const Text('アイコンを変更'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('ニックネーム', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onSubmitted: widget.onNicknameChanged,
          onTapOutside: (_) => widget.onNicknameChanged(_controller.text),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('アプリバージョン'),
            Text(widget.appVersion),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }
}
