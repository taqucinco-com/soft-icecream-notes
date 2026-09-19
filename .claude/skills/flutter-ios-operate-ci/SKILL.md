---
name: flutter-ios-operate-ci
description: GitHub Actions CI上でicecream_log(mobile/)をiOS Simulatorで起動し、idb/simctlでの操作を行う共通手順。UI検証のmaker/checker等、CI上でiOS Simulatorの操作が必要な複数のスキル・agentから共通で参照される。`flutter-ios-operate`のCI環境向け版。
---

# Flutter iOS操作（CI/iOS Simulator向け）

`flutter-ios-operate`スキルのCI環境向け版。**アプリの起動方法・環境セットアップだけがローカルと異なる**。タップ操作・要素ツリー取得・スクリーンショット撮影・ヒットターゲットのデバッグ・座標系の注意点は、このスキルではなく`.claude/skills/flutter-ios-operate/SKILL.md`の3節以降をそのまま参照して使うこと（重複して定義しない）。

## なぜ別スキルにしたか

CIの`claude-ios`ワークフロー（`.github/workflows/claude-ios.yaml`）はGitHub Actionsのmacosランナー上で動き、ローカル開発環境とは前提が異なる。`fvm`は無く`flutter`コマンドをそのまま使う、CocoaPodsや`idb-companion`をジョブごとに都度インストールする、`.env.local`をSecretsから生成する、といった違いがある。またAndroid版CIスキル（`flutter-android-operate-ci`）と同様、非対話的なBash権限モデルでは`nohup <cmd> > file 2>&1 &`のようなバックグラウンド化・出力リダイレクトを伴うコマンドが拒否されやすいため、`flutter run`の代わりに単発コマンドの組み合わせでアプリを起動する。

## 前提

- ワークフロー側で既にiOS Simulatorの作成・起動、`idb-companion`/`idb-cli`のインストール、`idb connect`、CocoaPods/Flutterセットアップ、`mobile/.env.local`生成まで完了した状態でこのスキルが呼ばれる。`xcrun simctl list devices booted`と`idb list-targets`で起動・接続済みであることを確認してから進める。
- CIには`fvm`はインストールされていないため、`flutter`/`dart`コマンドをそのまま使う。
- モノレポ構成のため、Flutterコマンドはすべて`cd mobile && <コマンド>`の形で実行する。
- `simctl`/`idb`コマンドが`CoreSimulatorService`やidbのソケットに接続できず失敗する場合、ローカル環境（`flutter-ios-operate`skillの0節）と同じ理由でBashツールのサンドボックス制約が疑われる。その場合は`dangerouslyDisableSandbox: true`を付けて再実行すること（macOSランナーでも同じ制約が起こりうる。未確認の場合はまず制約無しで試し、`CoreSimulatorService connection became invalid`等のエラーが出たら切り替える）。

## UDIDの取得

```bash
UDID=$(xcrun simctl list devices booted -j | jq -r '.devices[][0].udid')
```

ワークフロー側でシミュレータを起動したステップが`$GITHUB_ENV`に`SIMULATOR_UDID`を入れている場合はそれを使ってもよい。Bashツールはシェル状態を保持しないため、UDIDは各コマンドで取得し直すか、コマンドごとに明示的に参照する。

## アプリをビルド・インストール・起動する

```bash
cd mobile && flutter build ios --debug --simulator --dart-define-from-file=.env.local
```

`.env.local`は`mobile/`直下（ローカルと同じ位置）。ワークフロー側の"Create mobile/.env.local from .env.sample"ステップが生成済みなので、このスキル側で作る必要はない。シミュレータ向けビルドのため署名は不要。

```bash
xcrun simctl install "$UDID" mobile/build/ios/iphonesimulator/Runner.app
```

```bash
xcrun simctl launch "$UDID" com.taqucinco.softicecreamnotes.icecreamLog
```

起動後、起動確認:

```bash
idb list-targets | grep Booted
```

## コード修正を反映したい場合

`flutter run`のホットリロードが使えないため、修正のたびに`flutter build ios --debug --simulator`からやり直す（iOSはAndroidよりフルビルドが重いため数分程度かかる）。

## idbの接続が切れた場合

ワークフロー側で`idb connect`済みだが、シミュレータの再起動やビルドやり直し後に接続が切れることがある。`idb list-targets`が対象UDIDについて`No Companion Connected`を返す場合は再接続する。

```bash
idb connect "$UDID"
```

## それ以降の手順

タップ操作・要素ツリー取得（`idb ui describe-all`）・スクリーンショット撮影・ヒットターゲットのデバッグ・座標系の注意点（スクリーンショットはピクセル、idbはポイント）・環境要因の落とし穴は、`.claude/skills/flutter-ios-operate/SKILL.md`の3節以降を使う。保存先ディレクトリ（`work/screenshots/mobile/`）はローカルと共通だが、**CIでは次節の理由により`$GITHUB_WORKSPACE`からの絶対パスで書き込むこと**。

## マップ画面の表示待ち（CI環境の制約）

Android版CIスキルと同様、CI環境のシミュレータではGoogle Mapのタイル描画に時間がかかることがある。マップタブに遷移した直後にスクリーンショットを撮ると「表示されない」と誤判定しやすいため、遷移後10秒待ってから撮影する。

```bash
sleep 10
```

## スクリーンショットの保存先（CI環境の制約）

CI環境のサンドボックスは、拡張子やサブディレクトリを問わず`.claude/`配下への書き込みを一律で「sensitive file」として拒否する（ローカル・CIとも保存先を`.claude/`配下ではなく`work/screenshots/<module>/`に統一しているのはこのため）。ワークフローのチェックアウト先（`$GITHUB_WORKSPACE`）直下の`work/screenshots/mobile/`に保存すること。

**必ず`$GITHUB_WORKSPACE`からの絶対パスで書き込むこと。** 本スキルの他のコマンド（`cd mobile && flutter build ...`等）を実行すると、このBashツールは作業ディレクトリがコマンドをまたいで持続する仕様のため、以降のコマンドは`mobile/`に居続けたまま実行される。その状態で相対パス`work/screenshots/mobile/<name>.png`に書き込むと、実際には`mobile/work/screenshots/mobile/`に保存されてしまい、ワークフロー側の`actions/upload-artifact`（`path: work/screenshots/**/*.png`、リポジトリルート基準）が何も見つけられず、artifactが作成されない。

```bash
mkdir -p "$GITHUB_WORKSPACE/work/screenshots/mobile"
xcrun simctl io "$UDID" screenshot "$GITHUB_WORKSPACE/work/screenshots/mobile/<name>.png"
```

`Run Claude Code`ステップの後続で、ワークフロー（`claude-ios.yaml`）側がこのディレクトリの`*.png`を自動でGitHub Actionsのartifactとしてアップロードし、そのダウンロードリンクをPR/Issueに投稿する。Claude自身がコミットやアップロードを行う必要は無い。評価結果（`<name>-compare.md`/`<name>-compare.json`等）も、呼び出し元のスキル・agentの指示に従って同じ`work/screenshots/mobile/`配下に保存する。
