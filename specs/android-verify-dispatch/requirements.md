# 概要

`claude.yml`は現在、`[ui-verify]`タグの有無によってジョブ内で同期的にAndroid SDK/JDK/KVM/Gradle/AVD/エミュレータのセットアップを行い、Android実機（エミュレータ）でのUI検証まで1つのジョブ内で完結させている。これは`ios-verify-dispatch`機能（`specs/ios-verify-dispatch/`）でiOS側に導入した「判定は専任agent、重い環境構築と実際の検証は別workflowへdispatch」という構成と非対称であり、以下の非効率を生む。

- Flutterでのコーディング・静的解析（`flutter analyze`/`flutter test`）は軽量なFlutter SDKだけで完結するにもかかわらず、`[ui-verify]`タグがあるだけでAndroid SDK/JDK/KVM/Gradle/AVDという重い環境構築が、コーディングが終わる前から`claude.yml`のジョブ内で走ってしまう。
- Android/iOSのどちらの確認が必要かを問わず一律ubuntuランナー上で環境構築が行われるため、実際には検証が不要だったケースでも時間とコストが無駄になる。

本機能では、Android版についてもiOS版と同じ「専任agentによる要否判定→専用workflowへのworkflow_dispatch」の構成に揃える。`claude.yml`はチェックアウト・Flutter SDKセットアップ（常時・軽量）・Claude Code実行という薄いコーディング/トリアージ役に専念し、Android Emulatorでの実機検証は新規`claude-android.yaml`に、iOS Simulatorでの検証は既存`claude-ios.yaml`に、それぞれ専任agentの判定を経てworkflow_dispatchで引き継ぐ。

あわせて、`[ui-verify]`タグの意味づけを「Android向けの検証依頼」から「プラットフォーム不問のUI確認依頼」に変更する。両OSのどちらで確認すべきかが依頼文から明確でない場合は、macOSランナーより安価なubuntuランナーで完結するAndroid Emulatorでの確認をデフォルトとし、iOS固有と判断できる場合のみiOS Simulatorでの確認を行う（コストを考慮した判定バイアス）。

## 対応範囲

1. 新規agent `android-verify-judge`: Android Emulatorでの確認要否を判定する専任agent（`ios-verify-judge`と同じ設計思想：判定のみ・副作用ゼロ）。
2. `claude.yml`からAndroid Emulator関連の環境構築・検証・後始末ステップ（JDK/KVM/Android SDK/Gradle cache/AVD cache/keystore/AVD起動/エミュレータ起動・停止/スクリーンショットアップロード等）をすべて除去する。Flutter SDKセットアップ（fvm/pub get/codegen）は「UI検証の要否」から切り離し、常時実行するステップとして残す。
3. 新規ワークフロー`.github/workflows/claude-android.yaml`: `claude-ios.yaml`と同じ構成（`workflow_dispatch`専用、必要な情報を受け取ってcheckout、Android Emulatorの環境構築、Claude Codeの実行、成果物アップロード、完了コメント）でAndroid Emulatorでの検証を引き継ぐ。**Android SDK/JDK/KVM/Gradle/AVD/エミュレータだけでなく、Flutterのフルビルド環境（fvmセットアップ・`flutter pub get`・codegen）も含める。** これはUI検証が「スクリーンショットを撮る→期待と比較する→一致しなければFlutterのコードを修正する→再ビルド・再インストール・再起動して撮り直す」という反復作業になるため、`claude-android.yaml`自身がコードを編集してビルドし直せる状態である必要があるからである（`claude-ios.yaml`は既にこの構成で実装済み）。
4. 新規skill `android-verify-dispatch`: `ios-verify-dispatch`とほぼ同じロジック（`android-verify-judge`の呼び出し→`gh workflow run claude-android.yaml`の起動→結果を最終応答に含める）に加え、`[ui-verify]`タグの有無とコスト（Android=ubuntuランナーで安価、iOS=macOSランナーで高価）を判定材料として扱う。
5. 既存の`ios-verify-judge`/`ios-verify-dispatch`（`specs/ios-verify-dispatch/`で導入済み）を改修し、`[ui-verify]`タグをプラットフォーム不問の汎用シグナルとして扱うようにする。あわせて、プラットフォームが依頼文から明確でない場合はコストの安いAndroidをデフォルトとし、iOS側はiOS固有と判断できる場合のみ要否をtrueにするというコストバイアスを明記する。
6. 新規agent `ui-verify-judge`: スクリーンショットによるUI検証結果（実装が期待と一致しているか）を判定する専任agent。Android/iOSで共通の1つとする（判定のみ・副作用ゼロ、`ios-verify-judge`/`android-verify-judge`と同じ設計思想）。既存4つの`*ui-verify*`系skill（`flutter-ui-verify`, `flutter-ui-verify-ci`, `flutter-ui-ios-verify`, `flutter-ui-ios-verify-ci`。ローカル開発向け・CI向け、Android/iOS双方を含む）すべてに、この`ui-verify-judge`を使った「コード修正→再ビルド→再検証」のループ制御（終了条件・エスカレーション条件・上限回数）を導入する。

