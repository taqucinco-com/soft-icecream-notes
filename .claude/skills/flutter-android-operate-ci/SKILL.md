---
name: flutter-android-operate-ci
description: GitHub Actions CI上でicecream_log(mobile/)をAndroidエミュレータで起動し、adbでのタップ操作・スクリーンショット取得を行う共通手順。UI検証のmaker/checker等、CI上でAndroidエミュレータの操作が必要な複数のスキル・agentから共通で参照される。`flutter-android-operate`のCI環境向け版。
---

# Flutter Android操作（CI/GitHub Actions向け）

`flutter-android-operate`スキルのCI環境向け版。**アプリの起動方法だけがローカルと異なる**。スクリーンショット撮影・タップ座標の正確な取得・ヒットターゲットのデバッグ・環境要因の落とし穴は、このスキルではなく`.claude/skills/flutter-android-operate/SKILL.md`の3節以降をそのまま参照して使うこと（重複して定義しない）。

## なぜ別スキルにしたか

CIの`claude-android`ジョブ（`.github/workflows/claude-android.yaml`）は非対話的なBash権限モデルで動いており、`nohup <cmd> > file 2>&1 &`のようなバックグラウンド化・出力リダイレクトを伴うコマンドは、`--allowedTools`にプレフィックスを追加しても権限拒否されやすい。作業ディレクトリ外へのリダイレクトはハードコードされたセキュリティ制限で拒否され、作業ディレクトリ内へのリダイレクトであっても複数行スクリプトとの組み合わせで拒否されることを実際に確認した。`flutter run`の代わりに、バックグラウンド化もリダイレクトも不要な単発コマンドの組み合わせでアプリを起動する。

## 前提

- ワークフロー側で既にAndroidエミュレータのセットアップ・起動・`flutter pub get`/コード生成まで完了した状態でこのスキルが呼ばれる。`adb devices`で`emulator-5554`等が起動済みであることを確認してから進める。
- CIには`fvm`はインストールされていないため、`flutter`/`dart`コマンドをそのまま使う。
- モノレポ構成のため、Flutterコマンドはすべて`cd mobile && <コマンド>`の形で実行する。

## アプリをビルド・インストール・起動する

```bash
cd mobile && flutter build apk --debug --dart-define-from-file=.env.local
```

`.env.local`は`mobile/`直下（ローカルと同じ位置）。`claude-android.yaml`の"Create mobile/.env.local from .env.sample"ステップが`mobile/.env.sample`から生成済みなので、このスキル側で作る必要はない。

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

スクリーンショット撮影・タップ座標の正確な取得・ヒットターゲットのデバッグ・環境要因の落とし穴は、`.claude/skills/flutter-android-operate/SKILL.md`の3節以降を使う。保存先ディレクトリ（`work/screenshots/<module>/`）はローカルと共通だが、**CIでは次節の理由により`$GITHUB_WORKSPACE`からの絶対パスで書き込むこと**。

## マップ画面の表示待ち（CI環境の制約）

`マップ`タブに遷移した直後はGoogle Mapのタイルがまだ読み込まれておらず、すぐにスクリーンショットを撮ると「表示されない」と誤判定しやすい。CI環境のエミュレータではタイル描画に10秒程度かかることがあるため、マップタブをタップしてから10秒待ってからスクリーンショットを撮ること。

```bash
sleep 10
```

## スクリーンショットの保存先（CI環境の制約）

CI環境のサンドボックスは、拡張子やサブディレクトリを問わず`.claude/`配下への書き込みを一律で「sensitive file」として拒否する（ローカル・CIとも保存先を`.claude/`配下ではなく`work/screenshots/`に統一しているのはこのため）。ワークフローのチェックアウト先（`$GITHUB_WORKSPACE`）直下の`work/screenshots/`に保存すること。

**必ず`$GITHUB_WORKSPACE`からの絶対パスで書き込むこと。** 本スキルの他のコマンド（`cd mobile && flutter build ...`等）を実行すると、このBashツールは作業ディレクトリがコマンドをまたいで持続する仕様のため、以降のコマンドは`mobile/`に居続けたまま実行される。その状態で相対パス`work/screenshots/<name>.png`に書き込むと、実際には`mobile/work/screenshots/`に保存されてしまい、ワークフロー側の`actions/upload-artifact`（`path: work/screenshots/*.png`、リポジトリルート基準）が何も見つけられず、artifactが作成されない（実際にこの事故が発生したことがある）。

```bash
mkdir -p "$GITHUB_WORKSPACE/work/screenshots"
adb -s emulator-5554 exec-out screencap -p > "$GITHUB_WORKSPACE/work/screenshots/<name>.png"
```

`Run Claude Code`ステップの後続で、ワークフロー（`claude-android.yaml`）側がこのディレクトリの`*.png`を自動でGitHub Actionsのartifactとしてアップロードし、そのダウンロードリンクをPR/Issueに別コメントで投稿する。Claude自身がコミットやアップロードを行う必要は無い。評価結果（`<name>-compare.md`/`<name>-compare.json`等）も、呼び出し元のスキル・agentの指示に従って同じ`work/screenshots/`配下に保存する。
