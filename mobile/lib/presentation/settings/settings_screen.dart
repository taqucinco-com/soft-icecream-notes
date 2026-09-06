import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/application/di/usecase_providers.dart';
import '../../features/profile/application/providers/app_version.dart';
import '../../features/profile/application/providers/profile.dart';
import '../../features/profile/domain/entities/user_profile.dart';

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
          onNicknameChanged: (nickname) async {
            try {
              await ref.read(saveProfileUseCaseProvider)(
                profile.copyWith(nickname: nickname),
              );
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ニックネームの保存に失敗しました: $error')),
                );
              }
            }
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

  void _submitNickname() {
    final trimmed = _controller.text.trim();
    if (trimmed != widget.profile.nickname) {
      widget.onNicknameChanged(trimmed);
    }
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
          onSubmitted: (_) => _submitNickname(),
          onTapOutside: (_) => _submitNickname(),
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
