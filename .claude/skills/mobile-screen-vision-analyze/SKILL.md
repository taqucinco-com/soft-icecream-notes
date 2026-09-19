---
name: mobile-screen-vision-analyze
description: モバイルアプリのスクリーンキャプチャ画像1枚を、Claude自身のVision機能（VLM）で解析し、オブジェクトのbounding box・特徴ラベル・UI構造上のランドマーク・OCRテキスト・要素の親子関係(入れ子構造)・画面の意味理解を含む構造化JSONとして出力する。「このスクリーンショットを分析して」「画面の構造をJSONにして」等、スクリーンショット1枚の内容を機械可読な形にしたい依頼で使う。2つの分析結果を比較したい場合は、この結果を`mobile-screen-vision-compare`スキルに渡す。
---

# モバイルアプリのスクリーンキャプチャを入力とし、JSONを出力とする

## 目的

モバイルアプリのスクリーンキャプチャ画像を解析し、画面上のオブジェクトやテキストの情報を抽出して分析可能な構造化データとして出力することを目的とする。ここで言う「解析」は外部の画像認識APIを呼ぶのではなく、**Claude自身のVision機能で画像を読み、推論した結果をこのスキルが定義するJSON Schemaに落とし込む**ことを指す。出力されたJSONは、別の分析結果との機械的な比較（`mobile-screen-vision-compare`スキル）や、複数回の検証結果の時系列比較に使うことを想定している。

## 入力

モバイルアプリのスクリーンキャプチャ画像ファイル（PNG, JPEGなど）1枚のパスを入力とする。複数画面・複数状態の比較はこのスキルの範囲外（`mobile-screen-vision-compare`側で扱う）。

## 精度についての前提（重要）

