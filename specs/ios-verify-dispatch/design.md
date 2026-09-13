# アーキテクチャ概要

既存の `claude.yml`（ubuntu-latest、`@claude` メンションで起動）はそのまま維持しつつ、以下を追加する。

```
[@claudeメンション: issue_comment / pull_request_review_comment / pull_request_review / issues]
                 │
                 ▼
        claude.yml (ubuntu-latest)
   ┌───────────────────────────────────┐
   │ 1. [ui-verify]タグ判定 (既存・不変)  │→ true → Androidエミュレータ検証 (既存)
   │ 2. `ios-verify-judge`agentをTaskで  │
   │    呼び出し、iOS要否を判断 (新規)    │
   └───────────────────────────────────┘
                 │ iOS確認が必要と判断
                 ▼
   `gh workflow run claude-ios.yaml --ref develop -f ...`
                 │ (workflow_dispatch)
                 ▼
        claude-ios.yaml (macos-26, 新規)
   ┌───────────────────────────────────┐
   │ inputで渡されたhead_refをcheckout   │
   │ iOS Simulator起動 + idb-companion   │
   │ Claude Codeを新規CI向けiOSスキルで  │
   │ 実行し、検証・コメント・artifact投稿│
   └───────────────────────────────────┘
```

`[ui-verify]`（Android）とiOSの意味的判断は独立に評価され、両方成立すれば両方が実行される（要件6）。iOS Simulatorの起動にはmacOSランナーが必須のため、`claude.yml`と`claude-ios.yaml`は別ジョブではなく別ワークフローとして分離し、`workflow_dispatch`でつなぐ。両ワークフローは非同期に完了し、それぞれが自分の担当範囲についてPR/Issueコメントを残す（要件3, 8）。

判断ロジックと実行手順（起動コマンド・コメント投稿）は責務を分離する。本リポジトリには既に `spec-reviewer`（`.claude/agents/spec-reviewer.md`）という「判定のみを行い、副作用のある操作は一切行わない専任agent」の前例があり、これに倣う。iOS確認要否の判断は新規agent `ios-verify-judge`（Read/Grep/Globのみ、`Bash`無し）に切り出し、`claude.yml`側のClaudeがTaskツールで呼び出して判定結果（要否・理由）を受け取る。実際に`gh workflow run`を実行する手順は、判定結果を受け取った`claude.yml`側のClaude自身が`ios-verify-dispatch`skillに従って行う（skill自体はagentを呼び出す手順込みで記述する）。

# コンポーネント/モジュール構成

## 1. `CLAUDE.md` への追記

「GitHub Actions（@claudeメンション）での応答ルール」節に、iOS Simulator確認要否の判断ルールを追記する。判断基準の詳細は新規agent（2.）に、`gh workflow run`の具体的な実行手順は新規skill（3.）に切り出し、CLAUDE.md側は「`ios-verify-dispatch`skillの手順に従い、iOS Simulatorでの確認要否を判断した上で必要なら`claude-ios.yaml`を起動すること」という誘導のみを記述する。既存の「GitHub Actions応答ルール」（最終コメント必須等）とも整合させる。

## 2. 新規agent: `ios-verify-judge`（判断専任）

`spec-reviewer`agentと同じ設計思想（判定のみ・副作用ゼロ）に倣う専任agent。`tools: Read, Grep, Glob`のみを持たせ、`Bash`・`gh`等の実行手段は一切与えない。

- 入力: `claude.yml`側のClaudeがTaskツール経由で渡す、依頼元コメント本文（と、必要に応じて変更内容の要約）。
- 判断基準: 依頼文がiOSプラットフォーム固有の見た目・挙動（iOS特有のUIコンポーネント、Cupertino系ウィジェット、iOS版のみで発生している不具合報告、「iOSで確認して」等の明示的な言及、Figmaワイヤーフレームとの一致確認でプラットフォーム区別がある場合 等）に触れているかどうかを判断基準の例として示す。`[ui-verify]`タグの有無はこの判断に影響しない（要件6）。
- 出力: 「要否（true/false）」と「判断理由」を明確な形式（例: `必要: true/false` + 理由の文章）で返す。ファイルの編集や外部コマンドの実行は行わない。

