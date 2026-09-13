---
name: flutter-ui-ios-verify
description: ローカル開発環境でiOSシミュレータ上のicecream_log(mobile/)を起動し、idb（タップ・要素ツリー取得）とxcrun simctl（スクリーンショット）でUI実装の妥当性を検証する。「iOSで動作確認して」「シミュレータで見た目を確認して」「iOSでワイヤーフレーム通りか確認して」等、iOS/シミュレータ/idbへの言及がある依頼で使う。Androidエミュレータで検証する場合は`flutter-ui-verify`、GitHub Actions CI上では`flutter-ui-verify-ci`を使う。
---

# Flutter UI検証（icecream_log / iOSシミュレータ・ローカル環境向け）

`mobile/`配下のFlutterアプリをiOSシミュレータで起動し、`idb`と`xcrun simctl`で実装の見た目・挙動を検証する手順。`flutter-ui-verify`（Androidエミュレータ版）のiOS版で、**操作ツールが`adb`から`idb`/`simctl`に変わる点だけが異なる**。評価の進め方（7節）は両者で共通なので、Android版スキルを参照する。

ローカル開発環境向けで、`fvm`経由（`fvm flutter`）での実行を前提にしている。

## 0. 前提

- iOSシミュレータを使う。`idb`（`idb-companion`含む）とXcodeがセットアップ済みであること（手順はリポジトリ直下の`README.md`「AI agentが直接iOS Simulatorと対話する」節）。
- **`simctl`と`idb`はBashツールのサンドボックス内では動かない。** 必ず`dangerouslyDisableSandbox: true`で実行すること。サンドボックスは`CoreSimulatorService`へのXPC接続と`/tmp/idb/state.lock`の作成を遮断するため、以下のようなエラーになる（アプリやシミュレータ側の異常ではない）。

  ```
  # simctl
  CoreSimulatorService connection became invalid. Simulator services will no longer be available.
  Unable to locate device set: ... Code=61 "Connection refused"
  # idb
  PermissionError: [Errno 1] Operation not permitted: '/tmp/idb/state.lock'
  ```

- スクリーンショットは必ず `.claude/screenshots/<module>/`（例: `mobile/`）配下に保存する。`mobile/`直下やリポジトリ直下には置かない（`.gitignore`で`.claude/screenshots/**/*.png`等が除外されている）。

## 1. シミュレータを起動し、idbを接続する

まず起動済みのシミュレータとidbの接続状態を確認する。

```bash
xcrun simctl list devices booted
idb list-targets | grep Booted
```

`idb list-targets`の行末が`No Companion Connected`ではなく`/tmp/idb/<UDID>_companion.sock`になっていれば接続済み。以降の手順はこのUDIDを使う。Bashツールはシェル状態を保持しないので、UDIDは各コマンドに直接書くか、コマンドごとに取得する。

```bash
UDID=$(xcrun simctl list devices booted -j | jq -r '.devices[][0].udid')
```

起動していない場合:

```bash
xcrun simctl boot <UDID>   # 例: iPhone 17
open -a Simulator
idb connect <UDID>
```

`idb connect`はシミュレータを再起動するたびに必要になる。操作系コマンドが`No Companion Connected`や接続エラーで失敗したら、まずこれを疑う。

## 2. アプリをビルド・起動する

```bash
cd mobile
nohup fvm flutter run -d <UDID> --dart-define-from-file=.env.local > /tmp/flutter_run_ios.log 2>&1 &
disown
```

注意点:

