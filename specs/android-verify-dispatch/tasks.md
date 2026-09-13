# タスク一覧

実施順に並んでいる。各タスクは1コミットで完結する粒度を想定する。

## Android要否判定・起動

- [x] 1. 新規agent `.claude/agents/android-verify-judge.md` を作成する（`ios-verify-judge`と同じtools構成・出力形式。`[ui-verify]`タグとプラットフォーム不明時のAndroidデフォルトを判断基準に含める）
  - 対応: requirements.md #1, #8 / design.md コンポーネント1

- [x] 2. 新規skill `.claude/skills/android-verify-dispatch/SKILL.md` を作成する（`ios-verify-dispatch`と同じ構成・Issue #56の教訓を踏襲。呼び出しagentと起動先ワークフローのみAndroid向けに差し替え）
  - 対応: requirements.md #4, #5, #6, #7, #15 / design.md コンポーネント2

- [x] 3. 既存agent `.claude/agents/ios-verify-judge.md` を改修する（`[ui-verify]`タグをプラットフォーム不問の汎用シグナルとして扱い、プラットフォーム不明時はAndroidをデフォルトとしてiOS側はtrueにしないというコストバイアスを明記する）
  - 対応: requirements.md #8, #9 / design.md コンポーネント3

- [x] 4. 既存skill `.claude/skills/ios-verify-dispatch/SKILL.md` の判断基準に関する説明文を、Android版が対称に存在することが分かるよう軽微に更新する
  - 対応: design.md コンポーネント4

## claude-android.yaml（新規ワークフロー）

- [x] 5. 新規ファイル `.github/workflows/claude-android.yaml` を作成し、`workflow_dispatch`トリガーと`inputs`（`target_type`, `target_number`, `head_ref`, `original_request`, `judged_reason`。base64は使わない）、`runs-on: ubuntu-latest`、`inputs.head_ref`を対象にした`actions/checkout@v4`ステップまでを実装する
  - 対応: requirements.md #5, #10 / design.md コンポーネント5

- [x] 6. `claude-android.yaml`に`mobile/.env.local`生成ステップを追加する（既存`claude.yml`の該当ステップを移植）
  - 対応: requirements.md #10 / design.md コンポーネント5

- [x] 7. `claude-android.yaml`にJDK 17セットアップ、KVM有効化、Android SDKセットアップ、Gradle cache、AVD cache、stale lock除去、Debug Keystoreデコードのステップを追加する（既存`claude.yml`の該当ステップを移植）
  - 対応: requirements.md #10 / design.md コンポーネント5

- [x] 8. `claude-android.yaml`にFlutterセットアップ（fvm）、Dart build_runner cache、`flutter pub get`+codegen、codegen変更の破棄のステップを追加する（既存`claude.yml`の該当ステップを移植）
  - 対応: requirements.md #10, #12 / design.md コンポーネント5

- [x] 9. `claude-android.yaml`にAVD作成・起動確認（reactivecircus/android-emulator-runner）とエミュレータのバックグラウンド起動のステップを追加する（既存`claude.yml`の該当ステップを移植）
  - 対応: requirements.md #10 / design.md コンポーネント5

- [x] 10. `claude-android.yaml`に`anthropics/claude-code-action@v1`実行ステップを追加する。`${{ inputs.original_request }}`/`${{ inputs.judged_reason }}`をプロンプトに埋め込み、`flutter-ui-verify-ci`skillを使うよう指示し、Issue #56の教訓（単一コマンド・事前疎通確認禁止）を明記する。`--allowedTools`に`adb`/`flutter`/`dart`/`git commit`/`git push`/`gh pr comment`/`gh issue comment`等を許可する
  - 対応: requirements.md #11, #12, #15 / design.md コンポーネント5

- [x] 11. `claude-android.yaml`にスクリーンショットのartifactアップロード、成功時のリンクコメント、失敗時のエスカレーションコメントのステップを追加する（`claude-ios.yaml`と同じパターン）
  - 対応: requirements.md #13, #14 / design.md コンポーネント5

## claude.ymlの簡素化

- [x] 12. `.github/workflows/claude.yml`からAndroid Emulator関連ステップ（UI verify判定、`.env.local`生成、gh CLIアップグレード、JDK/KVM/Android SDK/Gradle cache/AVD cache/stale lock除去/Debug Keystore、AVD起動確認、エミュレータ起動、スクリーンショットアップロード、コメント投稿、エミュレータ停止）をすべて削除する
  - 対応: requirements.md #1 / design.md コンポーネント6

- [x] 13. `claude.yml`のFlutterセットアップ（fvm）、Dart build_runner cache、`flutter pub get`+codegen、codegen変更の破棄から`if`条件を外し、常時実行するステップにする
  - 対応: requirements.md #2 / design.md コンポーネント6

- [x] 14. `claude.yml`の`claude_args`の`--allowedTools`から`Bash(adb:*)`を削除する
  - 対応: design.md コンポーネント6

## UI検証ループ（ui-verify-judge）

- [x] 15. 新規agent `.claude/agents/ui-verify-judge.md` を作成する（`tools: Read`のみ。Android/iOS共通、`flutter-ui-verify`skill7節のチェックリスト・判定基準を移植し、`loop_verdict`(`pass`/`retry`/`fatal`)と`fatal_reason`を出力形式に追加する）
  - 対応: requirements.md #16, #18, #21 / design.md コンポーネント7

- [x] 16. `.claude/skills/flutter-ui-verify/SKILL.md`の7節を改修する。`ui-verify-judge`agentの呼び出し、`pass`/`retry`/`fatal`による分岐、イテレーションカウンタ（最大10回）によるループ制御を追加する（既存のチェックリスト・JSON形式は維持しつつ`loop_verdict`/`fatal_reason`を追加）
  - 対応: requirements.md #17, #19, #20, #22 / design.md コンポーネント8

- [x] 17. `.claude/skills/flutter-ui-verify-ci/SKILL.md`の7節への参照部分を、改修後の`flutter-ui-verify`7節（ループ導入後）を指すように確認・更新する
  - 対応: requirements.md #11, #16〜22 / design.md コンポーネント8

- [x] 18. `.claude/skills/flutter-ui-ios-verify/SKILL.md`の7節への参照部分を、改修後の`flutter-ui-verify`7節を指すように確認・更新する
  - 対応: requirements.md #16〜22 / design.md コンポーネント8

- [x] 19. `.claude/skills/flutter-ui-ios-verify-ci/SKILL.md`の7節への参照部分を、改修後の`flutter-ui-verify`7節を指すように確認・更新する
  - 対応: requirements.md #16〜22 / design.md コンポーネント8

## 仕上げ

- [x] 20. `claude.yml`・`claude-android.yaml`・`claude-ios.yaml`・新規agent2つ・改修skill6つの内容を通しで見直し、要件定義書の受け入れ条件1〜22を満たしているか確認する（`actionlint`等での構文チェックも行う）
  - 対応: requirements.md 全項目

- [ ] 21. ブランチをpushし、`gh workflow run claude-android.yaml`で手動動作確認を行う（ユーザー確認の上で実施）
  - 対応: requirements.md #10〜15 の動作確認
