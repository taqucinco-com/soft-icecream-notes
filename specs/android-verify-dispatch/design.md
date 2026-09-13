# アーキテクチャ概要

```
[@claudeメンション]
        │
        ▼
   claude.yml (ubuntu-latest, 常時Flutter SDKセットアップのみ)
   ┌─────────────────────────────────────────────┐
   │ Claude Codeが依頼内容を分析                     │
   │  → android-verify-judge agentをTaskで呼び出し   │
   │  → ios-verify-judge agentをTaskで呼び出し       │
   │  （[ui-verify]タグはプラットフォーム不問の         │
   │    汎用シグナルとして両agentに伝わる。            │
   │    プラットフォーム不明時はAndroidをデフォルト）   │
   └─────────────────────────────────────────────┘
        │ Android要                 │ iOS要
        ▼                           ▼
  android-verify-dispatch      ios-verify-dispatch
  skillの手順で                 skillの手順で
  gh workflow run               gh workflow run
  claude-android.yaml            claude-ios.yaml
        │                           │
        ▼                           ▼
  claude-android.yaml            claude-ios.yaml
  (ubuntu-latest, 新規)          (macos-26, 既存)
  ┌─────────────────────┐    ┌─────────────────────┐
  │ Android SDK/JDK/KVM/  │    │ iOS Simulator/       │
  │ Gradle/AVD/エミュレータ│    │ idb-companion        │
  │ + Flutterフルビルド   │    │ + Flutterフルビルド   │
  │ 環境                  │    │ 環境（既存）          │
  └─────────────────────┘    └─────────────────────┘
        │                           │
        └──────────┬────────────────┘
                    ▼
     検証ループ（flutter-ui-verify-ci / flutter-ui-ios-verify-ci
                 いずれもローカル版 flutter-ui-verify /
                 flutter-ui-ios-verify の7節を参照）
     ┌───────────────────────────────────────────┐
     │ 1. ビルド・インストール・起動・スクリーンショット │
     │ 2. ui-verify-judge agentをTaskで呼び出し       │
     │    （Android/iOS共通・判定専任）               │
     │ 3. 判定結果で分岐:                            │
     │    - pass（重大な指摘0件）→ ループ終了・成功      │
     │    - retry（重大な指摘あり、致命的でない）        │
     │      → コード修正→再ビルド→1へ戻る（最大10回）    │
     │    - fatal（致命的な破綻）→ 即中断・人間へ       │
     │      エスカレーション                          │
     └───────────────────────────────────────────┘
```

`claude.yml`は「軽量なコーディング/トリアージ役」に徹し、Android/iOSどちらのプラットフォーム固有の重い環境構築も一切行わない。両OSの要否判定は独立した専任agent（`android-verify-judge`/`ios-verify-judge`）が行い、それぞれ独立に成立しうる（要件3）。`[ui-verify]`タグは今回からプラットフォーム不問の汎用シグナルとなり、プラットフォームが依頼文から特定できない場合は安価なAndroidをデフォルトとするコストバイアスを両agentが共有する（要件8, 9）。

実際の検証（スクリーンショットを撮って期待と比較し、必要なら直して撮り直す）は、Android/iOS・ローカル/CIを問わず共通のループ構造を持つ。この判定部分だけを新規agent`ui-verify-judge`に切り出し、既存4つの`*ui-verify*`系skillすべてがこのループ経由で評価を行うように改修する（要件16〜22）。

# コンポーネント/モジュール構成

## 1. 新規agent: `android-verify-judge`（Android Emulatorでの確認要否判定）

`ios-verify-judge`と同じ設計思想（`tools: Read, Grep, Glob`のみ、副作用ゼロ、判定と理由のみを返す）。判断基準は`ios-verify-judge`とほぼ対称だが、以下の点が異なる。

- 入力に依頼元コメント本文と（把握していれば）`[ui-verify]`タグの有無を含める。
- `[ui-verify]`タグがあり、かつ依頼内容からプラットフォームが特定できない場合は「必要: true」とする（コストの安いAndroidをデフォルトにするバイアス。要件8）。
- 依頼内容が明示的にiOS固有（Cupertino、iOS限定の不具合等）であり、かつAndroidに無関係と判断できる場合は「必要: false」としてよい。
- 出力形式は`ios-verify-judge`と同じ（`必要: true/false/unknown` + 理由）。

## 2. 新規skill: `android-verify-dispatch`（起動用）

