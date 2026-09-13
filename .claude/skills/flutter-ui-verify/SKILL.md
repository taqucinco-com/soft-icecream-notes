---
name: flutter-ui-verify
description: ローカル開発環境でAndroidエミュレータ上のicecream_log(mobile/)を実機起動し、adbでのタップ操作・スクリーンショット取得・Figmaワイヤーフレームとのチェックリストに基づく構造的比較（VLMによる一致度判定）によってUI実装の妥当性を検証する。「動作確認して」「ワイヤーフレーム通りか確認して」「実機で見た目を確認して」「Figmaとどれくらい近づいたか教えて」等の依頼で使う。依頼にiOS/シミュレータ/idbへの言及がある場合は代わりに`flutter-ui-ios-verify`スキルを、GitHub Actions CI上で実行している場合は`flutter-ui-verify-ci`スキルを使うこと（いずれもアプリの起動方法・操作コマンドが異なる）。
---

# Flutter UI検証（icecream_log / Androidエミュレータ・ローカル環境向け）

`mobile/`配下のFlutterアプリを実機（Androidエミュレータ）で起動し、adb操作とスクリーンショットで実装の見た目・挙動を検証する手順。design.mdの「Figmaワイヤーフレームとの対応関係」表にある各画面を、実装後に実際にレンダリングして確認する用途を想定している。**ローカル開発環境向け**で、`fvm`経由（`fvm flutter`/`fvm dart`）での実行を前提にしている。GitHub Actions CI上で`[ui-verify]`から呼ばれた場合は、このスキルではなく`flutter-ui-verify-ci`スキルを使うこと（アプリのビルド・起動方法だけが異なり、3節以降の手順は共通）。

## 0. 前提

- Androidエミュレータを使う（iOSシミュレータで検証する場合はこのスキルではなく`flutter-ui-ios-verify`スキルを使う）。起動コマンドは `$ANDROID_HOME/emulator/emulator -avd Medium_Phone_API_35`など。Android Emulaterは起動すると `flutter devices` で `emulator-5554` として認識される。
- スクリーンショットは必ず `.claude/screenshots/<module>/`（例: `mobile/`）配下に保存する。`mobile/`直下やリポジトリ直下には置かない（git管理対象にしないため。`.gitignore`で`.claude/screenshots/**/*.png`等が除外されている）。ディレクトリを新規作成した場合はそこにも用途を説明する`README.md`を置く。

## 1. エミュレータを起動する

まず`adb devices`で確認し、既に`emulator-5554`等が起動済みなら本節はスキップする。何も見つからない場合のみ以下を実行する。

```bash
nohup "$ANDROID_HOME/emulator/emulator" -avd Medium_Phone_API_35 > /tmp/emulator.log 2>&1 &
disown
```

起動待ちは `run_in_background` 付きBashで以下のように行い、完了通知を待つ（sleepループを直接待たない）:

```bash
until adb devices | grep -q "emulator-5554.*device$"; do sleep 2; done
```

## 2. アプリをビルド・起動する

```bash
cd mobile
nohup <flutter-cmd> run -d emulator-5554 --dart-define-from-file=.env.local > /tmp/flutter_run.log 2>&1 &
disown
```

`<flutter-cmd>`はローカルでは`fvm flutter`、CIでは`flutter`（0節参照）。以降このスキル内で「`flutter`コマンド」と書く場合はすべて同様に読み替える。

`--dart-define-from-file=.env.local`はGoogle Maps APIキー（Androidは`GOOGLE_MAP_KEY_ANDROID`）等のシークレットを読み込むために必須。省略すると地図画面（`MapScreen`）が空白のまま表示される。

**`.env.local`は`mobile/`直下にある**（雛形は`mobile/.env.sample`）。リポジトリ直下ではないので`../`を付けない。ローカルでは各自作成、CIでは`claude-android.yaml`が`mobile/.env.sample`とSecretsから生成するので、位置はローカル・CIで共通。
起動完了待ち（同じく`run_in_background`+通知待ち）:

```bash
until grep -qE "A Dart VM Service|Lost connection|Error|Exception|Gradle build failed" /tmp/flutter_run.log; do sleep 3; done
```

`nohup`でバックグラウンド化した`flutter run`にはstdinが繋がっておらず、`r`（hot reload）を送れない。コード修正を反映したい場合は該当プロセスをkillして`flutter run`をやり直す（フルビルドで15〜30秒程度）。

