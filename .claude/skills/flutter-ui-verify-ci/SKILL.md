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

## スクリーンショットの保存先（CI環境の制約）

CI環境のサンドボックスは、拡張子やサブディレクトリを問わず`.claude/`配下への書き込みを一律で「sensitive file」として拒否する。そのため`flutter-ui-verify`スキルが指示する`.claude/screenshots/<module>/`には保存できない。代わりに`work/screenshots/`に保存すること（例: `work/screenshots/develop-initial-screen.png`。ディレクトリが無ければ`mkdir -p work/screenshots`で作成する）。

```bash
mkdir -p work/screenshots
adb -s emulator-5554 exec-out screencap -p > work/screenshots/<name>.png
```

`Run Claude Code`ステップの後続で、ワークフロー（`claude.yml`）側がこのディレクトリの`*.png`を自動でGitHub Actionsのartifactとしてアップロードし、そのダウンロードリンクをPR/Issueに別コメントで投稿する。Claude自身がコミットやアップロードを行う必要は無い。

（過去に`gh issue/pr comment --attach`で直接添付する方式を試したが、claude-code-actionが使うGitHub Appのインストールトークンでは`--attach`が`unsupported authentication type`エラーで失敗するため使えない。リポジトリへのコミットも画像でリポジトリが肥大化するため避け、artifact化する方式にした。）

## スクリーンショットの視覚的分析結果（JSON）

スクリーンショットをReadツールで開いて目視確認した内容を、文章だけでなく機械可読なJSONとしても`--body`に含めること（Figmaワイヤーフレームとの構造比較とは別物で、Figma比較を行っていない単純な起動確認でも毎回作成する）。

```json
{
  "screenshot": "<name>.png",
  "checked_at": "<ISO8601日時>",
  "check_request": "<今回確認しようとした内容の短い説明>",
  "observed_elements": ["画面上で確認できた主要な要素を列挙（日本語で簡潔に）"],
  "anomalies": ["クラッシュ・白画面・ローディング停止・意図しないダイアログ等があれば記述。無ければ空配列"],
  "verdict": "ok"
}
```

`verdict`は異常が無ければ`ok`、`observed_elements`や`anomalies`から見て何らかの問題がある場合は`anomaly_detected`とする。このJSONは`--body`の本文中にコードフェンス付きで埋め込む（`--attach`は画像/動画専用のため、JSONの添付には使えない）。
