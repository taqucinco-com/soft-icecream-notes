---
name: flutter-ui-android-verify
description: ローカル開発環境でAndroidエミュレータ上のicecream_log(mobile/)を実機起動し、adbでのタップ操作・スクリーンショット取得・Figmaワイヤーフレームとのチェックリストに基づく構造的比較（VLMによる一致度判定）によってUI実装の妥当性を検証する。「動作確認して」「ワイヤーフレーム通りか確認して」「実機で見た目を確認して」「Figmaとどれくらい近づいたか教えて」等の依頼で使う。依頼にiOS/シミュレータ/idbへの言及がある場合は代わりに`flutter-ui-ios-verify`スキルを、GitHub Actions CI上で実行している場合は`flutter-ui-android-verify-ci`スキルを使うこと（いずれもアプリの起動方法・操作コマンドが異なる）。
---

# Flutter UI検証（icecream_log / Androidエミュレータ・ローカル環境向け）

`mobile/`配下のFlutterアプリを実機（Androidエミュレータ）で起動し、adb操作とスクリーンショットで実装の見た目・挙動を検証する手順。design.mdの「Figmaワイヤーフレームとの対応関係」表にある各画面を、実装後に実際にレンダリングして確認する用途を想定している。**ローカル開発環境向け**で、`fvm`経由（`fvm flutter`/`fvm dart`）での実行を前提にしている。GitHub Actions CI上で`[ui-verify]`から呼ばれた場合は、このスキルではなく`flutter-ui-android-verify-ci`スキルを使うこと（アプリのビルド・起動方法だけが異なり、以下の内容は共通）。

エミュレータの起動・アプリのビルド起動・スクリーンショット撮影・タップ操作・ヒットターゲットのデバッグ・環境要因の落とし穴は、このスキルではなく`flutter-android-operate`スキル（`.claude/skills/flutter-android-operate/SKILL.md`）を使う。このスキルは、その操作結果を「評価」してループを回す部分だけを扱う（重複して定義しない）。

## 前提

- Androidエミュレータで検証する（iOSシミュレータの場合は`flutter-ui-ios-verify`スキルを使う）。
- スクリーンショットの保存先は`flutter-android-operate`skillの指示（`work/screenshots/<module>/`）に従う。

## 画面の評価とui-checkerによるループ

評価そのものは専任agent`ui-checker`（Android/iOS・ローカル/CI共通、判定のみで副作用ゼロ）に委ね、本体のClaude（このskillを実行している自分自身）はその判定結果をもとに「コード修正→再ビルド→再検証」のループを回す。その場の印象で「だいたい合っている/動いている」と済ませたり、`ui-checker`を介さず自分で評価を確定させたりしないこと。**Figmaとの比較（7-A）を行うのは、依頼文で「Figma」「ワイヤーフレーム」「デザイン通り」など、Figmaへの言及が明示的にある場合に限る。** 言及が無い場合はFigmaを呼び出さず、7-Bの単純な構造分析を行う。ループの制御自体は7-Cで扱う。

### 7-A. Figmaに言及がある場合: Figmaワイヤーフレームとの比較用の資料を用意する

