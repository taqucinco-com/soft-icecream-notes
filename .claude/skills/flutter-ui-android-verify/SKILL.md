---
name: flutter-ui-android-verify
description: ローカル開発環境でAndroidエミュレータ上のicecream_log(mobile/)を実機起動し、adbでのタップ操作・スクリーンショット取得・Figmaワイヤーフレームとのチェックリストに基づく構造的比較（VLMによる一致度判定）によってUI実装の妥当性を検証する。「動作確認して」「ワイヤーフレーム通りか確認して」「実機で見た目を確認して」「Figmaとどれくらい近づいたか教えて」等の依頼で使う。依頼にiOS/シミュレータ/idbへの言及がある場合は代わりに`flutter-ui-ios-verify`スキルを、GitHub Actions CI上で実行している場合は`flutter-ui-android-verify-ci`スキルを使うこと（いずれもアプリの起動方法・操作コマンドが異なる）。
---

# Flutter UI検証（icecream_log / Androidエミュレータ・ローカル環境向け）

`mobile/`配下のFlutterアプリを実機（Androidエミュレータ）で起動し、adb操作とスクリーンショットで実装の見た目・挙動を検証する手順。design.mdの「Figmaワイヤーフレームとの対応関係」表にある各画面を、実装後に実際にレンダリングして確認する用途を想定している。**ローカル開発環境向け**で、`fvm`経由（`fvm flutter`/`fvm dart`）での実行を前提にしている。GitHub Actions CI上で`[ui-verify]`から呼ばれた場合は、このスキルではなく`flutter-ui-android-verify-ci`スキルを使うこと（アプリのビルド・起動方法だけが異なり、以下の内容は共通）。

エミュレータの起動・アプリのビルド起動・スクリーンショット撮影・タップ操作・ヒットターゲットのデバッグ・環境要因の落とし穴は、このスキルではなく`flutter-android-operate`スキル（`.claude/skills/flutter-android-operate/SKILL.md`）を使う。このスキルは、その操作結果を「評価」してループを回す部分だけを扱う（重複して定義しない）。

## 前提

- Androidエミュレータで検証する（iOSシミュレータの場合は`flutter-ui-ios-verify`スキルを使う）。
- スクリーンショットの保存先は`flutter-android-operate`skillの指示（`.claude/screenshots/<module>/`）に従う。

## 画面の評価とui-checkerによるループ

評価そのものは専任agent`ui-checker`（Android/iOS・ローカル/CI共通、判定のみで副作用ゼロ）に委ね、本体のClaude（このskillを実行している自分自身）はその判定結果をもとに「コード修正→再ビルド→再検証」のループを回す。その場の印象で「だいたい合っている/動いている」と済ませたり、`ui-checker`を介さず自分で評価を確定させたりしないこと。**Figmaとの比較（7-A）を行うのは、依頼文で「Figma」「ワイヤーフレーム」「デザイン通り」など、Figmaへの言及が明示的にある場合に限る。** 言及が無い場合はFigmaを呼び出さず、7-Bの単純な構造分析を行う。ループの制御自体は7-Cで扱う。

### 7-A. Figmaに言及がある場合: Figmaワイヤーフレームとの比較用の資料を用意する

#### 手順

1. design.mdの「Figmaワイヤーフレームとの対応関係」表で、検証したい画面に対応するnode-idを確認する。
2. Figma MCPの`get_screenshot`（`figma-use`系スキルは不要、読み取りのみなので直接呼び出してよい）でそのnode-idのリファレンス画像を取得し、`.claude/screenshots/<module>/<name>-figma.png`として保存する（＝「目指すべき成果物」）。
3. 同じnode-idについて`get_metadata`も呼び出し、各要素のid・name・x/y/width/heightを含む構造情報（下記のようなXML）を取得する。

   ```xml
   <frame id="13:76" name="Navigation" x="627" y="50" width="673" height="149">
     <frame id="13:28" name="Text" x="50" y="63" width="378" height="23">
   ```

   これは「要素の有無」「配置・順序」を画像の目視だけに頼らず、要素名・座標という客観的な情報で裏付けるために使う。
4. `flutter-android-operate`skillの3節の手順で実機の現状スクリーンショットを`.claude/screenshots/<module>/<name>-app.png`として保存する（＝「現状」）。あわせて同skill4節の`uiautomator dump`でアプリ側の構造（text/content-desc/bounds）も取得しておくと、Figmaの`get_metadata`と直接突き合わせられる。
5. 画像パス（`<name>-figma.png`/`<name>-app.png`）とメタデータが揃ったら7-Cに進み、`ui-checker`に渡して判定させる。「比較対象」はFigmaのリファレンス（画像・`get_metadata`）であることを7-Cの呼び出しで明示する。

### 7-B. Figmaに言及が無い場合: 単純な構造分析の材料を用意する

Figmaは呼び出さず、実機のスクリーンショットと`uiautomator dump`で得られる構造だけを根拠に、**依頼文で言及された確認内容（例:「マップタブに切り替えたら地図が表示されるはず」「一覧にカードが並んでいるはず」等）に実装がどの程度応えているか**を`ui-checker`に判定させる。依頼文がUIの構造や見た目に触れていない場合（例: 単に「起動確認して」）は、クラッシュ・白画面・意図しないダイアログの有無など、最低限の起動確認のみでよい。

#### 手順

