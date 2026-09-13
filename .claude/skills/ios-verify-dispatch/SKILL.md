---
name: ios-verify-dispatch
description: GitHub Actionsの`@claude`実行(`.github/workflows/claude.yml`)で、`ios-verify-judge`agentの判定結果に基づき、必要な場合に`.github/workflows/claude-ios.yaml`をworkflow_dispatchで起動する手順。CLAUDE.mdの「GitHub Actions（@claudeメンション）での応答ルール」から参照される。
---

# iOS Simulator確認要否の判定とclaude-ios.yamlへの引き継ぎ

`claude.yml`のジョブ内で、`ios-verify-judge`agentを呼び出してiOS Simulatorでの確認要否を判定させ、必要であれば`claude-ios.yaml`を起動するための手順。**判定基準そのものは`ios-verify-judge`agent側の責務であり、このskillでは扱わない。**

## 1. `ios-verify-judge`agentを呼び出す

`Task`ツールで`subagent_type: ios-verify-judge`を指定し、依頼元のコメント本文をそのまま渡す。必要であれば、対象のPR/Issueで何が変更されたかの要約も添えてよい。

agentは以下の形式で応答する。

```
必要: true / false / unknown
理由: <判断の根拠>
```

- `false`の場合は何もせず、通常の対応を続ける（`[ui-verify]`タグによるAndroid側の検証は、その判定に従いこれまで通り独立に実行される）。
- `unknown`の場合は、推測で起動判断をせず、依頼者に確認するコメントを残す（CLAUDE.mdの「要件・設計上の曖昧な点は推測で埋めない」方針に準じる）。
- `true`の場合は2.に進む。

## 2. claude-ios.yamlへ渡す情報を用意する

以下の情報を集める。

- `target_type`: PRコメント/PRレビュー由来なら`pr`、Issueコメント由来なら`issue`
- `target_number`: 対象のPR番号またはIssue番号（すでに把握しているイベント情報、または`gh pr view`/`gh issue view`から取得）
- `head_ref`: 検証対象のブランチ名。PRの場合は`gh pr view <番号> --json headRefName -q .headRefName`で取得する
- `original_request`: 依頼元のコメント本文（受け取った依頼テキストそのもの）
- `judged_reason`: `ios-verify-judge`agentが返した理由をそのまま使う

`original_request`と`judged_reason`は改行や引用符を含みうるため、渡す直前にbase64エンコードする。

## 3. claude-ios.yamlを起動する

```bash
ORIGINAL_REQUEST_B64=$(base64 <<< "$ORIGINAL_REQUEST" | tr -d '\n')
JUDGED_REASON_B64=$(base64 <<< "$JUDGED_REASON" | tr -d '\n')

gh workflow run claude-ios.yaml \
  --repo "$GITHUB_REPOSITORY" \
  --ref develop \
  -f target_type="pr" \
  -f target_number="123" \
  -f head_ref="feat/xxx" \
  -f original_request_b64="$ORIGINAL_REQUEST_B64" \
  -f judged_reason_b64="$JUDGED_REASON_B64"
```

`--ref`は常に`develop`（デフォルトブランチ）を指定する。`claude-ios.yaml`自体がまだ存在しないPRブランチからでも確実に起動するためで、実際に検証したいブランチは`head_ref`で別途渡す。`target_type`/`target_number`/`head_ref`は実際の値に置き換えること。

## 4. 起動結果をコメントする

### 成功時

`gh workflow run`が成功したら、以下のような内容でPR/Issueコメントを残し、ターンを終える（`claude-ios.yaml`の完了を待たない）。

```
iOS Simulatorでの確認が必要と判断したため、claude-ios.yamlに検証を引き継ぎました。
判断理由: <judged_reasonの要約>
完了後、claude-ios.yaml側から別途結果がコメントされます。
```

Android側（`[ui-verify]`）の検証も同時に走っている場合は、その旨も明記する。

### 失敗時

`gh workflow run`が権限不足・ワークフローファイルが見つからない等で失敗した場合、その旨と原因をPR/Issueコメントに残す。CLAUDE.mdの「GitHub Actions（@claudeメンション）での応答ルール」に従い、チェックリストを更新しただけで終わらせず、何が原因でどこまで進んだかを文章で明示すること。

```
iOS Simulatorでの確認が必要と判断しましたが、claude-ios.yamlの起動に失敗しました。
原因: <gh workflow runのエラー内容>
次にすべきこと: <権限設定の確認/ワークフローファイルの存在確認 等>
```