Figma MCPはプロジェクトルート直下の[.mcp.json](../../../.mcp.json)で定義する`figma`サーバ（[Framelink社のfigma-developer-mcp](https://github.com/GLips/Figma-Context-MCP)）を使う。ローカル・CI（`flutter-ui-android-verify-ci`/`flutter-ui-ios-verify-ci`）共通の同一設定・同一ツールセット。

#### 手順

1. design.mdの「Figmaワイヤーフレームとの対応関係」表で、検証したい画面に対応するfileKey（Figma URLの`/design/<fileKey>/...`部分）とnode-id（例: `2:2`）を確認する。
2. `mcp__figma__download_figma_images`（`figma-use`系スキルは不要、読み取りのみなので直接呼び出してよい）で、`nodes: [{nodeId: "<node-id>", fileName: "<name>-figma.png"}]`、`localPath: "work/screenshots/<module>"`を指定してそのnode-idのリファレンス画像を取得・保存する（＝「目指すべき成果物」）。`localPath`はMCPサーバプロセスのカレントディレクトリ（通常はリポジトリルート）からの相対パスとして解決される。
3. 同じfileKey・node-idについて`mcp__figma__get_figma_data`も呼び出し、各要素のid・name・レイアウト情報を含む構造情報（YAML形式のツリー）を取得する。

   ```yaml
   - id: "13:76"
     name: Navigation
     layout: { x: 627, y: 50, width: 673, height: 149 }
     children:
       - id: "13:28"
         name: Text
         layout: { x: 50, y: 63, width: 378, height: 23 }
   ```

   これは「要素の有無」「配置・順序」を画像の目視だけに頼らず、要素名・座標という客観的な情報で裏付けるために使う（XMLではなくYAML形式である点に注意。`mobile-screen-vision-compare`スキルの比較は構造化データであれば形式差を許容する）。
4. `flutter-android-operate`skillの3節の手順で実機の現状スクリーンショットを`work/screenshots/<module>/<name>-app.png`として保存する（＝「現状」）。あわせて同skill4節の`uiautomator dump`でアプリ側の構造（text/content-desc/bounds）も取得しておくと、Figmaの`get_figma_data`と直接突き合わせられる。
5. 画像パス（`<name>-figma.png`/`<name>-app.png`）とメタデータが揃ったら7-Cに進み、`ui-checker`に渡して判定させる。「比較対象」はFigmaのリファレンス（画像・`get_figma_data`）であることを7-Cの呼び出しで明示する。

### 7-B. Figmaに言及が無い場合: 単純な構造分析の材料を用意する

Figmaは呼び出さず、実機のスクリーンショットと`uiautomator dump`で得られる構造だけを根拠に、**依頼文で言及された確認内容（例:「マップタブに切り替えたら地図が表示されるはず」「一覧にカードが並んでいるはず」等）に実装がどの程度応えているか**を`ui-checker`に判定させる。依頼文がUIの構造や見た目に触れていない場合（例: 単に「起動確認して」）は、クラッシュ・白画面・意図しないダイアログの有無など、最低限の起動確認のみでよい。

#### 手順

1. `flutter-android-operate`skillの3節の手順で実機のスクリーンショットを`work/screenshots/<module>/<name>-app.png`として保存する。
2. 同skill4節の`uiautomator dump`でアプリの構造（text/content-desc/bounds）を取得する。
3. 画像パスと構造情報が揃ったら7-Cに進み、`ui-checker`に渡して判定させる。「比較対象」はFigmaではなく依頼文で示された期待であることを7-Cの呼び出しで明示する。

### 7-C. `ui-checker`を呼び出し、ループする

1. イテレーションカウンタを1にする（この会話内で本体のClaudeが保持する。`ui-checker`自体は状態を持たない）。
2. `Agent`ツールで`subagent_type: ui-checker`を**同期的に（`run_in_background: false`を指定して）**呼び出す。7-A/7-Bで用意した画像パス、（7-Aの場合）Figmaの構造情報、比較対象の期待（Figmaまたは依頼文）を渡す。**バックグラウンド（非同期）呼び出しは絶対に使わないこと。** GitHub Actions等の非対話的なCIセッションには後続ターンが無く、非同期呼び出しの完了通知を受け取れる機会が無いため、判定結果を使えないままターンが終わってしまう（実際にこの事故が発生し、ループが一度も回らずに完了報告コメントも投稿されなかった）。
3. 応答のJSON中の`fatal`でまず分岐する。**`pass`/`retry`という二値の「ループ制御判定」は`ui-checker`自体は返さない**（`mobile-screen-vision-compare`の比較結果である`criteria`と、環境・仕様レベルの`fatal`判定だけがagentの責務であり、そこから先の「ループを続けるか」はイテレーションカウンタという状態を持つ呼び出し元＝このskill自身の責務のため）。
   - **`fatal: true`**: 直ちにループを中断する。それ以上コードの修正・再ビルドを試みず、`fatal_reason`と直近の`criteria`をそのまま依頼者への報告（人間へのエスカレーション）に含める。
   - **`fatal: false`**: `criteria`に`mismatch`の観点が1件でもあるかを確認する（この判定は呼び出し元が`criteria`から直接行い、agentの追加出力には頼らない）。
     - **`mismatch`が0件**: 検証完了。`loop_verdict: pass`として下記「評価結果の保存」に進んでループを正常終了する。
     - **`mismatch`が1件以上かつイテレーションカウンタ < 10**: `criteria`の`mismatch`指摘をもとにコードを修正し、**検証対象のプラットフォーム・環境に応じた操作skillのアプリビルド・起動手順に従ってやり直し**、スクリーンショットを撮り直す（Androidローカルは`flutter-android-operate`2節「アプリをビルド・起動する」、Android CIは`flutter-android-operate-ci`「アプリをビルド・インストール・起動する」節、iOSローカルは`flutter-ios-operate`2節、iOS CIは`flutter-ios-operate-ci`「アプリをビルド・インストール・起動する」節。それぞれのCI/ローカルの制約に従うこと。**`nohup flutter run`を使ってよいのはローカル版だけ**で、CI版はビルド→インストール→起動のコマンド列を使う）。カウンタを+1して7-Cの2.（`ui-checker`の呼び出し）に戻る。
     - **`mismatch`が1件以上かつイテレーションカウンタ = 10**: それ以上ループしない。上限到達を理由に、直近の`criteria`を添えて依頼者へエスカレーションする。

`fatal: true`の具体例（`ui-checker`側の判断基準と共通）: 実行環境レベルの問題で改善しようがない、実装以前に破綻している仕様の瑕疵、コードの修正だけでは解決しない問題、emulator/simulatorがそもそも起動できていない。

### 評価結果の保存（Markdown + JSON）

保存の手順・フォーマット（Markdown/JSONの形式、`loop_verdict`の3値等）は`flutter-ui-android-verify`/`flutter-ui-android-verify-ci`/`flutter-ui-ios-verify`/`flutter-ui-ios-verify-ci`の4スキル共通なので`flutter-ui-verify-result-save`スキル（`.claude/skills/flutter-ui-verify-result-save/SKILL.md`）を使う（重複して定義しない）。保存先ディレクトリは`flutter-android-operate`skillの指示（`work/screenshots/<module>/`）に従う。上限到達（`loop_verdict: retry_limit_reached`）または`fatal`（`loop_verdict: fatal`）でループを終えた場合も、その時点までに判明していた`criteria`を同様に保存する。