## 3. 新規skill: `ios-verify-dispatch`（起動用）

`claude.yml`のジョブ内で読み込まれ、以下を提供する。

- `ios-verify-judge`agentをTaskツールで呼び出す手順（渡すべき入力・受け取る出力形式）。
- 要否が`true`の場合の起動手順: `gh workflow run claude-ios.yaml --ref develop -f ...` の具体的なコマンド（4.のデータモデル参照）。判断理由は`ios-verify-judge`の出力をそのまま`judged_reason`として利用する。
- 起動成功時・失敗時それぞれで、PR/Issueコメントに残すべき文面のガイド（要件3, 4）。

## 4. 新規skill: `flutter-ui-ios-verify-ci`（CI環境向けiOS検証実行用）

Android版 `flutter-ui-verify-ci` のiOS版。`claude-ios.yaml`内のClaude Codeから読み込まれる。

- 起動手順（CI固有）: `ios_simulator_idb_dry_run.yaml`の手順（シミュレータ作成・起動、`brew`経由の`idb-companion`/`idb-cli`インストール、`idb connect`、`idb ui describe-all`での起動確認）と`ios_simulator_dry_run.yaml`の手順（CocoaPods、Flutterセットアップ、`.env.local`生成）を統合したものを土台にする。
- タップ操作・要素ツリー取得・スクリーンショット撮影・VLMによる評価: `flutter-ui-ios-verify`スキルの1〜7節をそのまま参照し、CI固有の差分（スクリーンショット保存先を`work/screenshots/`にする、`fvm`を使わずCIにインストールされた`flutter`をそのまま使う 等）だけを`flutter-ui-verify-ci`スキルに倣って明記する。評価基準・JSON形式そのものは重複定義しない。

## 5. `claude.yml` の変更点

- `permissions.actions` を `read` → `write` に変更する（`gh workflow run`によるworkflow_dispatch実行に必要）。
- `Run Claude Code`ステップの `additional_permissions` にも `actions: write` を反映する（Claudeに払い出されるトークンのスコープ）。
- `claude_args`の`--allowedTools`に`Bash(gh workflow run:*)`を追加する。`Task`は既に許可済みなので、`ios-verify-judge`agentの呼び出しに追加変更は不要。
- ワークフローYAML側での機械的な条件分岐は追加しない。iOS要否の判断は`ios-verify-judge`agentに委ね、Android版の`steps.ui_verify`のような`if`ゲートに相当するものはiOS側には作らない。

## 6. 新規ファイル: `.github/workflows/claude-ios.yaml`

- トリガー: `workflow_dispatch`のみ（`claude.yml`からの起動専用。人手からの手動実行も可能だが、通常は`claude.yml`経由）。
- `runs-on: macos-26`（`idb-companion`のHomebrewインストール要件のため。`ios_simulator_idb_dry_run.yaml`と同じ制約）。
- 手順の骨格:
  1. `actions/checkout@v4`を`ref: ${{ inputs.head_ref }}`で実行（4.参照）。
  2. `mobile/.env.local`生成（既存2ワークフローと同じ`sed`手順）。
  3. Ruby/CocoaPods、Pub cache、Flutterセットアップ、`flutter pub get`・codegen（`ios_simulator_dry_run.yaml`を踏襲）。
  4. `pod install`。
  5. iOS Simulator作成・起動、`idb-companion`/`idb-cli`インストール、`idb connect`、UI読み取り確認まで（`ios_simulator_idb_dry_run.yaml`を踏襲）。
  6. `anthropics/claude-code-action@v1`を実行。`prompt`に、inputから復元した「元の依頼内容」「`claude.yml`側（`ios-verify-judge`agent）の判断理由」を埋め込み、`flutter-ui-ios-verify-ci`スキルを使ってiOS Simulator上で検証するよう指示する。
  7. スクリーンショット等の成果物を`work/screenshots/`から`actions/upload-artifact@v4`でアップロード（既存Android側と同じ命名パターン）。
  8. 完了時、`target_type`/`target_number`に応じて`gh pr comment`または`gh issue comment`で、依頼の完了状況（完了/未完了とその理由）を投稿する（要件8, CLAUDE.mdのGitHub Actions応答ルール準拠）。