# ユーザーストーリー

- 開発者として、UI変更を伴わない通常のコーディング依頼を`@claude`にした際、Android SDK/エミュレータのセットアップに時間を取られたくない。そうすれば、`claude.yml`のジョブがより速く完了する。
- 開発者として、`[ui-verify]`タグを付けて`@claude`に依頼した際、依頼内容がAndroid・iOSどちらに関するものかに応じて適切な方（もしくは両方）のプラットフォームで実機/シミュレータ確認をしてほしい。そうすれば、タグの意味が「Android専用」から「UI確認全般」に一貫する。
- 開発者として、プラットフォームを問わない一般的なUI変更について確認を依頼した場合、コストの安いAndroidでの確認がまず行われてほしい。そうすれば、無駄にmacOSランナーのコストをかけずに済む。
- 開発者として、`claude.yml`・`claude-android.yaml`・`claude-ios.yaml`のいずれの完了時にも、依頼がどこまで完了したか（未完了ならその原因）をPR/Issueコメントで確認したい。
- 開発者として、UI検証で撮ったスクリーンショットが期待と異なる場合、実装修正で直せる範囲の不一致であれば人手を介さず自動で修正・再検証を繰り返してほしい。そうすれば、軽微な実装ミスのたびに呼び出されずに済む。
- 開発者として、実行環境が壊れている・仕様自体が破綻しているなど、自動修正でどうにもならない問題が見つかった場合は、無駄にループを繰り返さずすぐにエスカレーションしてほしい。そうすれば、直しようのない問題にCI時間を浪費しない。

# 受け入れ条件

1. WHEN `claude.yml`のジョブが実行される THEN システム SHALL Android SDK/JDK/KVM/Gradle/AVD/エミュレータに関するステップを一切実行しない（これらは`claude-android.yaml`にのみ存在する）。
2. WHEN `claude.yml`のジョブが実行される THEN システム SHALL `[ui-verify]`タグの有無やUI検証要否に関わらず、Flutter SDKのセットアップ・`flutter pub get`・codegenを常時実行する。
3. WHEN `claude.yml`のジョブ内でClaude Codeが依頼内容を分析する THEN システム SHALL `android-verify-judge`agentと`ios-verify-judge`agentの両方について要否を判定する（両方が独立に真になりうる。例:「AndroidとiOS両方で確認して」という依頼）。
4. WHEN `android-verify-judge`agentがAndroid Emulatorでの確認を必要と判定する THEN システム SHALL `android-verify-dispatch`skillの手順に従い`claude-android.yaml`をworkflow_dispatchで起動する。
5. WHEN `claude.yml`側が`claude-android.yaml`を起動する THEN システム SHALL 少なくとも次の情報を入力として渡す: 対象のPR番号またはIssue番号、対象ブランチ（head ref）、元になった依頼のコメント本文、判断理由。
6. WHEN `claude.yml`側が`claude-android.yaml`の起動に成功する THEN システム SHALL 「Android Emulatorでの確認が必要と判断し、`claude-android.yaml`に検証を引き継いだ」旨を最終応答に含めてターンを終える（`claude-android.yaml`の完了を待たない）。
7. WHEN `claude.yml`側が`claude-android.yaml`の起動に失敗する THEN システム SHALL 失敗した旨と原因を最終応答に含める。
8. WHEN 依頼文に`[ui-verify]`タグが含まれ、かつ依頼内容からプラットフォームが特定できない THEN システム SHALL コストの安いAndroidでの確認を優先し、`android-verify-judge`の要否をtrueと判定する。iOS側は、依頼内容がiOS固有と判断できない限りtrueにしない。
9. WHEN 依頼文が明示的にiOS固有の内容（Cupertino、iOS限定の不具合、iOS向けFigma等）を含む THEN システム SHALL `[ui-verify]`タグの有無に関わらず`ios-verify-judge`が要否を判定できる（`specs/ios-verify-dispatch/`の既存挙動を維持しつつ、`[ui-verify]`単体でのAndroidデフォルト優先とは独立に判定する）。
10. WHEN `claude-android.yaml`がworkflow_dispatchで起動される THEN システム SHALL ubuntuランナー上でAndroid SDK/JDK/KVM/Gradle/AVD/エミュレータに加えFlutterのフルビルド環境（fvmセットアップ・`flutter pub get`・codegen）をセットアップし、渡された対象ブランチをチェックアウトしてClaude Codeを実行する。
11. WHEN `claude-android.yaml`内のClaude CodeがAndroid Emulator上でのUI確認を行う THEN システム SHALL 既存の`flutter-ui-verify-ci`skillを使用する（起動手順自体は変更しないが、検証ループの導入に伴う7節以降の改修は加える。16以降参照）。
12. WHEN `claude-android.yaml`または`claude-ios.yaml`でのUI確認中にスクリーンショットが期待した見た目と異なる THEN システム SHALL 同一ジョブ内でFlutter/Dartのコードを修正し、再ビルド・再インストール・再起動・再スクリーンショットのループを行える（`flutter`/`dart`コマンドの実行権限と、修正を反映するための`git commit`/`git push`の権限が`--allowedTools`に含まれている）。`claude-ios.yaml`は実装済みのためこの要件を既に満たしているが、`claude-android.yaml`でも同様に満たす必要がある。
13. WHEN `claude-android.yaml`の実行が完了する（成功・失敗いずれの場合も） THEN システム SHALL 依頼がどこまで完了したか、未完了ならその原因と次にすべきことを最終応答に含める。
14. WHEN `claude-android.yaml`がスクリーンショット等の検証成果物を生成する THEN システム SHALL `claude-ios.yaml`と同様にGitHub Actions artifactとしてアップロードし、そのリンクをPR/Issueコメントに含める。
15. WHEN `android-verify-dispatch`skillが`gh workflow run`等のコマンドを実行する THEN システム SHALL `ios-verify-dispatch`skill改修（Issue #56の教訓）と同じ制約に従う：事前の疎通確認をしない、単一の単純なコマンドとして実行する、base64を使わずシングルクォートで直接値を埋め込む。

