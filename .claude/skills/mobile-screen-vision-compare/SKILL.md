---
name: mobile-screen-vision-compare
description: モバイルアプリのスクリーンからVLM（Vision-Language Model）を用いて分析された構造化データともう一方の構造化データを比較する。
---

# 比較対象

### 比較元 (source)

比較元はモバイルスクリーンの構造化データである。

### 比較先 (target)

比較先はいくつかパターンが想定される。

1. モバイルスクリーンの構造化データ（`mobile-screen-vision-analyze`スキルの出力）

2. Figmaなどのデザインデータ

Figmaの場合、Figmaリファレンス画像パスを指定してその構造情報をMCP（`get_metadata`や`get_design_context`）で取得することができ、その形式はXMLである。同じ構造化データであるため形式は違えど比較は可能である。

https://developers.figma.com/docs/figma-mcp-server/tools-and-prompts/#get_metadata

3. ユーザーの依頼や指示

ユーザーの依頼や指示についてはほぼこの3パターンに分類される。

a. 機能やUIの追加
b. 機能やUIの削除
c. 現行から変化がないことの確認

a, b, cいずれもソースコードから影響範囲と変更内容を特定することが重要である。そこから予想される結果と得られた対象の構造化データを比較し、その内容が依頼や指示しているかを判断する

## ゴール

### 評価観点（チェックリスト）

以下の5観点について、それぞれ「一致(`match`) / 軽微な差異(`minor_diff`) / 不一致(`mismatch`) / 該当なし(`not_applicable`)」の4段階で判定してください。

| 観点(`aspect`) | 見るもの |
|---|---|
| `layout_structure`（画面構成） | ヘッダー/本文/フッター(ボトムナビ)などの大枠セクションが、比較対象と同じ数・同じ並びで存在するか |
| `element_presence`（要素の有無） | 比較対象に含まれる個々の要素（タイトル、ボタン、チップ、カード、チャート等）が実装側にすべて存在するか。過不足を具体的に列挙する |
| `arrangement_order`（配置・順序） | 各要素の相対的な位置関係（上下左右の並び順）が一致しているか |
| `text_labels`（テキスト/ラベル内容） | ボタンラベルや見出しの文言が、比較対象と一致しているか |
| `state_representation`（状態表現） | 空状態・未入力状態・選択状態など、比較対象が示す状態が実装でも再現されているか（対象外なら`not_applicable`） |

各観点は「一致」以外の場合、`diff`に具体的な差分を日本語で記述してください。

### 総合判定（`overall_verdict`）

- `exact_match`（完全一致）: 全観点が`match`
- `close_match`（ほぼ一致）: `minor_diff`のみ（余白・色味・アイコン種類など実装の裁量範囲内の違い）
- `partial_match`（部分一致）: 構造は合っているが要素の過不足・配置の違いがある
- `major_divergence`（大きく乖離）: 主要な構造（セクション数や画面遷移の前提）から異なる
