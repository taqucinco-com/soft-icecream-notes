---
name: flutter-ui-verify-result-save
description: `ui-checker`agentによる画面比較結果を、人間が読むMarkdownと機械集計用JSONの両方の形式で保存する手順。`flutter-ui-android-verify`/`flutter-ui-android-verify-ci`/`flutter-ui-ios-verify`/`flutter-ui-ios-verify-ci`の4スキルが共通して使う（プラットフォーム・ローカル/CI問わずフォーマットは同一で、保存先ディレクトリだけが呼び出し元ごとに異なる）。検証ループが正常終了・上限到達・`fatal`のいずれで終わった場合も、この手順で保存する。
---

# 評価結果の保存（Markdown + JSON）

`ui-checker`agentによる検証ループの終了時（正常終了・イテレーション上限到達・`fatal`によるエスカレーションのいずれでも）に、その結果をMarkdownとJSONの両方で保存するための共通手順。呼び出し元（`flutter-ui-android-verify`/`flutter-ui-android-verify-ci`/`flutter-ui-ios-verify`/`flutter-ui-ios-verify-ci`）ごとにフォーマットは変えず、保存先ディレクトリだけが異なる。

## 保存先ディレクトリ

このスキル自体はディレクトリを決めない。呼び出し元skillがスクリーンショットの保存先として指示しているディレクトリ（`flutter-android-operate`/`flutter-android-operate-ci`/`flutter-ios-operate`/`flutter-ios-operate-ci`いずれかの指示に従う）に、スクリーンショット画像と同じ並びで保存する。

## 保存内容

ループが終了した時点の`ui-checker`の最終応答（JSON。`criteria`/`overall_verdict`/`fatal`/`fatal_reason`を含む）に、以下を追加してJSONを組み立てる。

- `compared_at`: ISO8601日時
- `reference_image`: Figmaとの比較を行った場合は`<name>-figma.png`、依頼文との比較の場合は`null`
- `implementation_image`: `<name>-app.png`
- `loop_iterations`: ループの最終イテレーションカウンタ値
- `loop_verdict`: 呼び出し元がこのループの最終結果として判定した値。`pass`（`mismatch`が0件で正常終了） / `retry_limit_reached`（`mismatch`が残ったままイテレーション上限=10に到達） / `fatal`（`ui-checker`が`fatal: true`を返しエスカレーション）のいずれか。**`ui-checker`自体はこの値を返さない**（`fatal`/`fatal_reason`以外は呼び出し元が組み立てる）。

これを人間が読むMarkdownと、後で複数回分をスクリプト集計できるJSONの両方に、同じ内容で書き出す。ファイル名は画面名を揃え、拡張子だけ変える（`<name>-compare.md` / `<name>-compare.json`）。

判定語とJSON側の値の対応:

| 表記（Markdown） | JSON値 |
|---|---|
| 一致 | `match` |
| 軽微な差異 | `minor_diff` |
| 不一致 | `mismatch` |
| 該当なし | `not_applicable` |

総合判定の対応:

| 表記（Markdown） | JSON値 |
|---|---|
| 完全一致 | `exact_match` |
| ほぼ一致 | `close_match` |
| 部分一致 | `partial_match` |
| 大きく乖離 | `major_divergence` |

**Markdown（`<name>-compare.md`）**

```markdown
# <画面名> ワイヤーフレーム比較

- Figma node-id: <id>
- 比較日時: <date>
- リファレンス: `<name>-figma.png` / 実装: `<name>-app.png`
- ループ回数: <イテレーションカウンタの最終値>

## チェックリスト

| 観点 | 判定 | 差分 |
|---|---|---|
| 画面構成 | 一致 | - |
| 要素の有無 | 軽微な差異 | ○○ボタンが未実装 |
| 配置・順序 | 一致 | - |
| テキスト/ラベル内容 | 一致 | - |
| 状態表現 | 該当なし | - |

## 総合判定

ほぼ一致
```

**JSON（`<name>-compare.json`）**

`diff`は差分説明の自由記述（日本語）、それ以外のキー・値は英語のenumで機械可読にする。Figmaとの比較を行っていない場合は`figma_node_id`・`reference_image`を`null`にする。

```json
{
  "screen": "<画面名>",
  "figma_node_id": "<id、Figmaとの比較を行っていない場合はnull>",
  "compared_at": "<ISO8601日時>",
  "reference_image": "<name>-figma.png（Figmaとの比較を行っていない場合はnull）",
  "implementation_image": "<name>-app.png",
  "criteria": [
    { "aspect": "layout_structure", "verdict": "match", "diff": null },
    { "aspect": "element_presence", "verdict": "minor_diff", "diff": "○○ボタンが未実装" },
    { "aspect": "arrangement_order", "verdict": "match", "diff": null },
    { "aspect": "text_labels", "verdict": "match", "diff": null },
    { "aspect": "state_representation", "verdict": "not_applicable", "diff": null }
  ],
  "overall_verdict": "close_match",
  "fatal": false,
  "fatal_reason": null,
  "loop_verdict": "pass",
  "loop_iterations": 1
}
```

`fatal`/`fatal_reason`は`ui-checker`の応答をそのまま転記する。`loop_verdict`はそれとは別に、呼び出し元がこのループ全体の結末（正常終了/上限到達/エスカレーション）を表すために付与する値である点に注意する。

同じ画面を複数回検証する場合は上書きせず`<name>-compare-<timestamp>.json`のように連番/日時を付けて残し、`jq`等で時系列に読み込めば「実装が近づいているか」を追跡できる。
