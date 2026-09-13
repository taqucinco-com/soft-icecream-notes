# タスク一覧

実施順に並んでいる。各タスクは1コミットで完結する粒度を想定する。

- [x] 1. 新規skill `.claude/skills/flutter-ui-ios-verify-ci/SKILL.md` を作成する（`flutter-ui-verify-ci`のiOS版。`ios_simulator_idb_dry_run.yaml`/`ios_simulator_dry_run.yaml`の手順を土台に、起動手順のみCI向けに記述し、タップ・要素取得・評価は`flutter-ui-ios-verify`の1〜7節を参照する形にする）
  - 対応: requirements.md #8 / design.md コンポーネント4

- [x] 2. 新規agent `.claude/agents/ios-verify-judge.md` を作成する（`spec-reviewer`agentに倣い`tools: Read, Grep, Glob`のみとし、`Bash`は持たせない。iOS Simulator確認要否の判断基準例と、「必要: true/false」＋理由を返す出力形式を明記する）
  - 対応: requirements.md #1, #6 / design.md コンポーネント2

- [x] 3. `.claude/skills/ios-verify-dispatch/SKILL.md` を修正する。判断基準の記述は`ios-verify-judge`agentに移したため削除し、代わりに(a) `Task`ツールで`ios-verify-judge`agentを呼び出す手順、(b) その出力（要否・理由）を元に`gh workflow run claude-ios.yaml --ref develop -f ...`を実行する具体的なコマンド、(c) 起動成功時・失敗時それぞれのPR/Issueコメント文面ガイドに書き換える
  - 対応: requirements.md #1, #2, #3, #4, #6 / design.md コンポーネント3、データモデル節

- [x] 4. `CLAUDE.md`の「GitHub Actions（@claudeメンション）での応答ルール」節に、`ios-verify-dispatch`skillの手順に従いiOS Simulator確認要否を判断した上で必要なら`claude-ios.yaml`を起動する旨のルールを追記する
  - 対応: requirements.md #1, #5, #6 / design.md コンポーネント1

- [x] 5. `.github/workflows/claude.yml`の`permissions.actions`を`read`から`write`に変更し、`Run Claude Code`ステップの`additional_permissions`にも`actions: write`を反映する
  - 対応: requirements.md #1, #2 / design.md コンポーネント5

- [x] 6. `.github/workflows/claude.yml`の`claude_args`の`--allowedTools`に`Bash(gh workflow run:*)`を追加する（`Task`は既に許可済み）
  - 対応: requirements.md #1 / design.md コンポーネント5

- [x] 7. 新規ファイル`.github/workflows/claude-ios.yaml`を作成し、`workflow_dispatch`トリガーと`inputs`（`target_type`, `target_number`, `head_ref`, `original_request_b64`, `judged_reason_b64`）、`runs-on: macos-26`、`inputs.head_ref`を対象にした`actions/checkout@v4`ステップまでを実装する
  - 対応: requirements.md #2, #7 / design.md コンポーネント6（手順1）、データモデル節

- [x] 8. `claude-ios.yaml`に`mobile/.env.local`生成、Ruby/CocoaPodsセットアップ、Pubキャッシュ、Flutterセットアップ（`.fvmrc`）、`flutter pub get`・codegen、`pod install`のステップを追加する（`ios_simulator_dry_run.yaml`の該当ステップを移植）
  - 対応: requirements.md #7 / design.md コンポーネント6（手順2〜4）

- [x] 9. `claude-ios.yaml`にiOS Simulatorの作成・起動、`idb-companion`/`idb-cli`のインストール、`idb connect`、UI読み取り確認までのステップを追加する（`ios_simulator_idb_dry_run.yaml`の該当ステップを移植）
  - 対応: requirements.md #7 / design.md コンポーネント6（手順5）

- [x] 10. `claude-ios.yaml`に`anthropics/claude-code-action@v1`実行ステップを追加する。`original_request_b64`/`judged_reason_b64`をデコードして`prompt`に埋め込み、`flutter-ui-ios-verify-ci`skillを使うよう指示する
  - 対応: requirements.md #2, #8 / design.md コンポーネント6（手順6）

- [x] 11. `claude-ios.yaml`に`work/screenshots/`配下の成果物を`actions/upload-artifact@v4`でアップロードするステップを追加する（`claude.yml`のAndroid側と同じ命名パターン）
  - 対応: requirements.md #10 / design.md コンポーネント6（手順7）

- [x] 12. `claude-ios.yaml`に、`target_type`/`target_number`に応じて`gh pr comment`または`gh issue comment`で完了状況（完了/未完了とその理由、artifactリンク）を投稿する最終ステップを追加する
  - 対応: requirements.md #9 / design.md コンポーネント6（手順8）

- [x] 13. `claude.yml`・`claude-ios.yaml`・agent・両skillの内容を通しで見直し、要件定義書の受け入れ条件1〜10を満たしているか確認する（`actionlint`等があれば構文チェックも行う）
  - 対応: requirements.md 全項目

- [ ] 14. ブランチをpushし、`gh workflow run claude-ios.yaml`で手動動作確認を行う（ユーザー確認の上で実施。Simulator起動・idb接続・Claude起動・コメント投稿までの一連の流れをログで確認する）
  - 対応: requirements.md #7, #8, #9, #10 の動作確認
