---
name: flutter-android-operate
description: ローカル開発環境でAndroidエミュレータ上のicecream_log(mobile/)を実機起動し、adbでのタップ操作・スクリーンショット取得を行う共通手順。UI検証のmaker/checker等、Androidエミュレータの操作が必要な複数のスキル・agentから共通で参照される。CI環境では代わりに`flutter-android-operate-ci`を使う。
---

# Flutter Android操作（icecream_log / エミュレータ・ローカル環境向け）

`mobile/`配下のFlutterアプリを実機（Androidエミュレータ）で起動し、adb操作とスクリーンショットで実装の見た目・挙動を確認するための共通手順。**アプリを起動して操作する方法だけを扱い、その結果（スクリーンショットや構造情報）をどう評価するかはこのスキルの範囲外**（呼び出し元のスキル・agentが行う）。**ローカル開発環境向け**で、`fvm`経由（`fvm flutter`/`fvm dart`）での実行を前提にしている。GitHub Actions CI上では`fvm`が無い等の理由でアプリの起動方法が異なるため、このスキルではなく`flutter-android-operate-ci`を使うこと（3節以降の操作手順は共通）。

## 0. 前提

- Androidエミュレータを使う（iOSシミュレータの場合は`flutter-ios-operate`を使う）。起動コマンドは `$ANDROID_HOME/emulator/emulator -avd Medium_Phone_API_35`など。Android Emulatorは起動すると `flutter devices` で `emulator-5554` として認識される。
- スクリーンショットは必ず `work/screenshots/<module>/`（例: `mobile/`）配下に保存する。`mobile/`直下やリポジトリ直下には置かない（`.gitignore`で`/work/`配下がまるごと除外されている）。

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
nohup fvm flutter run -d emulator-5554 --dart-define-from-file=.env.local > /tmp/flutter_run.log 2>&1 &
disown
```

`--dart-define-from-file=.env.local`はGoogle Maps APIキー（Androidは`GOOGLE_MAP_KEY_ANDROID`）等のシークレットを読み込むために必須。省略すると地図画面（`MapScreen`）が空白のまま表示される。

**`.env.local`は`mobile/`直下にある**（雛形は`mobile/.env.sample`）。リポジトリ直下ではないので`../`を付けない。

起動完了待ち（同じく`run_in_background`+通知待ち）:

```bash
until grep -qE "A Dart VM Service|Lost connection|Error|Exception|Gradle build failed" /tmp/flutter_run.log; do sleep 3; done
```

`nohup`でバックグラウンド化した`flutter run`にはstdinが繋がっておらず、`r`（hot reload）を送れない。コード修正を反映したい場合は該当プロセスをkillして`flutter run`をやり直す（フルビルドで15〜30秒程度）。

## 3. スクリーンショットを撮る

```bash
mkdir -p work/screenshots/mobile
adb -s emulator-5554 exec-out screencap -p > work/screenshots/mobile/<name>.png
```

`cd mobile`した状態のままだと相対パスが`mobile/work/screenshots/`に書き込まれてしまう。リポジトリ直下からの絶対パスで書くか、事前に`cd`で戻ってから実行すること。

撮った画像は Read ツールで開いて目視確認する。

## 4. タップ操作 — 座標は必ずuiautomatorで正確に取る

**Readツールで表示された画像を目視して「だいたいこの位置」とピクセル座標を目算し、表示倍率だけ掛け戻して`adb shell input tap`する方法は失敗しやすい。** 視認による見積もりを2〜3回外し続けたことがあった（実際のカード位置が目算より数百px下にあった等）。代わりに以下の手順で正確な実座標を取得すること。

```bash
adb -s emulator-5554 shell uiautomator dump /sdcard/wd.xml
adb -s emulator-5554 pull /sdcard/wd.xml work/wd.xml
grep -o 'text="対象テキスト"[^/]*bounds="\[[0-9,]*\]\[[0-9,]*\]"' work/wd.xml
# または content-desc="..." で検索（SemanticsLabelが無いWidgetはtext/content-descで拾えないことがある）
```

保存先は作業ディレクトリ配下の`work/wd.xml`にすること（`.gitignore`で`/work/`配下は除外済み）。Bashツールのサンドボックスは作業ディレクトリとセッション専用`$TMPDIR`にのみ書き込みを許可する仕様のため、裸の`/tmp`直下は対象外（詳細は[`/sandbox`ドキュメント](https://code.claude.com/docs/en/sandboxing)の「Temporary directories」参照）。`cd mobile`した状態のままだと相対パスが`mobile/work/wd.xml`に書き込まれてしまう点は3節のスクリーンショット保存と同様に注意すること。

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
