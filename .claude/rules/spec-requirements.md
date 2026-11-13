---
description: 要件定義書(requirements.md)を作成・更新する
argument-hint: <feature-name>
---

対象: `specs/$ARGUMENTS/requirements.md`

手順:

1. 既存の `requirements.md` があれば読み込み、無ければ `/spec-init` の実行を促す。
2. ユーザーへの要望をヒアリングしながら、以下の構成で記述する:
   - 概要（何のための機能か）
   - ユーザーストーリー（As a ... I want ... So that ...）
   - 受け入れ条件（EARS記法: WHEN <イベント> THEN <システム> SHALL <振る舞い>、で検証可能な形にする）
   - スコープ外（今回やらないこと）
3. 曖昧な要求は推測で埋めず、AskUserQuestion 等で必ずユーザーに確認する。
4. 書き終えたら内容を要約して提示し、ユーザーの承認を得る。
5. 承認が得られるまで `design.md` には着手しない。承認後は `/spec-design $ARGUMENTS` の実行を案内する。