## UI検証ループ（`ui-verify-judge`agent）

16. WHEN `flutter-ui-verify`/`flutter-ui-verify-ci`/`flutter-ui-ios-verify`/`flutter-ui-ios-verify-ci`のいずれかでスクリーンショットによる検証を行う THEN システム SHALL 新規agent`ui-verify-judge`（Android/iOS共通、判定専任）をTaskツールで呼び出し、期待される内容とスクリーンショットを渡して判定を得る。
17. WHEN `ui-verify-judge`の判定結果が「重大な指摘（実装修正で解消しうる不一致。レイアウト・要素の有無・テキスト・状態表現等）が1件以上」かつ18の「致命的な破綻」に該当しない THEN システム SHALL コードを修正し、再ビルド・再インストール・再起動・再スクリーンショットを行った上で再度`ui-verify-judge`を呼び出す（ループを継続する）。
18. WHEN `ui-verify-judge`の判定結果が次のいずれかに該当する（致命的な破綻） THEN システム SHALL 直ちにループを中断し、それ以上の自動修正を試みず人間にエスカレーションする：(a) 実行環境レベルの問題でループを継続しても改善しようがない、(b) 実装するまでもなく破綻している仕様の瑕疵、(c) コードの修正だけではどうしても解決しない問題、(d) emulator/simulatorがそもそも起動できていない。
19. WHEN `ui-verify-judge`の判定結果が「重大な指摘0件」（かつ18に該当しない） THEN システム SHALL ループを正常終了とし、検証完了として扱う。
20. WHEN 同一検証について10回ループしても「重大な指摘0件」（19）にも「致命的な破綻」（18）にも到達しない THEN システム SHALL それ以上ループを継続せず、上限到達を理由として人間にエスカレーションする。
21. WHEN `ui-verify-judge`agentが呼び出される THEN システム SHALL そのagentの役割を判定のみに限定する（副作用のあるツール、コードの編集・コマンド実行等を持たせない）。実際のコード修正・再ビルド等は呼び出し元（各`*-verify*`skillの手順に従う本体のClaude）が行う。
22. WHEN ループが人間にエスカレーションされる（18または20が理由） THEN システム SHALL エスカレーションの理由（致命的な破綻の内容、または上限到達である旨）と、それまでに判明していた指摘内容を最終応答に明示する。

# スコープ外

- `claude-ios.yaml`自体の構成変更（macOSランナー等は変更しない）。
- `flutter-ui-verify-ci`/`flutter-ui-ios-verify-ci`のCI環境向け起動手順（アプリのビルド・インストール・起動方法）自体の変更（検証ループ・judge agent呼び出しの導入以外は変更しない）。
- `[ui-verify]`以外の新しい明示タグの追加。
- `claude.yml`側が`claude-android.yaml`/`claude-ios.yaml`の完了を同期的に待ち合わせる仕組み。
- Android/iOS以外のプラットフォームへの対応。
- ループの上限回数（10回）や重大度の分類基準を、依頼内容ごとに動的に変更する仕組み（固定値・固定基準とする）。