# データモデル・API/インターフェース

## `claude-ios.yaml` の `workflow_dispatch.inputs`

| 入力名 | 型 | 内容 |
|---|---|---|
| `target_type` | string (`pr` \| `issue`) | 結果をコメントする先がPRかIssueか |
| `target_number` | string | PR番号またはIssue番号 |
| `head_ref` | string | チェックアウト対象のブランチ名（PRのhead ref） |
| `original_request_b64` | string | 依頼元コメント本文（改行・引用符を含みうるためbase64エンコードして渡す） |
| `judged_reason_b64` | string | `claude.yml`側でiOS確認が必要と判断した理由・そこまでの調査結果（同様にbase64エンコード） |

`workflow_dispatch`のinput値はシェル経由でCLIに渡す都合上、改行やダブルクォートを含む文字列をそのまま渡すと壊れやすい。そのため本文系の2項目はbase64エンコードして渡し、`claude-ios.yaml`側の該当ステップで`base64 -d`してから`claude_args`の`prompt`に埋め込む。

## `ios-verify-judge`agentの呼び出しインターフェース

`claude.yml`側のClaudeが`Task`ツールで`subagent_type: ios-verify-judge`を指定して呼び出す。

- 入力（Taskの`prompt`）: 依頼元コメント本文をそのまま渡す。必要であれば、確認対象のPR/Issueで何が変更されたかの要約も添える。
- 出力（agentの応答）: 「必要: true」または「必要: false」を先頭に明記し、続けて判断理由を文章で述べる形式に統一する。`claude.yml`側のClaudeはこの文字列をパースして分岐し、`true`の場合は理由部分をそのまま`judged_reason`として次工程（`ios-verify-dispatch`skillの起動手順）に渡す。

## `claude.yml` → `claude-ios.yaml` 起動コマンド（`ios-verify-dispatch`スキルに実装として記載）

```bash
gh workflow run claude-ios.yaml \
  --ref develop \
  -f target_type="pr" \
  -f target_number="123" \
  -f head_ref="feat/xxx" \
  -f original_request_b64="$(base64 <<< "$ORIGINAL_REQUEST")" \
  -f judged_reason_b64="$(base64 <<< "$JUDGED_REASON")"
```

`--ref develop`固定とすることで、`claude-ios.yaml`自体がまだ存在しないPRブランチからでも確実に起動できる（ユーザー承認済みの設計判断）。実際に検証すべきブランチは`head_ref`で別途渡し、`claude-ios.yaml`内の`actions/checkout`で明示的にそのrefをチェックアウトする。

# 各要件と設計要素の対応関係（トレーサビリティ）

| 要件 | 対応する設計要素 |
|---|---|
| 1. iOS確認要否の判断→`claude-ios.yaml`起動 | コンポーネント2（`ios-verify-judge`agent）、コンポーネント3（`ios-verify-dispatch`skill）、CLAUDE.md追記 |
| 2. 起動時に渡す情報 | データモデル（`workflow_dispatch.inputs`） |
| 3. 起動成功時のコメントとターン終了 | コンポーネント3（skill内のコメント文面ガイド） |
| 4. 起動失敗時のコメント | コンポーネント3（skill内のコメント文面ガイド） |
| 5. 不要判断時は既存挙動維持 | コンポーネント5（ワークフローYAML自体は不変、判断は`ios-verify-judge`agentのみ） |
| 6. `[ui-verify]`とiOS判断の独立性 | アーキテクチャ概要の図、コンポーネント2の判断基準 |
| 7. `claude-ios.yaml`起動時のcheckout・Simulator起動 | コンポーネント6の手順1, 5 |
| 8. CI向けiOS検証skillの使用 | コンポーネント4（`flutter-ui-ios-verify-ci`） |
| 9. 実行完了時のコメント義務 | コンポーネント6の手順8 |
| 10. 成果物のartifactアップロード | コンポーネント6の手順7 |