`ios-verify-dispatch`skillとほぼ同一のロジック・同じ注意点（Issue #56の教訓：事前疎通確認をしない、単一の単純なコマンドとして実行する、base64を使わずシングルクォートで直接埋め込む）を踏襲する。差分は以下のみ。

- 呼び出すagentが`android-verify-judge`。
- 起動するワークフローが`claude-android.yaml`。
- 起動コマンド例:

  ```bash
  gh workflow run claude-android.yaml --ref develop -f target_type='pr' -f target_number='123' -f head_ref='feat/xxx' -f original_request='...' -f judged_reason='...'
  ```

## 3. 既存agent`ios-verify-judge`の改修

- 判断基準の記述に、`[ui-verify]`タグがプラットフォーム不問の汎用シグナルになったことを反映する。
- `[ui-verify]`タグ単体（プラットフォームが特定できない場合）ではiOSの要否をtrueにしない、というコストバイアスを明記する（Androidがデフォルト）。
- 依頼内容が明示的にiOS固有と判断できる場合は、`[ui-verify]`タグの有無に関わらずtrueにできる、という既存の判断基準は変更しない。

## 4. 既存skill`ios-verify-dispatch`の改修

- ロジック自体（agent呼び出し→`gh workflow run`→最終応答に含める）に変更は無い。「Android版と対称な構成になった」旨をコメントとして反映する程度の軽微な文言修正のみ。

## 5. 新規ワークフロー: `.github/workflows/claude-android.yaml`

`claude-ios.yaml`と同じ構成。既存`claude.yml`の`if: steps.ui_verify.outputs.enabled == 'true'`が付いていたAndroid関連ステップ（`.env.local`生成、gh CLIアップグレード、JDK 17、KVM有効化、Android SDKセットアップ、Gradle cache、AVD cache、stale lock除去、Debug Keystoreデコード、Flutterセットアップ、Dart build_runner cache、`flutter pub get`+codegen、codegen変更の破棄、AVD作成・起動確認（reactivecircus）、エミュレータのバックグラウンド起動）を丸ごと移植する。

- トリガー: `workflow_dispatch`のみ。`inputs`は`claude-ios.yaml`と同じ形（`target_type`, `target_number`, `head_ref`, `original_request`, `judged_reason`。base64エンコードは行わない）。
- `runs-on: ubuntu-latest`（既存のclaude.ymlのAndroid部分と同じ。iOSのmacosランナーよりコストが安い）。
- `actions/checkout@v4`は`ref: ${{ inputs.head_ref }}`。
- `anthropics/claude-code-action@v1`の`prompt`に`${{ inputs.original_request }}`/`${{ inputs.judged_reason }}`をそのまま埋め込み、`flutter-ui-verify-ci`skillを使うよう指示する。
- `claude_args`の`--allowedTools`は`claude-ios.yaml`のAndroid相当（`Bash(adb:*)`, `Bash(flutter:*)`, `Bash(dart:*)`, `Bash(cd mobile && *)`, `Bash(git commit:*)`, `Bash(git push:*)`, `Bash(gh pr comment:*)`, `Bash(gh issue comment:*)`等）を許可し、Issue #56の教訓（単一コマンド・事前疎通確認禁止）をpromptに明記する。
- 完了時のartifactアップロード・コメント投稿（成功時のスクリーンショットリンク・失敗時のエスカレーション）は`claude-ios.yaml`と同じパターン。

## 6. `claude.yml`の変更点

- 削除: `Determine if UI verification (Android emulator) is requested`（`ui_verify`ステップ）、`Create mobile/.env.local from .env.sample`、`Upgrade gh CLI for --attach support`、`Set up JDK 17`、`Enable KVM`、`Setup Android SDK`、`Gradle cache`、`AVD cache`、`Remove stale emulator lock files`、`Decode Debug Keystore`、`create and check booting AVD`、`Start Android emulator`、`Upload UI verification screenshots`、`Post screenshot artifact link`、`Stop Android emulator`。これらはすべて`claude-android.yaml`に移植済み。
- 変更: `Set up Flutter (from mobile/.fvmrc)`、`Dart build_runner cache`、`Install Flutter dependencies and generate code`、`Discard codegen changes to tracked files`は`if`条件を外し、常時実行するステップとしてそのまま残す（要件2）。
- `claude_args`の`--allowedTools`から`Bash(adb:*)`を削除する（このジョブではAndroidエミュレータを一切操作しないため不要）。`Bash(flutter:*)`/`Bash(dart:*)`は`flutter analyze`/`flutter test`等の静的解析用途で引き続き必要なため残す。`Bash(gh workflow run:*)`はAndroid/iOS両方のdispatchに共通で使えるため変更不要。
- `permissions`（`actions: write`含む）は変更しない。

