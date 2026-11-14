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
| `.mcp.json` | `.devin/mcp_config.json`（シンボリックリンク）。Devin CLIは`.mcp.json`も直接読むことを確認済み（`env`の`${VAR}`展開とクラウド版は未確認） | 未対応 |
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

Devinは`read_config_from.claude`（既定で有効）により、Claude Code用の設定の一部を直接読む。ドキュメントで読み込みが明記されているのは、`CLAUDE.md`、`.claude/skills/`、`.claude/commands/`、`.claude/settings.json`・`.claude/settings.local.json`の`hooks`と MCPサーバー、`.mcp.json`。`.claude/agents/`・`.claude/rules/`・`permissions`を読むという記載は無いため、これらは`.devin/`側に派生させるか、対応しない。Claude由来の設定と`.devin/`の設定が衝突した場合の優先順位は記載が無く、未確認。

- skills: `.devin/skills/`に`.claude/skills/`配下へのシンボリックリンクを置く。リンク先を実体とし、`.devin/skills/`側は編集しない。
- subagents: `.devin/agents/`に`.claude/agents/`配下へのシンボリックリンクを置く。Devinのsubagentsは`.devin/agents/`を検索対象とし`.claude/agents/`は対象に含まれないため。
- hooks: Devinが`.claude/settings.json`の`hooks`キーを読むため、`.devin/`側には何も置かない。`.claude/settings.json`にはhooksが無く、`.claude/settings.ci.json`（GitHub Actions専用）はファイル名が異なり読まれないため、Devinのセッションには`.claude/hooks/`のCI用ガードがかからない。これらはGitHub ActionsのClaude Code実行に依存するため意図した状態。Devinにガードが必要になった場合は`.devin/hooks.v1.json`に追加する。
- 設定: `.devin/config.json`に`.claude/settings.json`の`permissions.deny`を変換して置く。変換規則は下記。
- rules: `.claude/rules/`はDevinの読み込み対象（`read_config_from.claude`）に記載が見つからなかったため、Devin向けの対応はしていない。Devinにも読ませたい指示は`AGENTS.md`に書く。
- MCP: `.devin/mcp_config.json`に`.mcp.json`へのシンボリックリンクを置く。Devin CLIは`read_config_from.claude`により`.mcp.json`を読むと明記されているが、`env`の`${VAR}`展開など読み込み後の挙動が未確認のため、専用ファイル側にも同じ定義を置く。どちらも`{"mcpServers": {...}}`の同じ形式で、Devinは同名のMCPサーバーを名前ごとにマージするため二重定義にならない。`.mcp.json`を実体とし、`.devin/mcp_config.json`側は編集しない。次の点は未確認:
  - 確認済み: `devin mcp get figma`の`Source`が`.mcp.json`と表示され、Devin CLIが`.mcp.json`を読むことを確認した。`Env`は`FIGMA_API_KEY=${FIGMA_API_KEY}`と未展開の文字列で表示される。`Source`に`.devin/mcp_config.json`ではなく`.mcp.json`が出るのは、リンクを辿った結果か、同名の定義で`.mcp.json`が優先されたためかを区別できていない。
  - `.mcp.json`の`env`にある`${FIGMA_API_KEY}`を、起動時に展開するか（`devin mcp get`の表示は設定値のままで、展開の有無は分からない）。Devinのドキュメントで展開の記法として確認できるのは`${env:VAR}`（コロン付き、記載があるのはOAuth関連のフィールド）のみで、`env`・`args`・`url`・`headers`で展開できるかは記載が無い。展開されない場合、文字列`${FIGMA_API_KEY}`がそのまま渡る。リンクにしているためClaude Codeの`${VAR}`と食い違う書式には変えられない。展開されないと分かった場合は、リンクをやめて`.devin/mcp_config.json`に`${env:FIGMA_API_KEY}`で定義する。
  - クラウド版Devinがリポジトリ直下の`.mcp.json`を読むか。クラウド版はWebのCustomize → MCPsで登録し、秘密情報はDevinのSecrets機能で渡す。pluginが持つMCPだけがplugin内の`.mcp.json`で宣言される。
  - 実行環境にNode.js（`npx`）があるか。ドキュメントにNode.jsの要件の記載は無い。
  - 展開の有無は、`FIGMA_API_KEY`に実際の値を設定したDevin CLIから、figmaのMCPツール（Figmaのファイル取得など）を呼んで成功するかで確認する。認証エラーになる場合は、文字列がそのまま渡っている。
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
- [Devin CLI MCP設定](https://docs.devin.ai/ja/cli/extensibility/mcp/configuration.md)
- [Devin MCP（クラウド版Devinの接続）](https://docs.devin.ai/work-with-devin/mcp.md)
- [Devin MCP Server（Devin自身をMCPサーバーとして公開する機能。`.mcp.json`の読み込みとは無関係）](https://docs.devin.ai/work-with-devin/devin-mcp)
- [Devin read_config_from（Claude Codeの設定の読み込み）](https://docs.devin.ai/ja/cli/reference/configuration/read-config-from.md)
- [Devin Configuration](https://docs.devin.ai/ja/cli/extensibility/configuration)
- [Devin Review](https://docs.devin.ai/ja/work-with-devin/devin-review)

## Codex連携

`.codex/config.toml`に`.claude/settings.json`の`permissions.deny`のうちファイルパスのルールを変換して置く。`.claude/settings.json`の`permissions`を変更したときは`.codex/config.toml`も同じ内容に更新する。

- `Read(glob)`・`Edit(glob)`・`Write(glob)`は、Codexの`[permissions.project.filesystem.":workspace_roots"]`に`"glob" = "deny"`として統合する（重複は除く）。Codexのファイル権限は`deny`が読み取りも書き込みも拒否し、操作ごとに分けられないため。
- `./`で始まるルートパスは、`:workspace_roots`配下の相対パスにする。`**/`付きのglobはワークスペース直下のファイルに一致しない可能性があるため、すべての`**/`付きのルールに`**/`なしの形も併記する（`.env`系以外も同様）。
- skills: `.agents/skills/`に`.claude/skills/`配下へのシンボリックリンクを置く。Codexは`<project-root>/.agents/skills/<skill-name>/SKILL.md`を検索対象とし、`.claude/skills/`は対象に含まれないため。リンク先を実体とし、`.agents/skills/`側は編集しない。`.claude/skills/`にエントリを追加したときは、`.agents/skills/`にもリンクを追加する。DevinもDevin自身の`.devin/skills/`に加えて`.agents/skills/`を検索対象とする。
- subagents: `.codex/agents/<name>.toml`に`.claude/agents/<name>.md`を変換して置く。Codexは1ファイル1エージェントのstandalone TOMLを要求し、mdをそのまま読めないためシンボリックリンクにできない。`.claude/agents/`を実体とし、`.codex/agents/`側は編集しない。変換規則は下記。
- rules: `.claude/rules/*.md`は`.codex/hooks.json`のSessionStartフックで`.codex/hooks/load-claude-rules.sh`を実行し、本文を開発者コンテキストとして注入する。フックはリポジトリルートから`.claude/rules/`を再帰的に読み、frontmatterを除いた本文を出力する（`paths`付きのルールには、`paths`のYAMLリスト・カンマ区切り・`[a, b]`形式のいずれもカンマ区切りの1行にして「適用対象パス」として添える。`paths`以外のfrontmatterのキーは出力しない）。`.claude/rules/`を実体とし、Claude Codeへの影響を避けるため`AGENTS.md`への`@`取り込みや`AGENTS.override.md`の生成は使わない（`AGENTS.md`はClaude Codeも`CLAUDE.md`経由で読むため、取り込むとルールが二重に読まれる。`AGENTS.override.md`は同じディレクトリの`AGENTS.md`を置き換えるため、`AGENTS.md`の内容の複製が必要になる）。Codexの`rules/*.rules`はコマンド実行を制御するStarlarkで、指示文のruleとは別物。
- フックは初回に`/hooks`でレビュー・信頼が必要で、変更するとハッシュが変わり再レビューまでスキップされる。出力が既定約2,500トークンを超えると全文が保存されプレビューに置き換わるため、`additionalContextLimit`を設定している。
- コマンド禁止: `.claude/settings.json`の`Bash(...)`のdenyルールは、Starlarkの`.codex/rules/deny.rules`に`prefix_rule(..., decision = "forbidden")`として置く。`config.toml`では表現できないため。`.claude/settings.json`の`permissions`を変更したときは`deny.rules`も同じ内容に更新する。変換規則は下記。
- hooks: フックの定義は`.codex/hooks.json`に置く。同じ層に`hooks.json`と`config.toml`のインライン`[hooks]`の両方があるとマージされ起動時に警告が出る（"Prefer one representation per layer."）ため、`config.toml`には`[hooks]`を書かない。`.claude/settings.json`にはhooksが無く、`.claude/settings.ci.json`のhooks（`guard-subagent-sync.sh`・`guard-gh-single-command.sh`・`mark-ci-reply-posted.sh`・`require-ci-reply.sh`）はGitHub ActionsのClaude Code実行（`@claude`メンション）専用で、`CLAUDE_PROJECT_DIR`・Claude Codeの`tool_input.run_in_background`・CLAUDE.mdの応答ルールに依存するため、Codexには変換しない。
- `default_permissions`と`[permissions]`は旧来の`sandbox_mode`と併用できず、読み込まれる設定に`sandbox_mode`が1つでもあると`default_permissions`は無視される。`sandbox_mode`は書かない。
- Codexは信頼済みのプロジェクトでのみ`.codex/`を読む。

### `.codex/rules/deny.rules`の変換規則

- `Bash(cmd arg *)`は`pattern = ["cmd", "arg"]`にする。`pattern`は引数列の完全なトークン単位の前方一致で、`*`は使えないため落とす。
- `-f`と`--force`のように同じ位置で選択肢がある場合は、`["--force", "-f"]`のように1要素のリストで代替を表す。
- 引数にglobを含むルール（`cat .env*`等）は表現できないため、`["cat", [".env", "./.env", "mobile/.env.local", ...]]`のように具体的なファイル名に置き換える。リポジトリに存在する秘密情報ファイル（`.env`、`mobile/.env.local`、`mobile/android/key.properties`等）を、`./`付きの形も含めて列挙し、新しい秘密情報ファイルを追加したときは追記する。列挙していない名前（`cat path/to/.env`等）は一致しない。ファイルパスのglobによる禁止は`config.toml`の`filesystem`で`deny`にする（シェルコマンド経由の読み取りにも効くかは未確認）。
- `Bash(git push --force*)`の`*`は`--force-with-lease`などの別名にも一致するため、`["--force", "--force-with-lease", "-f"]`と列挙する。
- `pattern`は引数列の先頭からの前方一致で、位置を指定しない一致は表現できない。`git push origin feature --force`のようにフラグが引数の後ろに来る形は一致せず許可される（元のClaude側のルールも同じ挙動）。`cat`以外の読み取りコマンド（`head`・`less`等）は元のルールにも含まれず、変換もしていない。
- 全ルールに`decision = "forbidden"`と`justification`（人間向けの理由）を付ける。
- 全ルールに`match`と`not_match`の例を付ける。読み込み時に検証されるため、patternの誤りがその時点で分かる。
- 複数のルールに一致した場合は`forbidden` > `prompt` > `allow`の順で最も厳しい決定が適用される。
- `bash -lc "a && b"`のように単純語を`&&`・`||`・`;`・`|`でつないだコマンドは、実行時に分割されて個別に評価される。リダイレクト・`$(...)`・環境変数代入・ワイルドカードを含むコマンドは分割されず、スクリプト全体が1つの呼び出しとして評価されるため、`prefix_rule`が一致しない場合がある。
- 確認は`codex execpolicy check --pretty --rules .codex/rules/deny.rules -- <コマンド>`で行う。この確認ではシェルのラッパーを分割しないため、`bash -lc`経由の評価は実行時とは異なる。
- 変更後はCodexを再起動する。rulesは実験的機能（"Rules are experimental and may change."）で、プロジェクトの`.codex/`が信頼済みの場合のみ読み込まれる。

### `.codex/agents/`の変換手順

`.claude/agents/<name>.md`を追加・変更したときは、`python3 -I .codex/scripts/sync-agents.py`を実行して`.codex/agents/<name>.toml`を再生成する。`--check`を付けると、書き込まずに差分があれば終了コード1で終わる（`.claude/agents/`に対応するmdが無い`.toml`も差分として報告する）。`.codex/agents/`は生成物のため手で編集しない。

スクリプトの変換規則:

1. frontmatterの`name`を`name`に、`description`を`description`にそのまま入れる。ファイル名は`<name>.toml`とする（Codexは識別にファイル名ではなく`name`を使うが、一致させるのが最も単純な規約のため）。
2. frontmatter以降の本文を、TOMLのリテラル複数行文字列（`'''`）で`developer_instructions`に入れる。本文にバックスラッシュやバッククォートが多く、`"""`だと文字がエスケープされるため。本文に`'''`が含まれる場合は`"""`に切り替えてエスケープする。
3. frontmatterの`tools`は`Read`・`Grep`・`Glob`のみの場合に限り、本文の末尾に「ファイルの読み取りと検索のみを行い、編集・コマンド実行・外部への書き込みを行わない」という注記を追加する。Codexのカスタムエージェントは`sandbox_mode`・`approval_policy`・`mcp_servers`をファイルで上書きできず、親セッションの設定を継承するため、読み取り専用の制限は指示文でしか表現できない（`developer_instructions`は編集を避けるよう頼めるだけで、読み取り専用サンドボックスにはならない）。それ以外の`tools`は変換先が無いため捨てる。
4. `model`等の任意キーは設定しない（Claude側にも対応する指定が無いため）。

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