- **`-d <UDID>`は必ず明示する。** この開発機には物理iPhoneがネットワーク越しに接続されていることがあり（`flutter devices`に`sudo iPhone17 (wireless)`として現れる）、デバイス指定を省くと実機側にデプロイされうる。
- **`.env.local`は`mobile/`直下にある**（`mobile/.env.sample`が雛形）。リポジトリ直下ではない。
- iOSの地図キーは`GOOGLE_MAP_KEY_ANDROID`ではなく**`GOOGLE_MAP_KEY_IOS`**（キーはプラットフォームごとに分かれている）。`mobile/ios/Runner/AppDelegate.swift`がInfo.plistの`DartDefines`経由で読む仕組みのため、**ビルド時に埋め込まれる**。キーを変えた場合はhot restartでは反映されず、ビルドし直しが必要。省略・誤りがあると地図画面（`MapScreen`）が空白になる。
- 初回やPods更新後は、README記載の事前ビルドが必要になることがある。

  ```bash
  cd mobile && fvm flutter build ios --dart-define-from-file=.env.local
  ```

起動完了待ちは`run_in_background`付きBashで行い、完了通知を待つ（sleepループを直接待たない）:

```bash
until grep -qE "A Dart VM Service|Lost connection|Error|Exception|Xcode build done|Could not build" /tmp/flutter_run_ios.log; do sleep 3; done
```

`nohup`でバックグラウンド化した`flutter run`にはstdinが繋がっておらず、`r`（hot reload）を送れない。コード修正を反映したい場合は該当プロセスをkillして`flutter run`をやり直す。

## 3. スクリーンショットを撮る

```bash
xcrun simctl io <UDID> screenshot .claude/screenshots/mobile/<name>.png
```

READMEにある`xcrun simctl screenshot <path>`という短縮形は**存在しないサブコマンド**で、usageが表示されるだけなので使わない（`io <UDID> screenshot`が正）。

撮った画像は Read ツールで開いて目視確認する。

## 4. 要素の取得とタップ — 座標を目算しない

Androidの`uiautomator dump`に相当するのが`idb ui describe-all`で、画面全体のアクセシビリティツリーをJSONで返す。`jq`で要素名と座標の一覧にすると読みやすい。

```bash
idb ui describe-all --udid <UDID> \
  | jq -r '.[] | select(.AXLabel != null) | "\(.type)\t\(.AXLabel)\t\(.frame.x),\(.frame.y) \(.frame.width)x\(.frame.height)"'
```

```
Application	Icecream Log	0,0 402x874
Heading	設定	179,76 44x28
Button	アイコンを変更	140.2,230 121.6x48
StaticText	メモ一覧	70.6,818.5 45x40
```

特定の要素だけ見たい場合:

```bash
idb ui describe --udid <UDID> --match-key AXLabel "マップ"
```

### タップはラベル指定が第一選択

`idb ui tap`は座標だけでなく**アクセシビリティマーカー（文字列）**を直接受け取れる。座標計算を挟まない分こちらが確実なので、ラベルが取れる要素にはこれを使う。

```bash
idb ui tap --udid <UDID> --match-key AXLabel "メモ一覧"
```

座標でタップする場合は`describe-all`の`frame`の中心（`x + width/2`, `y + height/2`）をそのまま渡す。

```bash
idb ui tap --udid <UDID> 93 838
```

### 座標系の罠: スクリーンショットはピクセル、idbはポイント

**スクリーンショット画像の座標とidbに渡す座標は一致しない。** iPhone 17では画像が1206x2622ピクセル、`describe-all`/`tap`が扱うのは402x874ポイントで、**3倍のずれ**がある（Androidの`uiautomator`のboundsが実ピクセルそのままだったのとは異なる）。

そのため、**スクリーンショットを目視してピクセル座標を目算し、そのまま`idb ui tap`に渡すのは必ず失敗する。** 座標は`describe-all`の`frame`から取り、画像から読む必要がある場合のみ`ピクセル ÷ スケール（Retina系は3、一部は2）`で換算する。スケールは`スクリーンショットの幅 ÷ describe-allのApplication要素のframe.width`で確認できる。

### ラベルが取れない要素

Flutterの`Semantics`ラベルが無いアイコンのみのWidgetは`describe-all`に現れないことがある（Androidの`uiautomator dump`と同じ制約）。その場合は`Semantics(label: ..., child: ...)`を一時的に追加するか、近傍の既知要素からの相対位置で見積もる。座標が分かっている点に何があるかは`idb ui describe-point <x> <y>`で逆引きできる。

