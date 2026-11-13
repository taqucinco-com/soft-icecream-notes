---
description: 新しい機能の仕様駆動開発を開始し、specs/<feature-name>/ の雛形を作成する
argument-hint: <feature-name> <一行概要>
---

新機能 `$ARGUMENTS` の仕様駆動開発を開始する。

手順:

1. 機能名を kebab-case に正規化し、`specs/<feature-name>/` ディレクトリを作成する。
2. `requirements.md` に以下の見出しだけを持つ空テンプレートを作成する:
   - 概要
   - ユーザーストーリー
   - 受け入れ条件
   - スコープ外
3. `design.md` と `tasks.md` は空ファイルとして作成のみ行う（中身はまだ書かない）。
4. 作成したファイル一覧を提示し、次に `/spec-requirements <feature-name>` を実行するようユーザーに案内する。

このコマンドではコードの実装や設計判断、要件の記述は行わない。ディレクトリとファイルの雛形作成のみに留めること。