# 検討したが採用しなかった代替案・既知のリスク

## 代替案

- **`repository_dispatch`での連携**: `workflow_dispatch`はGitHub上のUIからの手動再実行や入力スキーマの型指定ができる点で扱いやすく、`gh workflow run`とも相性が良いため不採用にはしなかったが、`repository_dispatch`は任意のペイロード(JSON)を渡せる自由度がある。今回は入力項目が固定的で少数のため、シンプルな`workflow_dispatch`を採用した。
- **PRブランチ自体をrefにして起動**: ユーザー確認の結果、`claude-ios.yaml`がまだ存在しない既存PRブランチでも動作させるため不採用。
- **`macos-15` + `simctl`のみでのタップなし検証**: ユーザー確認の結果、Android版と同水準のタップ操作込み検証を優先し、`idb-companion`が要求する`macos-26`を採用。
- **明示タグ`[ios-verify]`の新設**: 要件定義時点でスコープ外と確認済み。Claudeの意味的判断のみで運用する。
- **`claude.yml`側で`claude-ios.yaml`の完了を待ち合わせる**: 要件定義時点でスコープ外と確認済み。実装が複雑化し、`claude.yml`の`timeout-minutes: 45`にiOS側の実行時間も収める必要が生じるため不採用。
- **判断ロジックをskillに直接記述する（agentに分離しない）**: 初期設計ではこの方式だったが、ユーザー指摘によりレビュー・変更した。判断（副作用ゼロであるべき）と実行（`gh workflow run`という副作用を伴う操作）が1つのファイルに同居すると、判断基準だけを見直したい時に実行手順まで一緒に扱うことになり、また判断agentに実行権限を渡す必然性もない。既存の`spec-reviewer`agent（判定専任・`Bash`無し）という前例があることから、同じ設計思想で`ios-verify-judge`agentに判断を分離し、`ios-verify-dispatch`skillは実行手順（agent呼び出し＋`gh workflow run`）に専念する形に変更した。

## 既知のリスク

- **フォーク由来のPRでの動作**: フォークからのPRでは`GITHUB_TOKEN`の権限が制限され、`secrets`も既定では渡らないため、`gh workflow run`自体が失敗しうる。既存の`claude.yml`も同様の前提（内部コントリビュータ想定）に立っており、本機能もその前提を踏襲する。
- **`workflow_dispatch`のinput文字数制限**: GitHub Actionsの`workflow_dispatch` inputには実用上の長さ制限がある。コメント本文が非常に長い場合、`original_request_b64`が切り詰められる可能性があり、その場合は要約して渡すなどの対応が実装時に必要になる。
- **`idb-companion`のインストール不安定性**: `ios_simulator_idb_dry_run.yaml`のコメントにある通り、Homebrewの非公式タップ経由のインストールで`brew trust`の要否がバージョンによって変わるなど、将来的なランナーイメージ更新で壊れる可能性がある。
- **`[ui-verify]`とiOS判断の同時成立**: 要件6により両立を許容する設計としたが、実際に両方が真になるケース（Android・iOS両方の確認を1つの依頼で求められる場合）のテストケースは`tasks.md`で明示的に確保する必要がある。
- **判断基準の主観性**: 「iOS確認が必要か」はキーワード一致ではなくClaudeの意味的判断に委ねるため、判断がぶれる（過剰起動・見送りの双方）可能性がある。判断基準の例示（コンポーネント2）を継続的に調整する運用が前提になる。