## 3. スクリーンショットを撮る

```bash
adb -s emulator-5554 exec-out screencap -p > .claude/screenshots/mobile/<name>.png
```

撮った画像は Read ツールで開いて目視確認する。

## 4. タップ操作 — 座標は必ずuiautomatorで正確に取る

**Readツールで表示された画像を目視して「だいたいこの位置」とピクセル座標を目算し、表示倍率だけ掛け戻して`adb shell input tap`する方法は失敗しやすい。** このセッションでも、視認による見積もりを2〜3回外し続けたことがあった（実際のカード位置が目算より数百px下にあった等）。代わりに以下の手順で正確な実座標を取得すること。

```bash
adb -s emulator-5554 shell uiautomator dump /sdcard/wd.xml
adb -s emulator-5554 pull /sdcard/wd.xml /tmp/wd.xml
grep -o 'text="対象テキスト"[^/]*bounds="\[[0-9,]*\]\[[0-9,]*\]"' /tmp/wd.xml
# または content-desc="..." で検索（SemanticsLabelが無いWidgetはtext/content-descで拾えないことがある）
```

`bounds="[x1,y1][x2,y2]"`はデバイスの実ピクセル座標そのもの（スケーリング不要）。中心 `((x1+x2)/2, (y1+y2)/2)` をそのまま`adb shell input tap`に渡す。

Semanticsラベルが無いアイコンのみのWidget（`Icon`を直接`GestureDetector`で囲っただけ等）はuiautomatorのdumpに現れないことがある。その場合は`Semantics(label: ..., child: ...)`を一時的に追加するか、素直に近傍の既知要素からの相対位置で見積もる。

## 5. タップが反応しない場合はヒットターゲットのサイズを疑う

小さいアイコン（14px角など）に直接`GestureDetector`を付けただけだと、正確な座標を渡しても物理的に当てにくく反応しないことがある（実際に本アプリの5軸評価ドットで発生し、実バグとして修正した）。

