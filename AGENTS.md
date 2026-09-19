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