## 7. 新規agent: `ui-verify-judge`（スクリーンショット評価の判定専任）

`flutter-ui-verify`skillの7節にある評価ロジック（チェックリスト・判定基準・Markdown+JSON形式）をそのまま踏襲しつつ、専任agentとして切り出す。`tools: Read`のみ（画像を読むためだけ。編集・コマンド実行は一切行わない）。Android/iOS共通の1つとする。

- 入力（呼び出し元がTaskの`prompt`で渡す）: 実装のスクリーンショット画像パス、（7-Aの場合）Figmaリファレンス画像パスと`get_metadata`構造情報、（7-Bの場合）依頼文で示された期待、エラーログや起動失敗の有無等が分かっていればそれも渡す。
- 出力: 既存の`criteria`配列・`overall_verdict`に加えて、ループ制御用に次を追加する。
  - `loop_verdict`: `pass` | `retry` | `fatal`
  - `pass`: 重大な指摘（`mismatch`）が0件（`minor_diff`のみ、または`match`のみ）。
  - `retry`: 1件以上の`mismatch`があるが、`fatal`の条件に該当しない。
  - `fatal`: 次のいずれかに該当する場合（要件18）: (a) 実行環境レベルの問題で改善しようがない、(b) 実装以前に破綻している仕様の瑕疵、(c) コード修正だけでは解決しない問題、(d) emulator/simulatorがそもそも起動できていない。
  - `fatal`の場合は`fatal_reason`にどれに該当するか＋具体的な理由を文章で含める。

## 8. 既存4skillへの検証ループ導入

`flutter-ui-verify`skillの7節を「7. 画面の評価」から「7. 画面の評価とui-verify-judgeによるループ」に改修し、以下の流れに書き換える。他3skill（`flutter-ui-verify-ci`, `flutter-ui-ios-verify`, `flutter-ui-ios-verify-ci`）は従来通りこの7節を参照する形を維持する（重複定義しない）。

1. （既存の7-A/7-B手順で）スクリーンショット・構造情報・比較対象を用意する。
2. イテレーションカウンタを1から始める（呼び出し元本体のClaudeが会話内で保持する。`ui-verify-judge`自体は状態を持たない）。
3. `ui-verify-judge`agentをTaskツールで呼び出し、1で用意した情報を渡す。
4. `loop_verdict`で分岐:
   - `pass`: 検証完了。評価結果（Markdown+JSON）を保存して終了（要件19）。
   - `fatal`: 直ちに中断し、`fatal_reason`とそれまでの指摘内容を人間へのエスカレーションとして最終応答に含める（要件18, 22）。それ以上コードの修正は試みない。
   - `retry`かつイテレーションカウンタ < 10: 指摘内容をもとにFlutter/Dartのコードを修正し、各skill既存の手順（2節「アプリをビルド・起動する」等）で再ビルド・再インストール・再起動・再スクリーンショットを行い、カウンタを+1して3に戻る（要件17）。
   - `retry`かつイテレーションカウンタ = 10: それ以上ループせず、上限到達を理由に人間へエスカレーションする（判明していた直近の指摘内容も添える。要件20, 22）。

# データモデル・API/インターフェース

## `claude-android.yaml`の`workflow_dispatch.inputs`

`claude-ios.yaml`と同一の形（Issue #56の教訓を反映済み、base64無し）。

| 入力名 | 型 | 内容 |
|---|---|---|
| `target_type` | string (`pr` \| `issue`) | 結果をコメントする先がPRかIssueか |
| `target_number` | string | PR番号またはIssue番号 |
| `head_ref` | string | チェックアウト対象のブランチ名 |
| `original_request` | string | 依頼元コメント本文 |
| `judged_reason` | string | `claude.yml`側で判断した理由 |

## `ui-verify-judge`agentの呼び出しインターフェース

