# soft-icecream-notes

食べたソフトクリームの写真からメモを作成するアプリ。

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

## 言語ルール

コードレビューコメントを含め、Claude Codeが生成する説明文・コメントはすべて日本語で書くこと。コード自体の識別子（変数名・関数名等）は対象外。

## Dartコーディングスタイル (mobile/)

- 型が文脈から推論できる場合は [dot shorthand構文](https://dart.dev/language/dot-shorthands)（`ColorScheme.fromSeed(...)` ではなく `.fromSeed(...)` のように書く記法。Dart 3.10以降の言語機能）を積極的に使う。コンストラクタ呼び出し・static member・enum値のいずれでも使用可。
- これはコンパイルエラーではなく意図したスタイルなので、コードレビューで指摘しないこと。
