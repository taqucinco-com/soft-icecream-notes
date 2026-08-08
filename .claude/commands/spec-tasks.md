---
description: 承認済みの設計書からタスクリスト(tasks.md)に分解する
argument-hint: <feature-name>
---

前提: `specs/$ARGUMENTS/design.md` がユーザー承認済みであること。未承認・未作成なら先にそちらを完了するよう促し、このコマンドの本処理は行わない。

対象: `specs/$ARGUMENTS/tasks.md`

手順:

1. `design.md` を読み込み、実装可能な粒度のタスクに分解する。
2. 各タスクは以下の形式で書く:
   - `- [ ] <タスク内容>`（1タスク = 1コミットで完結する程度の粒度）
   - 対応する requirements / design の項番を併記する
3. タスク間に依存関係がある場合は実施順が分かるように並べる。
4. 書き終えたら一覧を提示し、ユーザーの承認を得る。
5. 承認後は `/spec-implement $ARGUMENTS` で実装フェーズに進めることを案内する。