- 呼び出し: `Task`ツールで`subagent_type: ui-verify-judge`を指定。
- 出力形式（JSON、既存の`criteria`/`overall_verdict`に追加する形）:

  ```json
  {
    "screen": "<画面名>",
    "figma_node_id": "<id、7-Bではnull>",
    "criteria": [
      { "aspect": "layout_structure", "verdict": "match", "diff": null }
    ],
    "overall_verdict": "close_match",
    "loop_verdict": "retry",
    "fatal_reason": null
  }
  ```

  `loop_verdict`が`fatal`の場合のみ`fatal_reason`に該当区分（環境問題/仕様の瑕疵/コード修正不可/起動不可のいずれか）と具体的な説明を入れる。

# 各要件と設計要素の対応関係（トレーサビリティ）

| 要件 | 対応する設計要素 |
|---|---|
| 1. `android-verify-judge`agent | コンポーネント1 |
| 2. Flutterセットアップの常時実行 | コンポーネント6 |
| 3. 両agentが独立に判定 | アーキテクチャ概要図、コンポーネント1・3 |
| 4. `android-verify-dispatch`skillでの起動 | コンポーネント2 |
| 5. 起動時に渡す情報 | データモデル（`workflow_dispatch.inputs`） |
| 6. 起動成功時の最終応答 | コンポーネント2 |
| 7. 起動失敗時の最終応答 | コンポーネント2 |
| 8. `[ui-verify]`単体でのAndroidデフォルト | コンポーネント1 |
| 9. iOS固有時の`ios-verify-judge`判定 | コンポーネント3 |
| 10. `claude-android.yaml`のセットアップ範囲 | コンポーネント5 |
| 11. `flutter-ui-verify-ci`の利用 | コンポーネント5、コンポーネント8 |
| 12. 修正・再ビルドループの権限 | コンポーネント5（`--allowedTools`） |
| 13. `claude-android.yaml`完了時の最終応答 | コンポーネント5 |
| 14. artifactアップロード | コンポーネント5 |
| 15. Issue #56の教訓の適用 | コンポーネント2 |
| 16. `ui-verify-judge`の呼び出し | コンポーネント7・8 |
| 17. `retry`時のループ継続 | コンポーネント8 |
| 18. `fatal`時の即エスカレーション | コンポーネント7・8 |
| 19. `pass`時の正常終了 | コンポーネント7・8 |
| 20. 上限到達時のエスカレーション | コンポーネント8 |
| 21. `ui-verify-judge`の判定専任性 | コンポーネント7 |
| 22. エスカレーション時の理由明示 | コンポーネント8 |

# 検討したが採用しなかった代替案・既知のリスク

## 代替案

- **`claude.yml`にAndroid環境構築を残し、判定だけagent化する**: 判定と重い環境構築を分離するという本機能の目的そのものに反するため不採用。
- **`ui-verify-judge`をAndroid/iOSで別agentにする**: 判定ロジック（チェックリスト・4段階判定）は既にプラットフォーム非依存で共通化されているため、agentも1つに統一する方がメンテナンス性が高い（ユーザー確認済み）。
- **`loop_verdict`を`overall_verdict`（`exact_match`等）だけで代用する**: 既存の4段階は「どの程度似ているか」の粒度であり、「ループを続けるべきか/中断してエスカレーションすべきか」という制御用の3値とは目的が異なるため、別フィールドとして追加した。
- **ループ上限やfatal判定基準を依頼内容ごとに動的にする**: 要件定義時点でスコープ外と確認済み。固定値・固定基準とする。

## 既知のリスク

- **`fatal`判定の主観性**: 「コードの修正だけでは解決しない問題」等の判断はagentの意味的判断に委ねられ、判断がぶれる可能性がある。判断基準の例示を継続的に調整する運用が前提になる。
- **10回ループの実行時間**: 1回のビルド（特にiOS）は数十秒〜数分かかるため、10回近くまでループするとジョブの`timeout-minutes`を超過する可能性がある。実装時に既存のtimeout値で十分かを確認する必要がある。
- **`[ui-verify]`タグの意味変更による既存運用への影響**: これまで`[ui-verify]`はAndroidのみをトリガーしていたが、今後はコストバイアス次第でiOS側の判定にも間接的に影響しうる（明示的にiOS固有と判断できない限りtrueにしないため実際の挙動は変わらない想定だが、判断基準の文言変更なので注意深くレビューする）。
- **Issue #56と同種の権限問題の再発**: `claude-android.yaml`も`claude-ios.yaml`と同じBash権限モデルの制約を受けるため、`android-verify-dispatch`skill・`claude-android.yaml`双方で同じ注意点（単一コマンド・事前疎通確認禁止）を確実に踏襲する必要がある。
