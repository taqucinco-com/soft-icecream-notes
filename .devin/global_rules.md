# Devin向けのルール

Devinはリモート環境で動き、`.claude/settings.json`の`permissions.deny`をそのまま使うと開発の流れが止まる操作があるため、次のルールはDevinの`.devin/config.json`に変換しない。Claude Code・Codexには`.claude/settings.json`の`permissions.deny`をそのまま適用する。

このファイルは手書きの実体で、`sync-devin-codex`プラグインは生成も上書きもしない。同期スキルはこのファイルを読み、`devin:`付きのルールを`--skip-deny`でDevinの生成物から外す（プラグイン側の対応: [plugin-marketplace#4](https://github.com/taqucinco-com/plugin-marketplace/issues/4)）。ルールは`.claude/settings.json`の`permissions.deny`の文字列と完全一致で書く。`Edit(...)`は`.devin/config.json`では`Write(...)`に統合されるため、`Edit`と`Write`の両方を並べる。

## Devinで変換しないdenyルール

- `devin:Edit(./.env.*)`、`devin:Edit(**/.env.*)`、`devin:Write(./.env.*)`、`devin:Write(**/.env.*)`: `.env.sample`の更新と`.env.local`の作成（[CONTRIBUTING.md](../CONTRIBUTING.md)の手順）を行うため。`.env`・`.env.local`の読み取り（`Read`・`cat`）と、`.env`への書き込みは拒否のまま。
- `devin:Bash(rm -rf *)`、`devin:Bash(rm -fr *)`: ビルド成果物やworktreeのディレクトリを削除するため。
- `devin:Bash(git branch -D*)`: squashマージ後のローカルブランチは`-d`では削除できないため。
- `devin:Bash(git reset --hard*)`、`devin:Bash(git clean -fd*)`: 作業をやり直し、生成物を掃除するため。
