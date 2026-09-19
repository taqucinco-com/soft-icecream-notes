@AGENTS.md

# CLAUDE.md

Claude Code固有のルール。プロジェクト概要やツールに依存しない共通ルール（言語ルール、Dartコーディングスタイル等）は [AGENTS.md](./AGENTS.md) を参照。

## 仕様駆動開発のルール

新機能や仕様変更を行う際は、コードに着手する前に以下のフローに従うこと。

1. `/spec-init <feature-name> <一行概要>` — `specs/<feature-name>/` を作成する
2. `/spec-requirements <feature-name>` — 要件定義書 (`requirements.md`) を作成する
3. `/spec-design <feature-name>` — 技術設計書 (`design.md`) を作成する
4. `/spec-tasks <feature-name>` — 設計をタスクリスト (`tasks.md`) に分解する
5. `/spec-implement <feature-name> [task番号]` — タスクを1つずつ実装する

運用ルール:

- 各フェーズは、前フェーズの内容についてユーザーの承認を得てからでないと次に進まない。
- 要件・設計上の曖昧な点は推測で埋めず、必ずユーザーに確認する。
- `specs/` 以下の仕様書はコードと同様にレビュー・コミット対象として扱う。
- 実装フェーズでは一度に1タスクのみ着手し、完了ごとに `tasks.md` を更新する。
- 上記のフェーズごとの承認は対話セッションを前提としている。GitHub Actions上の`@claude`メンションのような、フェーズごとの往復ができない非対話ターンでは、代わりに`spec-driven-development-ci`skillの基準に従う。
- `specs/adr/`は例外で、機能仕様（`specs/<feature-name>/`、requirements.md/design.md/tasks.mdの3点セット）ではなくADR（Architecture Decision Record）専用のディレクトリ。単一機能に閉じない横断的な設計判断を`specs/adr/NNNN-<slug>.md`として記録する（例: [`specs/adr/0001-work-directory-per-module-subdirectory.md`](./specs/adr/0001-work-directory-per-module-subdirectory.md)）。上記のフロー・3点セットの構造には従わない。

## コメント・ドキュメント記述のルール

コード内のコメント、スクリプト、ドキュメント（スキル定義等）では現在の状態と「なぜそう書いているのか」だけを記載する。過去に発生した不具合、その背景、学習・検討過程は記載しない。過去の経験や判断根拠が記録価値の高い場合は、代わりに`specs/adr/`にADR（Architecture Decision Record）として記録する。

例：
- ❌ `.ci-tmp/`にマーカーを置く。PR #82で/tmpへの書き込みがブロックされて無限ループが発生したため`
- ✅ `.ci-tmp/`にマーカーを置く。Bashツールのサンドボックスは作業ディレクトリとセッション専用$TMPDIRにのみ書き込みを許可する仕様のため`

技術的な根拠がある場合（仕様・実装の参照等）はURLやドキュメント参照として残す。ADRはこのプロジェクトの過去の判断・経験を記録する一次情報源となる。

## GitHub Actions（@claudeメンション）での応答ルール

### モデル選択の自動化

`claude.yml`では、依頼内容の複雑度を自動判定して最適なモデルを選択する仕組みが実装されている。

- **判定エージェント**: `task-complexity-judger`が、PR/Issueコメント の依頼内容を解析し、タスクの複雑度（Simple/Standard/Advanced）を判定する。
- **モデル選択**: 判定結果に基づいて、Haiku（シンプル）/ Sonnet（標準）/ Opus（複雑）を自動選択。
- **フォールバック**: 判定失敗時はSonnetをデフォルトで使用。

判定基準は `.claude/agents/task-complexity-judger.md` に記載。

### 応答ルール

- `@claude`メンションでの依頼をGitHub Actions上で処理する場合、ターンを終える前に必ず「依頼された作業がどこまで完了したか、完了できなかった場合は何が原因でどこまで進んだか」を明記した結論をPR/Issueのコメントとして残すこと。
- 進行中のチェックリスト（`- [ ]`等）を更新しただけの状態でターンを終えてはならない。チェックリストが未完了のまま終わる場合は、その理由（権限拒否・ビルド失敗など）と次にすべきことを文章で明示すること。**例外**: `claude-android.yaml`/`claude-ios.yaml`へ検証を引き継いだ項目は、別workflowへの引き継ぎであり放置ではないため、未完了（`- [ ]`）のまま最終応答としてよい。
- GitHub Actionsのjobが成功（緑）で終わることと、依頼されたタスクを完了できたことは別である。job成功はClaudeのプロセスがエラー無く終了しただけを意味し、タスクの成否はこの最終コメントでのみ人間に伝わる。
- `claude.yml`で依頼を処理する際は、`android-emu-verify-dispatch`/`ios-sim-verify-dispatch`両スキルの手順に従い、Android Emulator・iOS Simulatorそれぞれでの確認要否を独立に判断すること。必要と判断した場合はそれぞれ`.github/workflows/claude-android.yaml`/`.github/workflows/claude-ios.yaml`をworkflow_dispatchで起動する。`[ui-verify]`タグはプラットフォーム不問の汎用シグナルであり、プラットフォームが依頼文から特定できない場合はコストの安いAndroidをデフォルトとする。両方に該当する依頼であれば両方の検証を行う。
- 依頼内容が新機能の追加や既存機能の仕様変更を伴う場合は、実装に着手する前に`spec-driven-development-ci`skillの手順に従うこと。`spec-change-escalation-checker`agentが仕様変更の種類（追加/削除/既存仕様との矛盾）と影響範囲を判定し、影響が限定的な追加・削除（例: 既存のデータモデルやドメイン層に触れず単一画面に閉じる変更）は自動で仕様書更新・実装まで進めてよいが、想定外の影響が懸念される追加・削除（例: データモデルの変更や複数画面にまたがる変更）や既存仕様との矛盾は実装に着手せず、提案内容を最終応答に含めて人間の承認を待つ。
- `claude.yml`/`claude-android.yaml`/`claude-ios.yaml`いずれのターンでも、最後に必ず`gh pr comment`/`gh issue comment`で起動元コメントへの返信を投稿すること（自動投稿には頼らない）。GitHubのIssue/PRコメントに本来のスレッド返信機能が無いことを踏まえ、コメント本文の先頭に起動元コメントへの引用・リンク（`> 起動元コメントへの返信: <パーマリンク>`）を入れ、返信であることが分かる形にする。
- GitHub Actions上でAgentツールによりサブエージェント（`android-pr-emu-need-checker`/`ios-pr-sim-need-checker`/`ui-checker`/`spec-change-escalation-checker`等）を呼び出す際は、必ず同期的に（`run_in_background: false`を指定して）呼び出すこと。バックグラウンド（非同期）呼び出しは使わない。非対話的なCIの単発セッションには後続ターンが無く、非同期呼び出しの完了通知を受け取れる機会が無いため、判定結果を使えないままターンが終わってしまう（実際にこの事故が発生し、`ui-checker`の判定を一度も使えないまま完了報告コメントが投稿されずに終わった）。
