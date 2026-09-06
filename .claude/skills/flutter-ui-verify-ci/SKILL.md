---
name: flutter-ui-verify-ci
description: GitHub Actions CI上でicecream_log(mobile/)をAndroidエミュレータで起動する際の、CI環境向けのアプリ起動手順。`.github/workflows/claude.yml`で`[ui-verify]`が指定された`@claude`実行から使う。スクリーンショット取得・タップ座標の取得・Figma比較など起動後の検証手順は`flutter-ui-verify`スキルを参照する。
---

# Flutter UI検証（CI/GitHub Actions向けの起動手順）

`flutter-ui-verify`スキルのCI環境向け版。**アプリの起動方法だけがローカルと異なる**。スクリーンショット撮影・タップ座標の正確な取得・ヒットターゲットのデバッグ・環境要因の落とし穴・Figmaワイヤーフレームとの構造比較は、このスキルではなく`.claude/skills/flutter-ui-verify/SKILL.md`の3節以降をそのまま参照して使うこと。

## なぜ別スキルにしたか

CIの`claude`ジョブ（`.github/workflows/claude.yml`）は非対話的なBash権限モデルで動いており、`nohup <cmd> > file 2>&1 &`のようなバックグラウンド化・出力リダイレクトを伴うコマンドは、`--allowedTools`にプレフィックスを追加しても権限拒否されやすい。作業ディレクトリ外へのリダイレクトはハードコードされたセキュリティ制限で拒否され、作業ディレクトリ内へのリダイレクトであっても複数行スクリプトとの組み合わせで拒否されることを実際に確認した。`flutter run`の代わりに、バックグラウンド化もリダイレクトも不要な単発コマンドの組み合わせでアプリを起動する。

## 前提

- ワークフロー側で既にAndroidエミュレータのセットアップ・起動・`flutter pub get`/コード生成まで完了した状態でこのスキルが呼ばれる。`adb devices`で`emulator-5554`等が起動済みであることを確認してから進める。
- CIには`fvm`はインストールされていないため、`flutter`/`dart`コマンドをそのまま使う。
- モノレポ構成のため、Flutterコマンドはすべて`cd mobile && <コマンド>`の形で実行する。

## アプリをビルド・インストール・起動する

```bash
cd mobile && flutter build apk --debug --dart-define-from-file=../.env.local
```

```bash
cd mobile && adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

```bash
adb -s emulator-5554 shell am start -n com.taqucinco.soft_icecream_notes.icecream_log/.MainActivity
```

起動後、アプリが実際に前面に来ているかを以下で確認してからスクリーンショットに進む。

```bash
adb -s emulator-5554 shell dumpsys window | grep mCurrentFocus
```

`com.taqucinco.soft_icecream_notes.icecream_log`を含む行が出ていれば起動成功。

## コード修正を反映したい場合

`flutter run`のホットリロードが使えないため、修正のたびに`flutter build apk --debug`からやり直す（フルビルドで数十秒程度）。

## それ以降の手順

スクリーンショット撮影・タップ座標の正確な取得・ヒットターゲットのデバッグ・環境要因の落とし穴・Figmaワイヤーフレームとの構造比較は、`.claude/skills/flutter-ui-verify/SKILL.md`の3節以降を使う。**ただし保存先パスだけは次節の指示に従うこと**（`.claude/screenshots/<module>/`ではなく`work/screenshots/`を使う）。

## マップ画面の表示待ち（CI環境の制約）

`マップ`タブに遷移した直後はGoogle Mapのタイルがまだ読み込まれておらず、すぐにスクリーンショットを撮ると「表示されない」と誤判定しやすい。CI環境のエミュレータではタイル描画に10秒程度かかることがあるため、マップタブをタップしてから10秒待ってからスクリーンショットを撮ること。

```bash
sleep 10
```

## スクリーンショットの保存先（CI環境の制約）

CI環境のサンドボックスは、拡張子やサブディレクトリを問わず`.claude/`配下への書き込みを一律で「sensitive file」として拒否する。そのため`flutter-ui-verify`スキルが指示する`.claude/screenshots/<module>/`には保存できない。代わりに、ワークフローのチェックアウト先（`$GITHUB_WORKSPACE`）直下の`work/screenshots/`に保存すること。

**必ず`$GITHUB_WORKSPACE`からの絶対パスで書き込むこと。** 本スキルの他のコマンド（`cd mobile && flutter build ...`等）を実行すると、このBashツールは作業ディレクトリがコマンドをまたいで持続する仕様のため、以降のコマンドは`mobile/`に居続けたまま実行される。その状態で相対パス`work/screenshots/<name>.png`に書き込むと、実際には`mobile/work/screenshots/`に保存されてしまい、ワークフロー側の`actions/upload-artifact`（`path: work/screenshots/*.png`、リポジトリルート基準）が何も見つけられず、artifactが作成されない（実際にこの事故が発生したことがある）。

```bash
mkdir -p "$GITHUB_WORKSPACE/work/screenshots"
adb -s emulator-5554 exec-out screencap -p > "$GITHUB_WORKSPACE/work/screenshots/<name>.png"
```

`Run Claude Code`ステップの後続で、ワークフロー（`claude.yml`）側がこのディレクトリの`*.png`を自動でGitHub Actionsのartifactとしてアップロードし、そのダウンロードリンクをPR/Issueに別コメントで投稿する。Claude自身がコミットやアップロードを行う必要は無い。

## スクリーンショットの視覚的分析（VLMによる評価・JSON）

目視確認・VLMによる構造的評価・JSON形式での記録は、`flutter-ui-verify`スキルの7節（画面の評価）の手順・チェックリスト・JSON形式（`criteria`配列、`overall_verdict`等）をそのまま使うこと。CI固有の差分はスクリーンショットの保存先パスのみ（`.claude/screenshots/<module>/`ではなく`work/screenshots/`を使う）。

7節の分岐もそのまま踏襲する。**依頼コメントで「Figma」「ワイヤーフレーム」等への明示的な言及があるときだけ7-A（Figmaとの構造的比較）を行い、言及が無いときは7-B（依頼内容に対する単純な構造分析）を行う。** 7-Bの場合、`figma_node_id`・`reference_image`は`null`にする。

このJSONは`--body`の本文中にコードフェンス付きで埋め込む（`--attach`は画像/動画専用のため、JSONの添付には使えない）。
