# 1. work/配下のAI/CI作業ディレクトリをmodule単位のサブディレクトリで分ける

## ステータス

Accepted

## コンテキスト

AIエージェント（ローカル・GitHub Actions CI問わず）がUI検証などで書き出すスクリーンショットやその評価結果は、`.gitignore`で丸ごと除外された`work/`配下（例: `work/screenshots/`）に保存している（[PR #89](https://github.com/taqucinco-com/soft-icecream-notes/pull/89)）。

現状このリポジトリには`mobile/`（Flutterアプリ）しかモジュールが無いが、将来的にbackend（API等）を同じリポジトリに追加する可能性がある。その際、backend向けのUI検証・動作確認等が同じ`work/screenshots/`に画像を書き出すと、mobile向けの成果物と混ざったりファイル名が衝突したりする恐れがある。

## 決定

`work/`配下にAIエージェントが書き出す成果物は、`work/screenshots/<module>/`のように**モジュール名（`mobile`、将来の`backend`等）のサブディレクトリで分ける**。フラットな`work/screenshots/`には直接置かない。

これに伴い、GitHub Actionsの`actions/upload-artifact`が参照するpathは非再帰的な`work/screenshots/*.png`ではなく、サブディレクトリを拾える`work/screenshots/**/*.png`にする（[PR #89のレビュー指摘](https://github.com/taqucinco-com/soft-icecream-notes/pull/89)で、この2つの記述が矛盾し、非再帰globだとartifactが無音で空になる問題が実際に見つかった）。

対象スキル: `flutter-android-operate`/`flutter-ios-operate`（ローカル）、`flutter-android-operate-ci`/`flutter-ios-operate-ci`（CI）、およびこれらを呼び出す`flutter-ui-*-verify`系スキル。

## 結果

- 良い点: 将来backend等のモジュールを追加しても、既存のmobile向け成果物と衝突・混在しない。モジュールごとに保存先を分けるという設計をSKILLのドキュメントを大きく書き換えずに素直に拡張できる。
- 悪い点: `work/screenshots/`直下ではなく必ず`<module>/`を経由するぶん、パスがわずかに長くなる。`actions/upload-artifact`等、パスをglobで参照する箇所は非再帰的なglobを使えず、`**`を使う必要がある（意図せずフラットなglobに戻すと成果物が拾えなくなる）。