このスキルの分析結果は、あくまでClaudeによる**目視ベースの推定**であり、正確なピクセル座標やAndroid/iOSのアクセシビリティAPIが返す実座標と一致することを保証しない。VLMのbounding box推定・カウントの精度限界に関するベンチマーク（[Limits of Vision - Claude](https://scads.github.io/generative-ai-notebooks/81_benchmarking_vlms_counting/limits_of_vision-claude.html)）でも、Claudeは画像内のオブジェクト数を「約13〜14個」のように幅を持って報告し、座標についても「visual estimationに基づく近似値であり、ピクセル完全な座標とは若干異なりうる」と明記されている。このスキルを使う・使わせる際は以下を踏まえること。

- **`bounding_box`をタップ操作の座標として使ってよいが、あくまで目視による概算だと理解した上で使う。** アクセシビリティラベルが取れない・`uiautomator dump`/`idb ui describe-all`に要素が現れない等の理由でOS標準の手段が使えない場合、`bounding_box`の中心座標をフォールバックとしてタップに使うのは有効な選択肢である。ただし小さいアイコンや密集した要素では実際のヒット位置と数px〜数十pxずれることがあるため、タップが反応しない場合は「コードのヒットエリアの不具合」と決めつける前に、まず`bounding_box_confidence`が`low`になっていないか・要素が小さすぎないかを疑う。
- **似た小さいオブジェクトが多数並ぶ画面では、個数を過信しない。** リストの行数やグリッドのマス数など、同種の要素が多い場合は数え間違い・見落としが起きやすい。自信が無い個数は`objects_count_confidence`を`low`にし、`screen_understanding.notes`に不確実性を明記する。
- **見えないもの・自信の無いものを補完（ハルシネーション）しない。** 画像から読み取れない要素は出力せず、テキストがかすれて判読できない場合は`text`を`null`にして`"判読不能"`等を`notes`に書く。
- 出力はこのスキルが定義するJSON Schemaに**厳密に一致**させる（キー名・型を変えない）。ベンチマークページ自身も「出力フォーマットをJSON Schemaとして明示するとVLMの出力が安定する」ことを示しており、本スキルはその知見に沿って厳密なSchemaを固定している。

## 分析観点とJSON Schema

出力は以下の6つのトップレベルキーを持つ1つのJSONオブジェクトとする。「オブジェクトの特徴」「ランドマーク」は、Google Cloud Vision APIの`LABEL_DETECTION`/`LANDMARK_DETECTION`という機能名から着想を得ているが、対象は一般的な写真ではなくモバイルアプリのUI画面なので、意味をUI文脈に合わせて読み替えている（下記参照）。

### 1. `source_image` / `image_size` — 入力のメタ情報

```json
{
  "source_image": "<入力画像への相対または絶対パス>",
  "image_size": { "width": 1206, "height": 2622 }
}
```

`image_size`はRead時にわかる範囲でよい（不明なら`null`）。後述の`bounding_box`は**画像の幅・高さに対する0.0〜1.0の正規化座標**（左上原点）で表現し、ピクセル座標にはしない。呼び出し元がピクセル値を必要とする場合は`image_size`と掛け合わせて変換させる。

### 2. `objects` — オブジェクトとその相対的な大きさと位置・特徴

画面内で視覚的に区別できるUI要素（ボタン、カード、アイコン、見出し、ナビゲーション項目など）を1要素1オブジェクトとして列挙する。「オブジェクトとその相対的な大きさと位置」（bounding box）と「オブジェクトの特徴」（`LABEL_DETECTION`相当のラベル付け）は、実装上は同じ配列の各要素が両方の情報を持つ形にまとめる（bounding boxだけを別配列にすると、どのラベルがどの箱に対応するか呼び出し元が突き合わせ直す必要が生じるため）。

```json
{
  "objects": [
    {
      "id": "obj_1",
      "type": "card",
      "labels": ["list_item", "photo_thumbnail", "rating_indicator"],
      "text": "バニラソフト",
      "bounding_box": { "x": 0.05, "y": 0.18, "width": 0.90, "height": 0.22 },
      "bounding_box_confidence": "medium",
      "parent_id": null,
      "z_index": 0
    }
  ],
  "objects_count_confidence": "high"
}
```

- `type`: 要素の種類を表す短い識別子（自由記述可。例: `button` / `icon` / `card` / `text_heading` / `navigation_bar` / `tab_bar` / `fab` / `dialog` / `chip` / `image` / `unknown`）。ボタンの中のアイコンのように他の要素を内包するだけの「入れ物」も1つの`object`として登録してよい（4節参照）。
- `labels`: その要素が持つ視覚的・機能的な特徴タグの配列（`LABEL_DETECTION`相当）。空配列可。
- `text`: その要素に直接紐づくテキスト（無ければ`null`。画面全体のOCR結果は5節の`text_blocks`で別途網羅する）。
- `bounding_box_confidence`: `high` / `medium` / `low`。重なりが多い・小さすぎる・部分的に隠れている等で座標に自信が無い場合は`low`にする（座標自体は省略せずベストエフォートで埋める）。
- `parent_id`: この要素を直接内包している親要素の`id`。画面に直接置かれていて他のどの`object`にも内包されていない場合は`null`。要素同士の入れ子関係（4節）はこのフィールドで表す。
- `z_index`: 同じ`parent_id`を持つ兄弟要素同士の重なり順を表す整数（大きいほど上に描画される）。兄弟同士が重ならない通常のレイアウトでは省略してよく、省略時は`0`相当として扱う（4節）。

### 3. `landmarks` — モバイルUIにおけるランドマーク（`LANDMARK_DETECTION`相当）

一般的な写真における「エッフェル塔」のような著名な地物ではなく、モバイルUIにおいて**型として認識できる構造要素**（存在有無・位置がアプリの骨格を表すもの）をランドマークとして扱う。`objects`と重複してよい（`objects`は個別要素の列挙、`landmarks`はその中から画面構造を特徴づける代表的なものだけを抜き出した要約）。

```json
{
  "landmarks": [
    { "name": "status_bar", "present": true, "object_id": "obj_status_bar" },
    { "name": "app_bar", "present": true, "object_id": "obj_appbar" },
    { "name": "bottom_navigation_bar", "present": true, "object_id": "obj_bottom_nav" },
    { "name": "floating_action_button", "present": false, "object_id": null },
    { "name": "modal_dialog", "present": false, "object_id": null },
    { "name": "empty_state_illustration", "present": false, "object_id": null }
  ]
}
```

`name`は代表的なランドマーク名を列挙する固定語彙とし、`present: false`の項目も**省略せず**含める（「存在しない」こと自体が比較時に意味を持つため）。上記6種類を基本セットとするが、画面に応じて`snackbar_toast` / `search_bar` / `tab_bar`などを追加してよい。`object_id`は、そのランドマークに対応する`objects`内の要素の`id`（`present: false`または`objects`に個別要素として登録していない場合は`null`）。ランドマークの内部構造（例: `app_bar`の中に何が並んでいるか）は`landmarks`自体には持たせず、4節の`parent_id`で`objects`側に表現する。

### 4. `objects`の入れ子構造 — 前面/背面の二値ではなく親子関係の木で表す

「前面」「背面」という2値だけでは、UIの実際の入れ子構造を表現できない。例えば、AppBarの中に左からChevron(戻る)・中央寄せのTitle・右のActionButton(角丸四角の中にsettings歯車アイコン)が並んでいる場合、実際には次のような多段の包含関係になっている。

1. 画面全体の上にAppBarが乗っている
2. AppBarの上にChevron・Title・ActionButtonが乗っている
3. ActionButton（角丸四角のView）の上にsettings歯車アイコンが乗っている

これは「前面/背面」という2階層のフラグでは表現できない（特にActionButtonは、Titleなどと同じ階層の兄弟でありながら、自分自身も歯車アイコンを内包する親でもある）。そこでこのスキルでは、2節で定義した`objects[].parent_id`によって**任意の深さの木構造**として表現する。`parent_id`が同じ要素同士が兄弟であり、画面に直接置かれている要素は`parent_id: null`とする。

上記のAppBarの例をJSONで表すと以下のようになる（`bounding_box`等は省略）。

```json
{
  "objects": [
    { "id": "obj_appbar", "type": "app_bar", "parent_id": null },
    { "id": "obj_back_chevron", "type": "icon_button", "parent_id": "obj_appbar" },
    { "id": "obj_title", "type": "text_heading", "text": "設定", "parent_id": "obj_appbar" },
    { "id": "obj_settings_button", "type": "icon_button_container", "parent_id": "obj_appbar" },
    { "id": "obj_settings_gear_icon", "type": "icon", "labels": ["settings_gear"], "parent_id": "obj_settings_button" }
  ]
}
```

`obj_settings_button`（角丸四角のView）は自身がAppBarの子でありながら、`obj_settings_gear_icon`（歯車アイコン）から見れば親になっている。このように`parent_id`を辿るだけで、何段ネストしていても実際の包含関係をそのまま表現できる。

`z_index`（2節）は、この木構造だけでは表現できない**兄弟同士の重なり順**を補うためのものである。例えばダイアログは、通常メモ一覧などの画面本体と同じく画面直下（`parent_id: null`）に置かれる兄弟だが、画面本体より上に重なって表示される。この場合は入れ子ではなく`z_index`で表現する。

```json
{
  "objects": [
    { "id": "obj_1", "type": "card", "parent_id": null, "z_index": 0 },
    { "id": "obj_5", "type": "dialog", "labels": ["confirmation_dialog"], "parent_id": null, "z_index": 1 }
  ]
}
```

まとめると、「AがBの一部として描かれている」場合は`parent_id`（入れ子）、「AとBは独立した要素だがAがBの上に重なって表示されている」場合は同じ`parent_id`を持つ兄弟同士の`z_index`の大小で表現する。

### 5. `text_blocks` — OCRによるテキスト抽出

`objects[].text`が個々の要素に紐づくテキストであるのに対し、こちらは**画面内の可読テキストを網羅的に**抽出する（どの要素にも明確に紐づかない断片的な文字列も含む）。

```json
{
  "text_blocks": [
    { "text": "メモ一覧", "bounding_box": { "x": 0.30, "y": 0.94, "width": 0.16, "height": 0.03 } },
    { "text": "バニラソフト", "bounding_box": { "x": 0.08, "y": 0.20, "width": 0.30, "height": 0.03 } }
  ]
}
```

判読できるが意味が取れない文字列（潰れている・部分的に切れている等）も`text`にそのまま書き、判読不能な場合のみ`text`を`null`にして扱いを`notes`（6節）に書く。

### 6. `screen_understanding` — この画面が何を意味するものか

```json
{
  "screen_understanding": {
    "screen_name_guess": "メモ一覧画面",
    "app_state": "populated",
    "summary": "食べたソフトクリームのメモがカード形式で一覧表示されている画面。画面下部にタブナビゲーションがあり、「メモ一覧」タブが選択状態。",
    "notes": ["カードが多数並んでおり、画面外にスクロールで続きがある可能性がある（objects_count_confidence: medium）。"]
  }
}
```

- `app_state`: `loading` / `empty` / `populated` / `error` / `unknown` のいずれか。クラッシュ画面・白画面・意図しないシステムダイアログが写っている場合は`error`とし、`notes`に具体的な症状（`flutter-android-operate`/`flutter-ios-operate`の「よくある環境要因の落とし穴」に該当するものなど）を書く。
- `summary`: 何のアプリの何の画面で、何が表示されているかを日本語の自由文で簡潔に説明する。
- `notes`: 不確実性・判断に迷った点・スクロールで隠れている可能性など、他のフィールドに機械的に収まらない所見を配列で列挙する（無ければ空配列）。

## 出力全体の例

上記6セクションを1つのJSONオブジェクトにまとめたものが最終出力となる。

```json
{
  "source_image": "work/screenshots/mobile/note-list.png",
  "image_size": { "width": 1206, "height": 2622 },
  "objects": [
    {
      "id": "obj_1",
      "type": "card",
      "labels": ["list_item", "photo_thumbnail", "rating_indicator"],
      "text": "バニラソフト",
      "bounding_box": { "x": 0.05, "y": 0.18, "width": 0.90, "height": 0.22 },
      "bounding_box_confidence": "medium",
      "parent_id": null,
      "z_index": 0
    },
    {
      "id": "obj_5",
      "type": "tab_bar_item",
      "labels": ["navigation", "selected_state"],
      "text": "メモ一覧",
      "bounding_box": { "x": 0.30, "y": 0.94, "width": 0.16, "height": 0.05 },
      "bounding_box_confidence": "high",
      "parent_id": "obj_bottom_nav",
      "z_index": 0
    },
    {
      "id": "obj_bottom_nav",
      "type": "bottom_navigation_bar",
      "labels": [],
      "text": null,
      "bounding_box": { "x": 0, "y": 0.92, "width": 1.0, "height": 0.08 },
      "bounding_box_confidence": "high",
      "parent_id": null,
      "z_index": 0
    }
  ],
  "objects_count_confidence": "medium",
  "landmarks": [
    { "name": "status_bar", "present": true, "object_id": null },
    { "name": "app_bar", "present": false, "object_id": null },
    { "name": "bottom_navigation_bar", "present": true, "object_id": "obj_bottom_nav" },
    { "name": "floating_action_button", "present": false, "object_id": null },
    { "name": "modal_dialog", "present": false, "object_id": null },
    { "name": "empty_state_illustration", "present": false, "object_id": null }
  ],
  "text_blocks": [
    { "text": "バニラソフト", "bounding_box": { "x": 0.08, "y": 0.20, "width": 0.30, "height": 0.03 } },
    { "text": "メモ一覧", "bounding_box": { "x": 0.30, "y": 0.94, "width": 0.16, "height": 0.03 } }
  ],
  "screen_understanding": {
    "screen_name_guess": "メモ一覧画面",
    "app_state": "populated",
    "summary": "食べたソフトクリームのメモがカード形式で一覧表示されている画面。画面下部にタブナビゲーションがあり、「メモ一覧」タブが選択状態。",
    "notes": ["カードが多数並んでおり、画面外にスクロールで続きがある可能性がある。"]
  }
}
```

## 手順

1. Readツールで入力画像を開く。
2. まず`screen_understanding`（6節）を仮決めする。何のアプリの何の画面かという文脈を先に持つことで、以降の`objects`/`landmarks`の判定（例: このアイコンは「お気に入り」か「削除」か）の精度が上がる。
3. 画面内で視覚的に区別できる要素を列挙し、`objects`（2節）を埋める。小さすぎる・重なっている等で自信が無い要素は無理に省略も捏造もせず、`bounding_box_confidence: low`で残す。
4. `landmarks`（3節）の固定語彙それぞれについて有無を判定する。
5. 各要素の入れ子関係を確認し、`objects[].parent_id`（4節）を埋める。画面に直接置かれている要素は`null`のままにする。重なって表示されている兄弟要素（ダイアログ等）がある場合のみ`z_index`で順序を表す。
6. 画面内の可読テキストを`text_blocks`（5節）として網羅的に書き出す。
7. `screen_understanding`を最終的な内容に更新する（2〜6節を経て気づいた不確実性があれば`notes`に反映する）。
8. 6セクションを1つのJSONオブジェクトにまとめて出力する（Markdownの前置き・後置きの説明文は不要。JSON以外のテキストを含めない）。

## 出力の保存

呼び出し元スキル・agentから保存先パスの指定が無い場合は、入力画像と同じディレクトリに`<入力画像のファイル名（拡張子除く）>-analysis.json`として保存する（例: `note-list.png` → `note-list-analysis.json`）。呼び出し元から保存先や保存要否の指定がある場合はそちらに従う。
