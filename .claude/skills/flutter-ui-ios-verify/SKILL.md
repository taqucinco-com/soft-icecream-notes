---
name: flutter-ui-ios-verify
description: ローカル開発環境でiOSシミュレータ上のicecream_log(mobile/)を起動し、idb（タップ・要素ツリー取得）とxcrun simctl（スクリーンショット）でUI実装の妥当性を検証する。「iOSで動作確認して」「シミュレータで見た目を確認して」「iOSでワイヤーフレーム通りか確認して」等、iOS/シミュレータ/idbへの言及がある依頼で使う。Androidエミュレータで検証する場合は`flutter-ui-android-verify`、GitHub Actions CI上では`flutter-ui-android-verify-ci`を使う。
---

# Flutter UI検証（icecream_log / iOSシミュレータ・ローカル環境向け）

`mobile/`配下のFlutterアプリをiOSシミュレータ上で検証する手順。`flutter-ui-android-verify`（Androidエミュレータ版）のiOS版で、評価の進め方（画面の評価とui-checkerによるループ）は両者で共通なのでAndroid版スキルを参照する。

シミュレータの起動・idb接続・アプリのビルド起動・スクリーンショット撮影・要素取得とタップ・ヒットターゲットのデバッグ・座標系の注意点・環境要因の落とし穴は、このスキルではなく`flutter-ios-operate`スキル（`.claude/skills/flutter-ios-operate/SKILL.md`）を使う。このスキルは、その操作結果を「評価」してループを回す部分だけを扱う（重複して定義しない）。

## 前提

- iOSシミュレータで検証する（Androidエミュレータの場合は`flutter-ui-android-verify`スキルを使う）。
- アプリの起動・操作は`flutter-ios-operate`skillに従う。`simctl`/`idb`がBashツールのサンドボックス内で動かない点（`dangerouslyDisableSandbox: true`が必要）も同skill側を参照。
- スクリーンショットの保存先は`flutter-ios-operate`skillの指示（`.claude/screenshots/<module>/`）に従う。

## 画面の評価とui-checkerによるループ

**評価とその後のループの手順・チェックリスト・判定基準・`ui-checker`agentの呼び出し方は`flutter-ui-android-verify`スキルと完全に共通なので、`.claude/skills/flutter-ui-android-verify/SKILL.md`の「画面の評価とui-checkerによるループ」節をそのまま参照して実施すること。** ここで重複して定義しない（片方だけ更新されて食い違うのを避けるため）。結果の保存形式（Markdown + JSON）は`flutter-ui-verify-result-save`スキルを使う（Android/iOS・ローカル/CI共通）。`ui-checker`agent自体もAndroid/iOS共通の1つを使う。

参照する際、Android向けの記述は以下のように読み替える。

| Android版スキルの記述 | iOSでの読み替え |
|---|---|
| `adb exec-out screencap`（`flutter-android-operate`3節） | `xcrun simctl io <UDID> screenshot`（`flutter-ios-operate`3節） |
| `uiautomator dump`でtext/content-desc/boundsを取得（`flutter-android-operate`4節） | `idb ui describe-all`でtype/AXLabel/frameを取得（`flutter-ios-operate`4節） |
| boundsは実ピクセル | frameはポイント。スクリーンショットのピクセルとは別座標系（`flutter-ios-operate`4節） |

要点だけ再掲すると:

- 依頼文に「Figma」「ワイヤーフレーム」「デザイン通り」等の言及がある場合のみFigma MCPでリファレンスを取得して比較する（7-A）。言及が無ければFigmaは呼ばず、依頼文で示された期待に対する構造分析を行う（7-B）。
- いずれの場合も7-Cで`ui-checker`agentを呼び出し、「画面構成 / 要素の有無 / 配置・順序 / テキスト・ラベル内容 / 状態表現」の5観点の判定・総合判定に加えて`fatal`/`fatal_reason`を得る（`ui-checker`は`pass`/`retry`という値自体は返さない）。`fatal: true`なら直ちに中断して人間にエスカレーションする。`fatal: false`の場合は、`criteria`にmismatchが1件でもあればコードを修正して`flutter-ios-operate`skillの2節「アプリをビルド・起動する」からやり直し（最大10回）、無ければ正常終了する。
- 結果は`.claude/screenshots/mobile/<name>-compare.md`と`<name>-compare.json`の両方に保存する。
