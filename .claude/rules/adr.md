---
paths:
  - "specs/adr/**"
---

# ADR（Architecture Decision Record）

`specs/adr/`は、単一機能に閉じない横断的な設計判断をADRとして記録するディレクトリ。機能仕様（`specs/<feature-name>/`、requirements.md/design.md/tasks.mdの3点セット）とは別物で、仕様駆動開発のフローや3点セットの構造には従わない。

## 命名規則

ファイル名は`yyyyMMddHHmm-<slug>.md`形式にする（例: [`specs/adr/202609191216-sandbox-filesystem-constraints.md`](../../specs/adr/202609191216-sandbox-filesystem-constraints.md)）。連番（`0001`, `0002`, ...）ではなくタイムスタンプを使う理由は、複数の開発者が異なるブランチで並行開発する場合、マージ時に番号の競合が発生するのを回避するため。
