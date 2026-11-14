# Review Guidelines

コードレビュー用のガイドライン。プロジェクト概要と共通ルールは [AGENTS.md](./AGENTS.md)、Claude Code固有のルールは [CLAUDE.md](./CLAUDE.md) を参照。

## 言語

レビューコメントはすべて日本語で書くこと。コード上の識別子は対象外。

## 指摘しないこと

- Dartの[dot shorthand構文](https://dart.dev/language/dot-shorthands)（`.fromSeed(...)` のように型名を省略する記法）は意図したスタイルであり、コンパイルエラーではない。指摘しない。
- 自動生成ファイル（`*.g.dart`、`*.freezed.dart`、`pubspec.lock`、`mobile/ios/Podfile.lock` 等）の中身。
- `.devin/skills/`、`.devin/agents/`、`.agents/skills/` 配下のシンボリックリンクと、`.devin/mcp_config.json`（`.mcp.json` へのシンボリックリンク）。実体は `.claude/skills/`、`.claude/agents/`、`.mcp.json` にあり、そちらをレビュー対象とする。
- `.codex/agents/*.toml` のプロンプト本文。`.claude/agents/*.md` から `.codex/scripts/sync-agents.py` で生成されるため、内容の重複は指摘しない。元の md との差分は下記の「他ツールへの派生」で確認する。

## 重点的に確認する領域

### 仕様駆動開発（specs/）

- 新機能・仕様変更のPRで、`specs/<feature-name>/` の `requirements.md` / `design.md` / `tasks.md` がコードと整合しているか。
- 仕様書は現在の状態だけを記述しているか。変更履歴や経緯が混ざっていないか。
- `specs/adr/` のファイル名が `yyyyMMddHHmm-<slug>.md` 形式か。

### コメント・ドキュメント

- コード内コメント、スクリプト、SKILL.md等に、過去の不具合・背景・検討過程が書かれていないか。現在の状態と「なぜそう書いているのか」だけを書く。記録すべき経緯は `specs/adr/` のADRに書く。
- GitHub Actionsのworkflow YAMLに、説明目的のコメントが追加されていないか。

### Flutterアプリ（mobile/）

- 型が推論できる箇所でdot shorthandを使っているか（使っていなくても指摘は不要だが、新規コードでは推奨）。
- ドメイン層・データモデルの変更が、`specs/` の設計と矛盾していないか。
- 変更に対応するテスト（`mobile/test/`、`mobile/integration_test/`）が追加・更新されているか。

### GitHub Actions・Claude設定（.github/、.claude/）

- workflowの権限（`permissions`）を広げる変更は、必要な理由が明確か。
- `.claude/settings*.json` やhooksの変更で、許可範囲が意図せず広がっていないか。
- `@claude` 応答まわりの変更は、CLAUDE.mdの「GitHub Actions（@claudeメンション）での応答ルール」と矛盾していないか。

### 他ツール（Devin・Codex）への派生

`.claude/` を実体とし、DevinとCodexの設定はそこから派生させる（詳細は [AGENTS.md](./AGENTS.md) の「Devin・Codex連携」）。

- `.claude/agents/*.md` を変更したPRで、`python3 -I .codex/scripts/sync-agents.py --check` が差分なしで通る状態か（`.codex/agents/*.toml` が再生成されているか）。
- `.claude/skills/` にスキルを追加したPRで、`.devin/skills/` と `.agents/skills/` に対応するシンボリックリンクがあるか。`.claude/agents/` への追加も同様に `.devin/agents/` を確認する。
- `.devin/skills/`、`.devin/agents/`、`.agents/skills/` の各エントリと `.devin/mcp_config.json` が、コピーではなくシンボリックリンクのままか。
- `.claude/settings.json` の `permissions.deny` を変更したPRで、`.devin/config.json`、`.codex/config.toml`、`.codex/rules/deny.rules` が同じ内容に更新されているか。

## セキュリティ

- `.env`、トークン、APIキー、AWS認証情報などの秘密情報がコミットされていないか。`.env.sample` にはダミー値のみを置く。
- workflowでPR/Issueコメント等の外部入力をシェルに直接埋め込んでいないか（コマンドインジェクション）。
