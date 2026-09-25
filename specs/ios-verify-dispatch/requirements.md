# 概要

GitHub Actions上で `@claude` メンションから起動する既存の `claude.yml`（Android Emulatorでの検証に対応済み）に加えて、依頼内容からiOS Simulatorでの確認が必要だとClaudeエージェントが判断した場合に、macOSランナー向けの新規ワークフロー `claude-ios.yaml` へ処理を引き継ぐ仕組みを追加する。

iOS Simulatorの起動・操作にはmacOSランナーが必要であり、`claude.yml`（ubuntu-latest）とは実行環境が異なるため、判断結果とそこまでの調査内容を渡した上で `claude-ios.yaml` を別途起動する構成にする。

## 対応範囲

1. `claude.yml` 側で、iOS Simulatorでの確認が必要と判断した場合にPR/Issue等の情報を `claude-ios.yaml` に渡して起動する仕組み
2. `claude-ios.yaml` ワークフロー自体の新規作成
3. iOS Simulator上での確認が必要かどうかをClaudeエージェントが判断するための仕組み（意味的判断。明示タグは設けない）
4. `claude-ios.yaml` 起動後、実際にiOS Simulator上でUI検証を行うためのCI環境向け新規スキル（既存の `flutter-ui-ios-verify` はローカル専用のため、`flutter-ui-verify-ci`（Android版）に相当するiOS版を新規作成する）

# ユーザーストーリー

- 開発者として、PR/Issueのコメントで `@claude` にiOS特有の見た目・挙動の確認が必要な依頼をすると、Claudeがその必要性を依頼内容から自分で判断し、iOS Simulatorでの検証まで自動的に行ってほしい。そうすれば、Android版の `[ui-verify]` タグのような明示指定を覚えなくても、依頼内容に応じた環境で検証してもらえる。
- 開発者として、`claude.yml` 側がどこまで調査・判断した上で `claude-ios.yaml` に引き継いだのかを、渡された情報から追える状態にしたい。そうすれば、処理が2つのワークフローに分かれても経緯を追跡できる。
- 開発者として、`claude.yml` と `claude-ios.yaml` のどちらの実行が終わった時点でも、依頼がどこまで完了したか（未完了ならその原因）をPR/Issueコメントで確認したい。そうすれば、ジョブの成功/失敗（緑/赤）と依頼の達成/未達成を混同せずに済む。

# 受け入れ条件

1. WHEN `claude.yml` のジョブ内でClaude Codeが依頼内容を分析し、iOS Simulatorでの確認が必要と判断する THEN システム SHALL `claude-ios.yaml` をworkflow_dispatchで起動する。
2. WHEN `claude.yml` 側が `claude-ios.yaml` を起動する THEN システム SHALL 少なくとも次の情報を入力として渡す: 対象のPR番号またはIssue番号、対象ブランチ（head ref）、元になった依頼のコメント本文、`claude.yml` 側で判断した理由やそこまでの調査結果。
3. WHEN `claude.yml` 側が `claude-ios.yaml` の起動に成功する THEN システム SHALL 「iOS Simulatorでの確認が必要と判断し、`claude-ios.yaml` に処理を引き継いだ」旨をPR/Issueコメントとして残してからターンを終える（`claude-ios.yaml` の完了を待たない）。
4. WHEN `claude.yml` 側が `claude-ios.yaml` の起動に失敗する（権限不足・ワークフローが見つからない等） THEN システム SHALL 失敗した旨と原因をPR/Issueコメントとして残す。
5. WHEN iOS Simulatorでの確認が不要と判断される THEN システム SHALL 現行の `claude.yml` の挙動（Android/`[ui-verify]` タグ判定を含む）をそのまま維持する。
6. WHEN PR/Issueコメントに `[ui-verify]` タグが含まれ、かつClaudeがiOS Simulatorでの確認も必要と判断する THEN システム SHALL 両方の判定を独立に扱う。すなわち `[ui-verify]` によるAndroid側の検証は `claude.yml` 内でこれまで通り実行しつつ、iOS側の検証は `claude-ios.yaml` へ引き継ぐ（`[ui-verify]` タグの有無はiOS側の判断に影響しない）。
7. WHEN `claude-ios.yaml` がworkflow_dispatchで起動される THEN システム SHALL macOSランナー上でiOS Simulatorを起動し、渡された対象ブランチをチェックアウトしてClaude Codeを実行する。
8. WHEN `claude-ios.yaml` 内のClaude CodeがiOS Simulator上でのUI確認を行う THEN システム SHALL 新規作成するCI環境向けiOS検証スキル(ローカル専用の `flutter-ui-ios-verify` とは別スキル)を使用する。
9. WHEN `claude-ios.yaml` の実行が完了する(成功・失敗いずれの場合も) THEN システム SHALL 依頼がどこまで完了したか、未完了ならその原因と次にすべきことをPR/Issueコメントとして残す(CLAUDE.mdのGitHub Actions応答ルールに従う)。
10. WHEN `claude-ios.yaml` がスクリーンショット等の検証成果物を生成する THEN システム SHALL Android版 (`claude.yml`) と同様にGitHub Actions artifactとしてアップロードし、そのリンクをPR/Issueコメントに含める。

# スコープ外

- Android版 `claude.yml` の `[ui-verify]` タグによる判定ロジック自体の変更。
- iOS版における明示タグ（`[ios-verify]` 等）でのオーバーライド機能（今回はClaudeの意味的判断のみとする）。
- `claude-ios.yaml` の完了を `claude.yml` 側が同期的に待ち合わせる仕組み（両ワークフローは非同期に完了し、それぞれが自分の担当範囲についてコメントする）。
- Android/iOS以外のプラットフォーム（Web等）への対応。