1. `flutter-android-operate`skillの3節の手順で実機のスクリーンショットを`.claude/screenshots/<module>/<name>-app.png`として保存する。
2. 同skill4節の`uiautomator dump`でアプリの構造（text/content-desc/bounds）を取得する。
3. 画像パスと構造情報が揃ったら7-Cに進み、`ui-checker`に渡して判定させる。「比較対象」はFigmaではなく依頼文で示された期待であることを7-Cの呼び出しで明示する。

### 7-C. `ui-checker`を呼び出し、ループする

1. イテレーションカウンタを1にする（この会話内で本体のClaudeが保持する。`ui-checker`自体は状態を持たない）。
2. `Agent`ツールで`subagent_type: ui-checker`を**同期的に（`run_in_background: false`を指定して）**呼び出す。7-A/7-Bで用意した画像パス、（7-Aの場合）Figmaの構造情報、比較対象の期待（Figmaまたは依頼文）を渡す。**バックグラウンド（非同期）呼び出しは絶対に使わないこと。** GitHub Actions等の非対話的なCIセッションには後続ターンが無く、非同期呼び出しの完了通知を受け取れる機会が無いため、判定結果を使えないままターンが終わってしまう（実際にこの事故が発生し、ループが一度も回らずに完了報告コメントも投稿されなかった）。
3. 応答のJSON中の`fatal`でまず分岐する。**`pass`/`retry`という二値の「ループ制御判定」は`ui-checker`自体は返さない**（`mobile-screen-vision-compare`の比較結果である`criteria`と、環境・仕様レベルの`fatal`判定だけがagentの責務であり、そこから先の「ループを続けるか」はイテレーションカウンタという状態を持つ呼び出し元＝このskill自身の責務のため）。
   - **`fatal: true`**: 直ちにループを中断する。それ以上コードの修正・再ビルドを試みず、`fatal_reason`と直近の`criteria`をそのまま依頼者への報告（人間へのエスカレーション）に含める。
   - **`fatal: false`**: `criteria`に`mismatch`の観点が1件でもあるかを確認する（この判定は呼び出し元が`criteria`から直接行い、agentの追加出力には頼らない）。
     - **`mismatch`が0件**: 検証完了。下記「評価結果の保存」に進んでループを正常終了する。
     - **`mismatch`が1件以上かつイテレーションカウンタ < 10**: `criteria`の`mismatch`指摘をもとにコードを修正し、**検証対象のプラットフォーム・環境に応じた操作skillのアプリビルド・起動手順に従ってやり直し**、スクリーンショットを撮り直す（Androidローカルは`flutter-android-operate`2節「アプリをビルド・起動する」、Android CIは`flutter-android-operate-ci`「アプリをビルド・インストール・起動する」節、iOSローカルは`flutter-ios-operate`2節、iOS CIは`flutter-ios-operate-ci`「アプリをビルド・インストール・起動する」節。それぞれのCI/ローカルの制約に従うこと。**`nohup flutter run`を使ってよいのはローカル版だけ**で、CI版はビルド→インストール→起動のコマンド列を使う）。カウンタを+1して7-Cの2.（`ui-checker`の呼び出し）に戻る。
     - **`mismatch`が1件以上かつイテレーションカウンタ = 10**: それ以上ループしない。上限到達を理由に、直近の`criteria`を添えて依頼者へエスカレーションする。

`fatal: true`の具体例（`ui-checker`側の判断基準と共通）: 実行環境レベルの問題で改善しようがない、実装以前に破綻している仕様の瑕疵、コードの修正だけでは解決しない問題、emulator/simulatorがそもそも起動できていない。

### 評価結果の保存（Markdown + JSON）

ループが終了した時点の`ui-checker`の最終応答（JSON。`criteria`/`overall_verdict`/`fatal`/`fatal_reason`を含む）に、`compared_at`（ISO8601日時）・`reference_image`（7-Bでは`null`）・`implementation_image`・`loop_iterations`と、**呼び出し元が7-Cで導出したこのループの最終結果**を表す`loop_verdict`（`pass` / `retry_limit_reached` / `fatal`）を追加した上で、人間が読むMarkdownと、後で複数回分をスクリプト集計できるJSONの両方を、同じ内容で`.claude/screenshots/<module>/`に保存する。ファイル名は画面名を揃え、拡張子だけ変える（`<name>-compare.md` / `<name>-compare.json`）。`fatal: true`または上限到達（イテレーションカウンタ=10）でループを終えた場合も、その時点までに判明していた`criteria`を同様に保存する（`loop_verdict`はそれぞれ`fatal`/`retry_limit_reached`にする）。

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

`diff`は差分説明の自由記述（日本語）、それ以外のキー・値は英語のenumで機械可読にする。7-B（Figmaに言及が無い場合）では`figma_node_id`・`reference_image`を`null`にする。

```json
{
  "screen": "<画面名>",
  "figma_node_id": "<id、7-Bではnull>",
  "compared_at": "<ISO8601日時>",
  "reference_image": "<name>-figma.png（7-Bではnull）",
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

`fatal`/`fatal_reason`は`ui-checker`の応答をそのまま転記する。`loop_verdict`はそれとは別に、呼び出し元がこのループ全体の結末（正常終了/上限到達/エスカレーション）を表すために付与する値である点に注意する（`ui-checker`自体は`pass`/`retry`という値を返さない）。

同じ画面を複数回検証する場合は上書きせず`<name>-compare-<timestamp>.json`のように連番/日時を付けて残し、`jq`等で時系列に読み込めば「実装が近づいているか」を追跡できる。
