import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:icecream_log/features/profile/application/di/usecase_providers.dart';
import 'package:icecream_log/features/profile/application/providers/app_version.dart';
import 'package:icecream_log/features/profile/application/providers/profile.dart';
import 'package:icecream_log/features/profile/domain/entities/user_profile.dart';

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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('アイコン変更機能は今後実装予定です')));
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('読み込みに失敗しました: $error')),
      ),
    );
  }
}

class _SettingsContent extends HookWidget {
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
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: profile.nickname);

    void submitNickname() {
      final trimmed = controller.text.trim();
      if (trimmed != profile.nickname) {
        onNicknameChanged(trimmed);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 44,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onChangeIconTap,
                child: const Text('アイコンを変更'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('ニックネーム', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => submitNickname(),
          onTapOutside: (_) => submitNickname(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('アプリバージョン'), Text(appVersion)],
        ),
        const Divider(height: 32),
      ],
    );
  }
}
