---
name: android-verify-dispatch
description: GitHub Actionsの`@claude`実行(`.github/workflows/claude.yml`)で、`android-verify-judge`agentの判定結果に基づき、必要な場合に`.github/workflows/claude-android.yaml`をworkflow_dispatchで起動する手順。CLAUDE.mdの「GitHub Actions（@claudeメンション）での応答ルール」から参照される。
---

# Android Emulator確認要否の判定とclaude-android.yamlへの引き継ぎ

`claude.yml`のジョブ内で、`android-verify-judge`agentを呼び出してAndroid Emulatorでの確認要否を判定させ、必要であれば`claude-android.yaml`を起動するための手順。**判定基準そのものは`android-verify-judge`agent側の責務であり、このskillでは扱わない。**`ios-verify-dispatch`skillとほぼ同一のロジックで、呼び出すagentと起動先ワークフローだけがAndroid向けになる。

## 1. `android-verify-judge`agentを呼び出す

`Task`ツールで`subagent_type: android-verify-judge`を指定し、依頼元のコメント本文をそのまま渡す。必要であれば、対象のPR/Issueで何が変更されたかの要約も添えてよい。

agentは以下の形式で応答する。

```
必要: true / false / unknown
理由: <判断の根拠>
```

- `false`の場合は何もせず、通常の対応を続ける（iOS側の検証は、`ios-verify-judge`の判定に従いこれまで通り独立に実行される）。
- `unknown`の場合は、推測で起動判断をせず、依頼者に確認するコメントを残す（CLAUDE.mdの「要件・設計上の曖昧な点は推測で埋めない」方針に準じる）。
- `true`の場合は2.に進む。

## 2. claude-android.yamlへ渡す情報を用意する

以下の情報を集める。

- `target_type`: PRコメント/PRレビュー由来なら`pr`、Issueコメント由来なら`issue`
- `target_number`: 対象のPR番号またはIssue番号。既に把握しているイベント情報（今回のトリガーとなったPR/Issue）からそのまま使う
- `head_ref`: 検証対象のブランチ名。既に自分が作業しているブランチ名（`git branch --show-current`の結果、またはこれまでの会話で分かっている値）をそのまま使う。`gh pr view`等の追加コマンドで取得し直す必要はない（3.参照）
- `original_request`: 依頼元のコメント本文（受け取った依頼テキストそのもの）
- `judged_reason`: `android-verify-judge`agentが返した理由をそのまま使う

## 3. claude-android.yamlを起動する — 単一のシンプルなコマンドとして実行する

**この起動コマンドは、他の処理と組み合わせず、`gh workflow run`だけから始まる1つの単純なコマンドとして実行すること。** 事前に`gh --version`や`gh auth status`で疎通確認をしない、`;`や`&&`で別のコマンドと連結しない、`$(...)`によるコマンド置換やシェル変数展開（`$VAR`）を使わない。

理由: このジョブの`--allowedTools`には`Bash(gh workflow run:*)`のみが許可されており、`gh --version`のような別のコマンドや、変数展開・コマンド置換を含む複合コマンドは、実行前に人間の承認が必要な扱いになる。非対話的なCI実行では承認者がいないため、そのようなコマンドは永遠に承認されず失敗する（`claude-ios.yaml`のdispatchで実際に発生したIssue #56の教訓）。**`gh`が使えるかどうかを事前確認する必要はない。GitHub Actionsのランナーには標準でインストール済みであることが保証されている。** いきなり本番の`gh workflow run`コマンドを実行すること。

`original_request`・`judged_reason`は改行や引用符を含みうるため、シェル変数や`base64`等の別コマンドに頼らず、**シングルクォートで直接くくって1つのコマンド中に埋め込む**。シングルクォート内は改行も含めてそのまま書けるが、本文中に`'`（シングルクォート）が含まれる場合だけ`'\''`に置き換える（例: `it's` → `it'\''s`）。

```bash
gh workflow run claude-android.yaml --ref develop -f target_type='pr' -f target_number='123' -f head_ref='feat/xxx' -f original_request='依頼元のコメント本文をここに直接埋め込む。
複数行でもそのまま書ける。本文中にシングルクォートがあれば '\''のように置換する。' -f judged_reason='android-verify-judgeが返した理由をここに直接埋め込む。'
```

`--ref`は常に`develop`（デフォルトブランチ）を指定する。`claude-android.yaml`自体がまだ存在しないPRブランチからでも確実に起動するためで、実際に検証したいブランチは`head_ref`で別途渡す。`target_type`/`target_number`/`head_ref`/`original_request`/`judged_reason`は実際の値に置き換えること。

## 4. 起動結果を最終応答に含める

**`gh pr comment`/`gh issue comment`を別途実行する必要は無い。** `claude.yml`はイベント（PR/Issueコメント等）にひも付いて起動しており、この turn の最終応答テキストはGitHub Actions側が自動的にPR/Issueコメントとして投稿する。`gh pr comment`等は`--allowedTools`に含まれておらず、実行しようとすると3.と同じ理由で承認待ちのまま失敗するので使わないこと。

### 成功時

`gh workflow run`が成功したら、最終応答の中に以下のような内容を含める（`claude-android.yaml`の完了を待たずにターンを終えてよい）。

```
Android Emulatorでの確認が必要と判断したため、claude-android.yamlに検証を引き継ぎました。
判断理由: <judged_reasonの要約>
完了後、claude-android.yaml側から別途結果がコメントされます。
```

iOS側（`ios-verify-judge`）の検証も同時に走っている場合は、その旨も明記する。

### 失敗時

`gh workflow run`が権限不足・ワークフローファイルが見つからない等で失敗した場合、その旨と原因を最終応答に含める。CLAUDE.mdの「GitHub Actions（@claudeメンション）での応答ルール」に従い、チェックリストを更新しただけで終わらせず、何が原因でどこまで進んだかを文章で明示すること。

```
Android Emulatorでの確認が必要と判断しましたが、claude-android.yamlの起動に失敗しました。
原因: <gh workflow runのエラー内容>
次にすべきこと: <権限設定の確認/ワークフローファイルの存在確認 等>
```
