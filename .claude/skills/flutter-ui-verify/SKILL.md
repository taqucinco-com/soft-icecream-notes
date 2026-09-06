---
name: flutter-ui-verify
description: Androidエミュレータ上でicecream_log(mobile/)を実機起動し、adbでのタップ操作・スクリーンショット取得・Figmaワイヤーフレームとのチェックリストに基づく構造的比較（VLMによる一致度判定）によってUI実装の妥当性を検証する。「動作確認して」「ワイヤーフレーム通りか確認して」「実機で見た目を確認して」「Figmaとどれくらい近づいたか教えて」等の依頼で使う。
---

# Flutter UI検証（icecream_log / Androidエミュレータ）

`mobile/`配下のFlutterアプリを実機（Androidエミュレータ）で起動し、adb操作とスクリーンショットで実装の見た目・挙動を検証する手順。design.mdの「Figmaワイヤーフレームとの対応関係」表にある各画面を、実装後に実際にレンダリングして確認する用途を想定している。

## 0. 前提

- Androidエミュレータを使う（iOSシミュレータは使わない）。起動コマンドは `$ANDROID_HOME/emulator/emulator -avd Medium_Phone_API_35`など。Android Emulaterは起動すると `flutter devices` で `emulator-5554` として認識される。
- スクリーンショットは必ず `.claude/screenshots/<module>/`（例: `mobile/`）配下に保存する。`mobile/`直下やリポジトリ直下には置かない（git管理対象にしないため。`.gitignore`で`.claude/screenshots/**/*.png`等が除外されている）。ディレクトリを新規作成した場合はそこにも用途を説明する`README.md`を置く。
- CI（GitHub Actions、`.github/workflows/claude.yml`）で`@claude`コメントに`[ui-verify]`を含めて実行された場合、ワークフロー側で既にAndroidエミュレータのセットアップ・起動・`flutter pub get`/コード生成まで完了した状態でこのスキルが呼ばれる。CIでは`fvm`はインストールされていないため、`flutter`/`dart`コマンドをそのまま使う（`fvm flutter`/`fvm dart`ではない）。ローカル開発環境では`fvm`経由（`fvm flutter`/`fvm dart`）で実行する。
- どちらの環境かは`fvm --version`が通るかで判定できる。迷ったら先に`adb devices`を実行し、既に起動済みのデバイスがあればそれを使う（＝1節の起動手順を省略してよい）。

## 1. エミュレータを起動する（ローカルのみ。CIでは既に起動済みなので不要）

まず`adb devices`で確認し、既に`emulator-5554`等が起動済みなら本節はスキップする（CI実行時は常にこのケースに該当する）。何も見つからない場合のみ以下を実行する。

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
nohup <flutter-cmd> run -d emulator-5554 --dart-define-from-file=../.env.local > /tmp/flutter_run.log 2>&1 &
disown
```

`<flutter-cmd>`はローカルでは`fvm flutter`、CIでは`flutter`（0節参照）。以降このスキル内で「`flutter`コマンド」と書く場合はすべて同様に読み替える。

`--dart-define-from-file=../.env.local`はGoogle Maps APIキー（`GOOGLE_MAP_KEY`）等のシークレットを読み込むために必須（リポジトリ直下の`.env.local`を参照。ローカルでは各自作成、CIでは`claude.yml`が`secrets.GOOGLE_MAP_KEY`から生成済み）。省略すると地図画面（`MapScreen`）が空白のまま表示される。

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

## 7. Figmaワイヤーフレームとの構造的比較（VLMによる評価）

画像を並べて眺めるだけでなく、決まったチェックリストに沿って構造化した比較を行い、「実装がワイヤーフレームにどれだけ近づいたか」を毎回同じ基準で判定できるようにする。

### 手順

1. design.mdの「Figmaワイヤーフレームとの対応関係」表で、検証したい画面に対応するnode-idを確認する。
2. Figma MCPの`get_screenshot`（`figma-use`系スキルは不要、読み取りのみなので直接呼び出してよい）でそのnode-idのリファレンス画像を取得し、`.claude/screenshots/<module>/<name>-figma.png`として保存する（＝「目指すべき成果物」）。
3. 3節の手順で実機の現状スクリーンショットを`.claude/screenshots/<module>/<name>-app.png`として保存する（＝「現状」）。
4. 両方をReadツールで開き、以下のチェックリストに沿って評価する。目視の印象だけで「だいたい合っている」と済ませない。

### 評価観点（チェックリスト）

| 観点 | 見るもの |
|---|---|
| 画面構成 | ヘッダー/本文/フッター(ボトムナビ)などの大枠セクションが同じ数・同じ並びで存在するか |
| 要素の有無 | ワイヤーフレームに描かれた個々の要素（タイトル、ボタン、チップ、カード、チャート等）が実装側にすべて存在するか。過不足を具体的に列挙する |
| 配置・順序 | 各要素の相対的な位置関係（上下左右の並び順）が一致しているか。px単位の一致までは求めない |
| テキスト/ラベル内容 | ボタンラベルや見出しの文言が一致しているか |
| 状態表現 | 空状態・未入力状態・選択状態など、ワイヤーフレームが示す状態が実装でも再現されているか（対象外なら「該当なし」） |

各観点は「一致 / 軽微な差異 / 不一致 / 該当なし」の4段階で判定し、「一致」以外は具体的な差分を書く。

### 総合判定

観点ごとの判定を踏まえ、以下のいずれか1つを選ぶ。

- **完全一致**: 全観点が「一致」
- **ほぼ一致**: 軽微な差異のみ（余白・色味・アイコン種類など実装の裁量範囲内の違い）
- **部分一致**: 構造は合っているが要素の過不足・配置の違いがある
- **大きく乖離**: 主要な構造（セクション数や画面遷移の前提）から異なる

「部分一致」「大きく乖離」の場合は、実装を直すべきかdesign.md側の記述を直すべきかをこの場で判断し、両者を一致させる。

### 比較結果の保存（Markdown + JSON）

人間が読むMarkdownと、後で複数回分をスクリプト集計できるJSONの両方を、同じ内容で`.claude/screenshots/<module>/`に保存する。ファイル名は画面名を揃え、拡張子だけ変える（`<name>-compare.md` / `<name>-compare.json`）。

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

`diff`は差分説明の自由記述（日本語）、それ以外のキー・値は英語のenumで機械可読にする。

```json
{
  "screen": "<画面名>",
  "figma_node_id": "<id>",
  "compared_at": "<ISO8601日時>",
  "reference_image": "<name>-figma.png",
  "implementation_image": "<name>-app.png",
  "criteria": [
    { "aspect": "layout_structure", "verdict": "match", "diff": null },
    { "aspect": "element_presence", "verdict": "minor_diff", "diff": "○○ボタンが未実装" },
    { "aspect": "arrangement_order", "verdict": "match", "diff": null },
    { "aspect": "text_labels", "verdict": "match", "diff": null },
    { "aspect": "state_representation", "verdict": "not_applicable", "diff": null }
  ],
  "overall_verdict": "close_match"
}
```

同じ画面を複数回検証する場合は上書きせず`<name>-compare-<timestamp>.json`のように連番/日時を付けて残し、`jq`等で時系列に読み込めば「実装が近づいているか」を追跡できる。
