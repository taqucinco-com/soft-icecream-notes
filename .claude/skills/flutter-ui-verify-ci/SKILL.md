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
cd mobile && flutter build apk --debug
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

スクリーンショット撮影・タップ座標の正確な取得・ヒットターゲットのデバッグ・環境要因の落とし穴・Figmaワイヤーフレームとの構造比較は、`.claude/skills/flutter-ui-verify/SKILL.md`の3節以降をそのまま使う。
