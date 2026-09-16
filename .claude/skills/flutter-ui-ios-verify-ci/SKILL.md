---
name: flutter-ui-ios-verify-ci
description: GitHub Actions CI上でiOS Simulator上のicecream_log(mobile/)についてFigmaワイヤーフレームまたは依頼内容とのUI実装の妥当性をVLM判定でループ検証する。`.github/workflows/claude-ios.yaml`から使う。アプリの起動・タップ操作・スクリーンショット取得は`flutter-ios-operate-ci`スキルに委ねる。
---

# Flutter UI検証（CI/iOS Simulator向け）

`flutter-ui-ios-verify`スキルのCI環境向け版。アプリの起動・操作は`flutter-ios-operate-ci`スキル（`.claude/skills/flutter-ios-operate-ci/SKILL.md`）に委ねており、このスキルは画面の評価・ループ制御だけを扱う（重複して定義しない）。

## 前提

- アプリの起動・タップ操作・スクリーンショット撮影は`flutter-ios-operate-ci`スキルを使う。CI固有の制約（`fvm`が無い、`nohup`が使えない、`simctl`/`idb`のサンドボックス制約等）や、なぜiOSローカル版（`flutter-ios-operate`）をそのまま使わず別スキルにしたかも同スキル側を参照。
- スクリーンショットおよび評価結果（`<name>-compare.md`/`<name>-compare.json`）の保存先は、`.claude/screenshots/mobile/`ではなく`flutter-ios-operate-ci`skillの指示に従い`work/screenshots/`を使う（`.claude/`配下への書き込みはCIのサンドボックスで拒否されるため）。

## スクリーンショットの視覚的分析（VLMによる評価・JSON）

評価とその後のループは、`flutter-ui-ios-verify`skill（および参照先の`flutter-ui-android-verify`skill）の「画面の評価とui-checkerによるループ」節の手順・チェックリスト・`ui-checker`agentの呼び出し方・JSON形式（`criteria`配列、`overall_verdict`、`fatal`/`fatal_reason`等）をそのまま使うこと。**CI固有の差分は保存先パスのみで、スクリーンショット画像だけでなく`<name>-compare.md`/`<name>-compare.json`（評価結果）も含めて、`.claude/screenshots/mobile/`ではなくすべて`work/screenshots/`に保存する**（`.claude/`配下への書き込みはCIのサンドボックスで拒否されるため）。

7-A/7-B/7-Cの分岐もそのまま踏襲する。**依頼コメントで「Figma」「ワイヤーフレーム」等への明示的な言及があるときだけ7-A（Figmaとの比較材料の用意）を行い、言及が無いときは7-B（依頼内容に対する単純な構造分析の材料の用意）を行う。** いずれの場合も7-Cで`ui-checker`を呼び出し、`fatal`でまず分岐し、`fatal: false`なら`criteria`のmismatch有無から呼び出し元自身がretry相当/pass相当を判定してループする（最大10回。`ui-checker`自体は`pass`/`retry`という値を返さない）。**retry相当では、7-Cが指す「iOSローカルの操作skill」ではなく`flutter-ios-operate-ci`skillの「アプリをビルド・インストール・起動する」節に戻ってビルド→インストール→起動をやり直す**（`flutter run`のホットリロードはCIでは使えない）。`fatal: true`では直ちに中断して人間にエスカレーションする。7-Bの場合、`figma_node_id`・`reference_image`は`null`にする。

このJSONは`--body`の本文中にコードフェンス付きで埋め込む（`--attach`は画像/動画専用のため、JSONの添付には使えない）。
