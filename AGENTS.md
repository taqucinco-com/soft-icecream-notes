# soft-icecream-notes

食べたソフトクリームの写真からメモを作成するアプリ。Claude Codeを利用したエージェントで「開発者自身がコードを作成しない」ための環境づくりをテーマに開発を行う実験的リポジトリ。

このファイルはAIエージェント向けの、ツールに依存しない共通ルールを記載する。Claude Code固有のルール（仕様駆動開発フロー、GitHub Actions連携など）は [CLAUDE.md](./CLAUDE.md) を参照。人間の開発者向けのセットアップ・運用手順は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照。

## 言語ルール

コードレビューコメントを含め、AIエージェントが生成する説明文・コメントはすべて日本語で書くこと。コード自体の識別子（変数名・関数名等）は対象外。

## Dartコーディングスタイル (mobile/)

- 型が文脈から推論できる場合は [dot shorthand構文](https://dart.dev/language/dot-shorthands)（`ColorScheme.fromSeed(...)` ではなく `.fromSeed(...)` のように書く記法。Dart 3.10以降の言語機能）を積極的に使う。コンストラクタ呼び出し・static member・enum値のいずれでも使用可。
- これはコンパイルエラーではなく意図したスタイルなので、コードレビューで指摘しないこと。

## AI agentが直接iOS Simulatorと対話する

`idb`/`simctl`によるiOS Simulatorの起動・タップ操作・スクリーンショット取得の具体的な手順は`flutter-ios-operate`スキル（`.claude/skills/flutter-ios-operate/SKILL.md`）が一次情報源。ここでは重複して定義しない（片方だけ更新されて食い違うのを避けるため）。事前に必要な`idb`のインストール等の環境構築は[CONTRIBUTING.md](./CONTRIBUTING.md)を参照。

Claude Codeに検証させる場合は`flutter-ui-ios-verify`スキル（`.claude/skills/flutter-ui-ios-verify/SKILL.md`）を使う。

## コメント・ドキュメント記述のルール

コード内のコメント、スクリプト、ドキュメント（SKILL.md等）では現在の状態と「なぜそう書いているのか」だけを記載する。過去に発生した不具合、その背景、学習・検討過程は記載しない。過去の経験や判断根拠が記録価値の高い場合は、代わりに`specs/adr/`にADR（Architecture Decision Record）として記録する。

例：
- ❌ `# /tmp/wd.xmlではなくwork/wd.xmlを使う。PR #82で/tmpへの書き込みがサンドボックスでブロックされる不具合が発生したため`
- ✅ `# work/wd.xmlに保存する。Bashツールのサンドボックスは作業ディレクトリとセッション専用$TMPDIRにのみ書き込みを許可する仕様のため（詳細は[ドキュメント](...)参照）`

技術的な根拠がある場合（仕様・実装の参照等）はURLやドキュメント参照として残す。

## ADR（Architecture Decision Record）

`specs/adr/`は、単一機能に閉じない横断的な設計判断をADRとして記録するディレクトリ。機能仕様（`specs/<feature-name>/`、requirements.md/design.md/tasks.mdの3点セット）とは別物で、仕様駆動開発のフローや3点セットの構造には従わない。

ファイル名は`yyyyMMddHHmm-<slug>.md`形式にする（例: [`specs/adr/202609191216-sandbox-filesystem-constraints.md`](./specs/adr/202609191216-sandbox-filesystem-constraints.md)）。連番（`0001`, `0002`, ...）ではなくタイムスタンプを使う理由は、複数の開発者が異なるブランチで並行開発する場合、マージ時に番号の競合が発生するのを回避するため。

## Devin・Codex連携の基本方針

Claude Codeの`.claude/`配下を実体（正）とし、DevinとCodexはそこから派生させる。Claude Codeの設定・ファイルは、DevinやCodexに対応するために変更しない。派生物は`.claude/`側を変更したときに更新する（下記の対応表のとおり）。

| `.claude/`の実体 | Devin | Codex |
|---|---|---|
| `skills/<name>/` | `.devin/skills/<name>`（シンボリックリンク） | `.agents/skills/<name>`（シンボリックリンク） |
| `agents/<name>.md` | `.devin/agents/<name>.md`（シンボリックリンク） | `.codex/agents/<name>.toml`（変換） |
| `rules/*.md` | 対応なし（Devinが読むか未確認。必要な指示は`AGENTS.md`に書く） | `.codex/hooks.json`のSessionStartフックで注入 |
| `settings.json`の`permissions.deny` | `.devin/config.json`（変換） | `.codex/config.toml`（パスのルール）、`.codex/rules/deny.rules`（コマンドのルール）（変換） |
| `settings.ci.json`のhooks | 対象外（CI専用） | 対象外（CI専用） |
| `.mcp.json` | Devinが直接読む | 未対応 |
| レビュー指針 | [REVIEW.md](./REVIEW.md) | [REVIEW.md](./REVIEW.md) |

### 指示の置き場所の判断

指示をどのファイルに書くかは、読み込むツールで決める。

| 指示の種類 | 置き場所 | 理由 |
|---|---|---|
| 全ツールで必要な共通ルール | `AGENTS.md` | Claude Code（`CLAUDE.md`の`@AGENTS.md`経由）、Codex、Devinのすべてが指示ファイルとして読む。`.claude/rules/`はDevinの読み込み対象に確認できていないため、Devinにも必要な指示は置かない。 |
| Claude Code固有のルール | `CLAUDE.md` | 他ツールは読まない。 |
| 特定のパスを扱うときだけ必要な指示（Claude Code・Codexで十分なもの） | `.claude/rules/*.md`（`paths`付き） | Claude Codeは一致するファイルを扱うときだけ読み込む。Codexは`.codex/hooks.json`のフックで注入する。 |
| 引数を取り、ユーザーが明示的に呼ぶ手順 | `.claude/skills/<name>/SKILL.md` | `.claude/commands/`は非推奨で、スキルが後継。Devin・Codexにもシンボリックリンクで共有できる。 |

### `.claude/commands/*.md`を`.claude/rules/`へ移行するときの変換

- frontmatterの`description`・`argument-hint`は削除し、`paths`を付ける。Claude Codeが`.claude/rules/`で読むfrontmatterは`paths`だけで、`paths`の無いルールは毎セッション読み込まれる。
- `paths`は、そのフェーズで扱うファイルに一致させる（例: `specs/*/design.md`）。対象のファイルがまだ存在しないフェーズのルールは自動では読み込まれないため、`CLAUDE.md`の手順から対象のルールを読むよう明示する。
- `$ARGUMENTS`は置換されないため、`<feature-name>`のようなプレースホルダに書き換える。
- `/コマンド名`で次の操作を案内していた文は、次のフェーズ名で案内する文に書き換える。
- `CLAUDE.md`や他のスキルが`/コマンド名`を参照している場合は、`.claude/rules/`のファイルへのリンクに置き換える。
- ルール内に「このコマンドでは〜を行わない」のような、他のルールと同時に読み込まれると矛盾する記述を残さない。同じ`paths`に一致するルールは同時に読み込まれる。

リファレンス（Claude Code）:

- [`.claude`ディレクトリ](https://code.claude.com/docs/ja/claude-directory)
- [Claude Code memory（`CLAUDE.md`・`.claude/rules`）](https://code.claude.com/docs/ja/memory)

## Devin連携

Devinはリポジトリ内の`.claude/`配下を読むため、skills・subagents・hooksの実体は`.claude/`に一本化する。

- skills: `.devin/skills/`に`.claude/skills/`配下へのシンボリックリンクを置く。リンク先を実体とし、`.devin/skills/`側は編集しない。
- subagents: `.devin/agents/`に`.claude/agents/`配下へのシンボリックリンクを置く。Devinのsubagentsは`.devin/agents/`を検索対象とし`.claude/agents/`は対象に含まれないため。
- hooks: Devinが`.claude/`の設定を読むため、`.devin/`側には何も置かない。
- 設定: `.devin/config.json`に`.claude/settings.json`の`permissions.deny`を変換して置く。変換規則は下記。
- rules: `.claude/rules/`はDevinの読み込み対象（`read_config_from.claude`）に記載が見つからなかったため、Devin向けの対応はしていない。Devinにも読ませたい指示は`AGENTS.md`に書く。
- MCP: `.mcp.json`をDevinが読むため、`.devin/mcp_config.json`は作らない。
- レビュー: Devin Reviewは[REVIEW.md](./REVIEW.md)を参照する。

`.claude/skills/`または`.claude/agents/`にエントリを追加したときは、対応するシンボリックリンクを`.devin/`側にも追加する。

### `.devin/config.json`の変換規則

`.claude/settings.json`の`permissions.deny`を、Devinの[権限の書式](https://docs.devin.ai/ja/cli/reference/permissions.md)に変換する。`.claude/settings.json`の`permissions`を変更したときは`.devin/config.json`も同じ内容に更新する。

- `Read(glob)`はそのまま`Read(glob)`にする。
- `Edit(glob)`と`Write(glob)`は、Devinに`Edit`相当のスコープが無いため`Write(glob)`に統合する（重複は除く）。
- `Bash(cmd *)`は`Exec(cmd)`にする。`Exec`は単語単位の前方一致でglobを使えないため、末尾の`*`は落とす。
- `Bash(cat .env*)`のような引数にglobを含むルールは表現できないため、`Exec(cat .env)`、`Exec(cat .env.local)`、`Exec(cat key.properties)`の完全一致に置き換える。それ以外の`cat`による秘密ファイルの読み取りは`Read`の拒否ルールだけでは防げない。
- `.claude/settings.ci.json`はGitHub Actions上のClaude Code専用のため変換しない。

リファレンス:

- [Devin Skills](https://docs.devin.ai/ja/product-guides/skills)
- [Devin Subagents](https://docs.devin.ai/ja/cli/subagents)
- [Devin Hooks](https://docs.devin.ai/ja/cli/extensibility/hooks/overview)
- [Devin Configuration](https://docs.devin.ai/ja/cli/extensibility/configuration)
- [Devin Review](https://docs.devin.ai/ja/work-with-devin/devin-review)

## Codex連携

`.codex/config.toml`に`.claude/settings.json`の`permissions.deny`のうちファイルパスのルールを変換して置く。`.claude/settings.json`の`permissions`を変更したときは`.codex/config.toml`も同じ内容に更新する。

- `Read(glob)`・`Edit(glob)`・`Write(glob)`は、Codexの`[permissions.project.filesystem.":workspace_roots"]`に`"glob" = "deny"`として統合する（重複は除く）。Codexのファイル権限は`deny`が読み取りも書き込みも拒否し、操作ごとに分けられないため。
- `./`で始まるルートパスは、`:workspace_roots`配下の相対パスにする。ルート直下だけに一致させない`**/`付きのルールは`**/`なし・ありの両方を置く。
- skills: `.agents/skills/`に`.claude/skills/`配下へのシンボリックリンクを置く。Codexは`<project-root>/.agents/skills/<skill-name>/SKILL.md`を検索対象とし、`.claude/skills/`は対象に含まれないため。リンク先を実体とし、`.agents/skills/`側は編集しない。`.claude/skills/`にエントリを追加したときは、`.agents/skills/`にもリンクを追加する。DevinもDevin自身の`.devin/skills/`に加えて`.agents/skills/`を検索対象とする。
- subagents: `.codex/agents/<name>.toml`に`.claude/agents/<name>.md`を変換して置く。Codexは1ファイル1エージェントのstandalone TOMLを要求し、mdをそのまま読めないためシンボリックリンクにできない。`.claude/agents/`を実体とし、`.codex/agents/`側は編集しない。変換規則は下記。
- rules: `.claude/rules/*.md`は`.codex/hooks.json`のSessionStartフックで`.codex/hooks/load-claude-rules.sh`を実行し、本文を開発者コンテキストとして注入する。フックはリポジトリルートから`.claude/rules/`を再帰的に読み、frontmatterを除いた本文を出力する（`paths`付きのルールには「適用対象パス」を添える）。`.claude/rules/`を実体とし、Claude Codeへの影響を避けるため`AGENTS.md`への`@`取り込みや`AGENTS.override.md`の生成は使わない（`AGENTS.md`はClaude Codeも`CLAUDE.md`経由で読むため、取り込むとルールが二重に読まれる。`AGENTS.override.md`は同じディレクトリの`AGENTS.md`を置き換えるため、`AGENTS.md`の内容の複製が必要になる）。Codexの`rules/*.rules`はコマンド実行を制御するStarlarkで、指示文のruleとは別物。
- フックは初回に`/hooks`でレビュー・信頼が必要で、変更するとハッシュが変わり再レビューまでスキップされる。出力が既定約2,500トークンを超えると全文が保存されプレビューに置き換わるため、`additionalContextLimit`を設定している。
- コマンド禁止: `.claude/settings.json`の`Bash(...)`のdenyルールは、Starlarkの`.codex/rules/deny.rules`に`prefix_rule(..., decision = "forbidden")`として置く。`config.toml`では表現できないため。`.claude/settings.json`の`permissions`を変更したときは`deny.rules`も同じ内容に更新する。変換規則は下記。
- hooks: フックの定義は`.codex/hooks.json`に置く。同じ層に`hooks.json`と`config.toml`のインライン`[hooks]`の両方があるとマージされ起動時に警告が出る（"Prefer one representation per layer."）ため、`config.toml`には`[hooks]`を書かない。`.claude/settings.json`にはhooksが無く、`.claude/settings.ci.json`のhooks（`guard-subagent-sync.sh`・`guard-gh-single-command.sh`・`mark-ci-reply-posted.sh`・`require-ci-reply.sh`）はGitHub ActionsのClaude Code実行（`@claude`メンション）専用で、`CLAUDE_PROJECT_DIR`・Claude Codeの`tool_input.run_in_background`・CLAUDE.mdの応答ルールに依存するため、Codexには変換しない。
- `default_permissions`と`[permissions]`は旧来の`sandbox_mode`と併用できず、読み込まれる設定に`sandbox_mode`が1つでもあると`default_permissions`は無視される。`sandbox_mode`は書かない。
- Codexは信頼済みのプロジェクトでのみ`.codex/`を読む。

### `.codex/rules/deny.rules`の変換規則

- `Bash(cmd arg *)`は`pattern = ["cmd", "arg"]`にする。`pattern`は引数列の完全なトークン単位の前方一致で、`*`は使えないため落とす。
- `-f`と`--force`のように同じ位置で選択肢がある場合は、`["--force", "-f"]`のように1要素のリストで代替を表す。
- 引数にglobを含むルール（`cat .env*`等）は表現できないため、`["cat", [".env", ".env.local", "key.properties"]]`のように具体的なファイル名に置き換える。ファイルパスのglobによる禁止は`config.toml`の`filesystem`で`deny`にする。
- 全ルールに`decision = "forbidden"`と`justification`（人間向けの理由）を付ける。
- 全ルールに`match`と`not_match`の例を付ける。読み込み時に検証されるため、patternの誤りがその時点で分かる。
- 複数のルールに一致した場合は`forbidden` > `prompt` > `allow`の順で最も厳しい決定が適用される。
- `bash -lc "a && b"`のように単純語を`&&`・`||`・`;`・`|`でつないだコマンドは、実行時に分割されて個別に評価される。リダイレクト・`$(...)`・環境変数代入・ワイルドカードを含むコマンドは分割されず、スクリプト全体が1つの呼び出しとして評価されるため、`prefix_rule`が一致しない場合がある。
- 確認は`codex execpolicy check --pretty --rules .codex/rules/deny.rules -- <コマンド>`で行う。この確認ではシェルのラッパーを分割しないため、`bash -lc`経由の評価は実行時とは異なる。
- 変更後はCodexを再起動する。rulesは実験的機能（"Rules are experimental and may change."）で、プロジェクトの`.codex/`が信頼済みの場合のみ読み込まれる。

### `.codex/agents/`の変換手順

`.claude/agents/<name>.md`を追加・変更したときは、対応する`.codex/agents/<name>.toml`を次の規則で作り直す。

1. frontmatterの`name`を`name`に、`description`を`description`にそのまま入れる。ファイル名は`<name>.toml`とする（Codexは識別にファイル名ではなく`name`を使うが、一致させるのが最も単純な規約のため）。
2. frontmatter以降の本文を、TOMLのリテラル複数行文字列（`'''`）で`developer_instructions`に入れる。本文にバックスラッシュやバッククォートが多く、`"""`だと文字がエスケープされるため。本文に`'''`が含まれる場合は`"""`に切り替えてエスケープする。
3. frontmatterの`tools`は変換先が無いため捨てる。Codexのカスタムエージェントは`sandbox_mode`・`approval_policy`・`mcp_servers`をファイルで上書きできず、親セッションの設定を継承する。読み取り専用の制限は、本文の「副作用を伴う操作を行わない」という指示に委ねる（`developer_instructions`は編集を避けるよう頼めるだけで、読み取り専用サンドボックスにはならない）。
4. `model`等の任意キーは設定しない（Claude側にも対応する指定が無いため）。
5. 変換後に`tomllib`でパースし、`name`・`description`・本文が元のmdと一致することを確認する。

リファレンス:

- [Codex Rules](https://learn.chatgpt.com/docs/agent-configuration/rules)
- [Codex Hooks](https://learn.chatgpt.com/codex/hooks)
- [Codex AGENTS.md](https://learn.chatgpt.com/codex/agent-configuration/agents-md)
- [Claude Code memory（.claude/rules）](https://code.claude.com/docs/ja/memory)
- [Codex Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents?surface=app)
- [Codex Skills](https://www.codex-docs.com/ja/docs/build-skills)
- [Codex Configuration Basics](https://learn.chatgpt.com/docs/config-file/config-basic)
- [Codex Configuration Reference](https://learn.chatgpt.com/docs/config-file/config-reference)
- [Codex Permissions](https://learn.chatgpt.com/codex/permissions)
