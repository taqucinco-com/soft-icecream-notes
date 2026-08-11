---
name: flutter-ui-verify
description: Androidエミュレータ上でicecream_log(mobile/)を実機起動し、adbでのタップ操作・スクリーンショット取得・Figmaワイヤーフレームとの視覚比較によってUI実装の妥当性を検証する。「動作確認して」「ワイヤーフレーム通りか確認して」「実機で見た目を確認して」等の依頼で使う。
---

# Flutter UI検証（icecream_log / Androidエミュレータ）

`mobile/`配下のFlutterアプリを実機（Androidエミュレータ）で起動し、adb操作とスクリーンショットで実装の見た目・挙動を検証する手順。design.mdの「Figmaワイヤーフレームとの対応関係」表にある各画面を、実装後に実際にレンダリングして確認する用途を想定している。

## 0. 前提

- Androidエミュレータを使う（iOSシミュレータは使わない）。起動コマンドは `$ANDROID_HOME/emulator/emulator -avd Medium_Phone_API_35`。起動すると `emulator-5554` として認識される。
- スクリーンショットは必ず `.claude/screenshots/<module>/`（例: `mobile/`）配下に保存する。`mobile/`直下やリポジトリ直下には置かない（git管理対象にしないため。`.gitignore`で`.claude/screenshots/**/*.png`等が除外されている）。ディレクトリを新規作成した場合はそこにも用途を説明する`README.md`を置く。

## 1. エミュレータを起動する

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
nohup fvm flutter run -d emulator-5554 > /tmp/flutter_run.log 2>&1 &
disown
```

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

## 7. Figmaワイヤーフレームとの比較

1. design.mdの「Figmaワイヤーフレームとの対応関係」表で、検証したい画面に対応するnode-idを確認する。
2. Figma MCPの`get_screenshot`（`figma-use`系スキルは不要、読み取りのみなので直接呼び出してよい）でそのnode-idのリファレンス画像を取得する。
3. 実機のスクリーンショットと並べて、要素の有無・大まかな配置・テキスト内容が一致しているかを確認する。ピクセル単位の一致は求めない（レイアウトの意図が再現されていればよい）。
4. 差異を見つけたら、実装を直すかdesign.md側の記述を直すか判断し、両方を一致させる。
