---
description: tasks.mdの未着手タスクを1つ実装する
argument-hint: <feature-name> [task番号やキーワード]
---

対象: `specs/$ARGUMENTS` の `tasks.md`

手順:

1. `tasks.md` を読み込み、指定されたタスク（未指定なら先頭の未完了タスク）を特定する。
2. 対応する `requirements.md` / `design.md` の該当箇所を参照しながら実装する。
3. 実装後、関連するテストを実行する（既存テストが無く必要な場合は追加する）。
4. 完了したら `tasks.md` の該当項目に `[x]` を付ける。
5. 一度に複数タスクをまとめて実装しない。1タスク完了ごとに結果をユーザーに報告し、次に進むか確認する。
