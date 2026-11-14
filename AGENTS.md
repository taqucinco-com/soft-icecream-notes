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

## 秘密情報ファイルの取り扱い

`.env`、`*.pem`、`*.key`、`key.properties` 等の秘密情報ファイルは、各ツールのパーミッション設定で読み取りがdenyになっている（実体は`.claude/settings.json`の`permissions.deny`。`.devin/config.json`・`.codex/config.toml`等はそこからの派生）。エージェントはこれらのファイルの内容を取得しようとしてはならない。

コマンド文字列ベースのdenyルールは`f='.''env'; cat "$f"`のようなファイル名の分割・変数参照で回避できてしまうが、回避が可能であることと読んでよいことは別。以下を含むあらゆる手段でdeny対象ファイルの内容を取得・出力しないこと。

- ファイル名の分割・変数・コマンド置換による難読化（例: `f='.''env'`、`cat .''env`）
- コピー・シンボリックリンク・アーカイブ（`cp`/`ln`/`tar`等）経由の間接的な読み取り
- `git show`等、別オブジェクト経由での内容取得

秘密情報の値そのものが必要になった場合は、ファイルを読まずユーザーに確認する。設定の有無を確認したいだけの場合は、値ではなくキー名の一覧やファイルの存在確認に留める。

なおこの節はエージェントの振る舞いを定めるルールであり、技術的な強制ではない。OSレベルでdeny対象パスを隠すには、Devinの`--sandbox`起動（[Devin Sandbox](https://docs.devin.ai/ja/cli/sandbox)）のような仕組みが必要。

## ADR（Architecture Decision Record）

`specs/adr/`は、単一機能に閉じない横断的な設計判断をADRとして記録するディレクトリ。機能仕様（`specs/<feature-name>/`、requirements.md/design.md/tasks.mdの3点セット）とは別物で、仕様駆動開発のフローや3点セットの構造には従わない。

ファイル名は`yyyyMMddHHmm-<slug>.md`形式にする（例: [`specs/adr/202609191216-sandbox-filesystem-constraints.md`](./specs/adr/202609191216-sandbox-filesystem-constraints.md)）。連番（`0001`, `0002`, ...）ではなくタイムスタンプを使う理由は、複数の開発者が異なるブランチで並行開発する場合、マージ時に番号の競合が発生するのを回避するため。

## Devin・Codex連携の基本方針

Claude Codeの`.claude/`配下を実体（正）とし、DevinとCodexはそこから派生させる。Claude Codeの設定・ファイルは、DevinやCodexに対応するために変更しない。

派生物（`.devin/`・`.codex/`・`.agents/`）の生成は、`sync-devin-codex`プラグイン（マーケットプレイス: [taqucinco-com/plugin-marketplace](https://github.com/taqucinco-com/plugin-marketplace)、`.claude/settings.json`の`extraKnownMarketplaces`・`enabledPlugins`で有効化）の`sync`スキルを使う。`.claude/`側を変更したときは`/sync-devin-codex:sync`を実行して派生物を更新する。変換対象・変換規則・未確認事項はプラグインの`references/conversion-rules.md`が一次情報源で、ここでは重複して定義しない。派生物は手で編集しない。Devin Reviewは[REVIEW.md](./REVIEW.md)を参照する。

### 指示の置き場所の判断

指示をどのファイルに書くかは、読み込むツールで決める。

| 指示の種類 | 置き場所 | 理由 |
|---|---|---|
| 全ツールで必要な共通ルール | `AGENTS.md` | Claude Code（`CLAUDE.md`の`@AGENTS.md`経由）、Codex、Devinのすべてが指示ファイルとして読む。`.claude/rules/`はDevinの読み込み対象に確認できていないため、Devinにも必要な指示は置かない。 |
| Claude Code固有のルール | `CLAUDE.md` | 他ツールは読まない。 |
| 特定のパスを扱うときだけ必要な指示（Claude Code・Codexで十分なもの） | `.claude/rules/*.md`（`paths`付き） | Claude Codeは一致するファイルを扱うときだけ読み込む。Codexは`.codex/hooks.json`のフックで注入する。 |
| 引数を取り、ユーザーが明示的に呼ぶ手順 | `.claude/skills/<name>/SKILL.md` | `.claude/commands/`は非推奨で、スキルが後継。Devin・Codexにもシンボリックリンクで共有できる。 |

リファレンス（Claude Code）:

- [`.claude`ディレクトリ](https://code.claude.com/docs/ja/claude-directory)
- [Claude Code memory（`CLAUDE.md`・`.claude/rules`）](https://code.claude.com/docs/ja/memory)