### その他の操作

`idb ui`のサブコマンドで一通りの操作ができる: `swipe` / `scroll` / `text`（文字入力） / `key` / `button`（ホームボタン等） / `multi-tap` / `pinch` / `drag-and-drop` / `rotate`。詳細は`idb ui <subcommand> --help`。

## 5. タップが反応しない場合はヒットターゲットのサイズを疑う

小さいアイコン（14px角など）に直接`GestureDetector`を付けただけだと、正確な座標を渡しても反応しないことがある（本アプリの5軸評価ドットで実際に発生し、実バグとして修正した）。

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

タップが繰り返し無反応な場合、コードのロジックを疑う前に、まず座標系（4節）とこのヒットエリア拡大で切り分けること。なお`idb ui tap`の`--api`は、マーカー指定時が`ax`（アクセシビリティ経由の押下）、座標指定時が既定で`hid`（実際のタッチイベント）になる。**`ax`はヒットエリアの問題を迂回してしまう**ため、ヒットエリアの不具合を再現・検証したいときは座標指定（`hid`）で確認する。

## 6. よくある環境要因の落とし穴

- **`simctl`/`idb`のサンドボックスエラー**: 0節の通り`dangerouslyDisableSandbox: true`が必要。接続エラーを見たら、まずシミュレータの異常ではなくこれを疑う。
- **`idb connect`の切れ**: シミュレータ再起動やマシンのスリープ後に`No Companion Connected`になる。`idb connect <UDID>`で再接続する。
- **物理iPhoneへの誤デプロイ**: 2節の通り`-d <UDID>`を省略しない。
- **シミュレータの状態汚れ**: `xcrun simctl erase <UDID>`で初期化できる（起動中なら`shutdown`してから）。アプリだけ入れ直したい場合は`xcrun simctl uninstall <UDID> com.taqucinco.softicecreamnotes.icecreamLog`。
- **ビルドが通らない**: iOSはPods起因の失敗が多い。`cd mobile/ios && pod install`、それでも駄目なら`fvm flutter clean`を試す。

## 7. 画面の評価とui-verify-judgeによるループ

**評価とその後のループの手順・チェックリスト・判定基準・`ui-verify-judge`agentの呼び出し方・結果の保存形式（Markdown + JSON）は`flutter-ui-verify`スキルと完全に共通なので、`.claude/skills/flutter-ui-verify/SKILL.md`の7節をそのまま参照して実施すること。** ここで重複して定義しない（片方だけ更新されて食い違うのを避けるため）。`ui-verify-judge`agent自体もAndroid/iOS共通の1つを使う。

参照する際、Android向けの記述は以下のように読み替える。

| Android版スキルの記述 | iOSでの読み替え |
|---|---|
| `adb exec-out screencap` | `xcrun simctl io <UDID> screenshot`（3節） |
| `uiautomator dump`でtext/content-desc/boundsを取得 | `idb ui describe-all`でtype/AXLabel/frameを取得（4節） |
| boundsは実ピクセル | frameはポイント。スクリーンショットのピクセルとは別座標系（4節） |

要点だけ再掲すると:

- 依頼文に「Figma」「ワイヤーフレーム」「デザイン通り」等の言及がある場合のみFigma MCPでリファレンスを取得して比較する（7-A）。言及が無ければFigmaは呼ばず、依頼文で示された期待に対する構造分析を行う（7-B）。
- いずれの場合も7-Cで`ui-verify-judge`agentを呼び出し、「画面構成 / 要素の有無 / 配置・順序 / テキスト・ラベル内容 / 状態表現」の5観点の判定・総合判定に加えて`loop_verdict`（`pass`/`retry`/`fatal`）を得る。`retry`ならコードを修正して2節からやり直し（最大10回）、`fatal`なら直ちに中断して人間にエスカレーションする。
- 結果は`.claude/screenshots/mobile/<name>-compare.md`と`<name>-compare.json`の両方に保存する。