修正パターン:

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: onTap,
  child: SizedBox(
    width: 32,
    height: 32,
    child: Center(child: Icon(..., size: 14)),
  ),
),
```

タップが繰り返し無反応な場合、コードのロジックを疑う前に、まずこのパターンでヒットエリアを拡大して切り分けること。

## 6. よくある環境要因の落とし穴

- **`INSTALL_FAILED_INSUFFICIENT_STORAGE`**: エミュレータの`/data`が埋まりやすい（プリインストールアプリ込みで数GB中数百MBしか空きが無いことがある）。`adb -s emulator-5554 shell df /data`で確認し、埋まっていたら`adb -s emulator-5554 emu kill`してから`-wipe-data`付きで再起動する。
- **プリインストールアプリの無関係なダイアログ**（例: "Messages isn't responding"）が前面に被ることがある。スクリーンショットに見慣れないダイアログが写っていたら、まずそれを閉じてから本来の検証を続ける。

## 7. 画面の評価とui-verify-judgeによるループ

評価そのものは専任agent`ui-verify-judge`（Android/iOS・ローカル/CI共通、判定のみで副作用ゼロ）に委ね、本体のClaude（このskillを実行している自分自身）はその判定結果をもとに「コード修正→再ビルド→再検証」のループを回す。その場の印象で「だいたい合っている/動いている」と済ませたり、`ui-verify-judge`を介さず自分で評価を確定させたりしないこと。**Figmaとの比較（7-A）を行うのは、依頼文で「Figma」「ワイヤーフレーム」「デザイン通り」など、Figmaへの言及が明示的にある場合に限る。** 言及が無い場合はFigmaを呼び出さず、7-Bの単純な構造分析を行う。ループの制御自体は7-Cで扱う。

### 7-A. Figmaに言及がある場合: Figmaワイヤーフレームとの比較materialを用意する

#### 手順

1. design.mdの「Figmaワイヤーフレームとの対応関係」表で、検証したい画面に対応するnode-idを確認する。
2. Figma MCPの`get_screenshot`（`figma-use`系スキルは不要、読み取りのみなので直接呼び出してよい）でそのnode-idのリファレンス画像を取得し、`.claude/screenshots/<module>/<name>-figma.png`として保存する（＝「目指すべき成果物」）。
3. 同じnode-idについて`get_metadata`も呼び出し、各要素のid・name・x/y/width/heightを含む構造情報（下記のようなXML）を取得する。

   ```xml
   <frame id="13:76" name="Navigation" x="627" y="50" width="673" height="149">
     <frame id="13:28" name="Text" x="50" y="63" width="378" height="23">
   ```

   これは「要素の有無」「配置・順序」を画像の目視だけに頼らず、要素名・座標という客観的な情報で裏付けるために使う。
4. 3節の手順で実機の現状スクリーンショットを`.claude/screenshots/<module>/<name>-app.png`として保存する（＝「現状」）。あわせて4節の`uiautomator dump`でアプリ側の構造（text/content-desc/bounds）も取得しておくと、Figmaの`get_metadata`と直接突き合わせられる。
5. 画像パス（`<name>-figma.png`/`<name>-app.png`）とメタデータが揃ったら7-Cに進み、`ui-verify-judge`に渡して判定させる。「比較対象」はFigmaのリファレンス（画像・`get_metadata`）であることを7-Cの呼び出しで明示する。

### 7-B. Figmaに言及が無い場合: 単純な構造分析の材料を用意する

Figmaは呼び出さず、実機のスクリーンショットと`uiautomator dump`で得られる構造だけを根拠に、**依頼文で言及された確認内容（例:「マップタブに切り替えたら地図が表示されるはず」「一覧にカードが並んでいるはず」等）に実装がどの程度応えているか**を`ui-verify-judge`に判定させる。依頼文がUIの構造や見た目に触れていない場合（例: 単に「起動確認して」）は、クラッシュ・白画面・意図しないダイアログの有無など、最低限の起動確認のみでよい。

#### 手順

1. 3節の手順で実機のスクリーンショットを`.claude/screenshots/<module>/<name>-app.png`として保存する。
2. 4節の`uiautomator dump`でアプリの構造（text/content-desc/bounds）を取得する。
3. 画像パスと構造情報が揃ったら7-Cに進み、`ui-verify-judge`に渡して判定させる。「比較対象」はFigmaではなく依頼文で示された期待であることを7-Cの呼び出しで明示する。

### 7-C. `ui-verify-judge`を呼び出し、ループする

1. イテレーションカウンタを1にする（この会話内で本体のClaudeが保持する。`ui-verify-judge`自体は状態を持たない）。
2. `Task`ツールで`subagent_type: ui-verify-judge`を呼び出す。7-A/7-Bで用意した画像パス、（7-Aの場合）Figmaの構造情報、比較対象の期待（Figmaまたは依頼文）を渡す。
3. 応答のJSON中の`loop_verdict`で分岐する。
   - **`pass`**: 検証完了。下記「評価結果の保存」に進んでループを正常終了する（重大な指摘は0件）。
   - **`fatal`**: 直ちにループを中断する。それ以上コードの修正・再ビルドを試みず、`fatal_reason`と直近の`criteria`をそのまま依頼者への報告（人間へのエスカレーション）に含める。
   - **`retry`かつイテレーションカウンタ < 10**: `criteria`の`mismatch`指摘をもとにコードを修正し、2節（アプリをビルド・起動する）以降をやり直してスクリーンショットを撮り直す。カウンタを+1して2に戻る。
   - **`retry`かつイテレーションカウンタ = 10**: それ以上ループしない。上限到達を理由に、直近の`criteria`を添えて依頼者へエスカレーションする。

`fatal`の具体例（`ui-verify-judge`側の判断基準と共通）: 実行環境レベルの問題で改善しようがない、実装以前に破綻している仕様の瑕疵、コードの修正だけでは解決しない問題、emulator/simulatorがそもそも起動できていない。

### 評価結果の保存（Markdown + JSON）

`pass`でループが終了した時点の`ui-verify-judge`の最終応答（JSON）に`compared_at`（ISO8601日時）・`reference_image`（7-Bでは`null`）・`implementation_image`を追加した上で、人間が読むMarkdownと、後で複数回分をスクリプト集計できるJSONの両方を、同じ内容で`.claude/screenshots/<module>/`に保存する。ファイル名は画面名を揃え、拡張子だけ変える（`<name>-compare.md` / `<name>-compare.json`）。`fatal`または上限到達でループを終えた場合も、その時点までに判明していた`criteria`を同様に保存する。

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
  "loop_verdict": "pass",
  "fatal_reason": null,
  "loop_iterations": 1
}
```

同じ画面を複数回検証する場合は上書きせず`<name>-compare-<timestamp>.json`のように連番/日時を付けて残し、`jq`等で時系列に読み込めば「実装が近づいているか」を追跡できる。
