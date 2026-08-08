# icecream-log 技術設計書

対応する要件定義: [requirements.md](./requirements.md)

## 技術選定（確定事項）

| 項目 | 選定 | 理由 |
|---|---|---|
| 店舗候補検索 | Google Places API (Nearby Search) | 日本国内の小規模店舗も含めた網羅性・精度を優先 |
| 地図表示 | Google Maps (`google_maps_flutter`) | 表示品質・情報量を優先 |
| ローカルDB | SQLite (`drift`) | フィルタ・検索条件をSQLで型安全に表現できる |
| 状態管理 | Riverpod | Flutterで標準的で、非同期のDB/API呼び出しとの相性が良い |
| Exif読み取り | `exif` パッケージ（Dart実装） | ネイティブ依存が少なく日時・GPSタグの読み取りに十分 |
| 写真取り込み | `image_picker` | カメラ撮影・ギャラリー選択の両方を標準サポート |
| レーダーチャート | `fl_chart`（RadarChart） | 純Dart実装でAPIキー・追加のネイティブ設定が不要。5軸評価の可視化に対応 |
| ルーティング | `go_router`（`StatefulShellRoute`） | ボトムナビゲーションのタブごとに画面スタックを保持しつつ、宣言的にモーダル遷移も扱える |
| プロフィール保存 | `shared_preferences` | ニックネーム・アイコンパスは単一レコードのみで、SQLによる検索・フィルタが不要なため |
| アプリバージョン取得 | `package_info_plus` | ビルド設定からアプリバージョンを取得する標準的な手段 |

いずれもAPIキー・課金が発生しうる選択（Google Places API, Google Maps）はユーザー承認済み。

## リポジトリ構成

将来バックエンドAPI等を追加する可能性があるため、モノレポ構成とする。Flutterプロジェクトはリポジトリ直下ではなく`mobile/`ディレクトリ配下に置く。

```
/
├── mobile/              # Flutterアプリ本体（本specsの実装対象）
│   ├── .fvmrc           # fvmで固定するFlutter SDKバージョン
│   ├── lib/
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── domain/
│   │   └── data/
│   └── ...
├── specs/               # 仕様駆動開発の成果物
├── .claude/
└── （将来追加想定: api/ など）
```

- Flutter SDKのバージョン管理には`fvm`を用いる。`mobile/`配下で`fvm use <version>`によりプロジェクト単位のバージョンを固定し、`.fvmrc`をコミットしてチーム/CIで再現性を担保する。以降のセットアップ・実行コマンドは`fvm flutter ...`の形で実行する前提とする。
- 本設計書内で示す`lib/`以下のディレクトリ構成は、すべて`mobile/lib/`を起点とする。

## ナビゲーション構造（REQ-8）

`go_router`の`StatefulShellRoute.indexedStack`で「メモ一覧」「設定」の2つを永続ブランチとして管理し、各ブランチは独立した画面スタックを保持する。中央の「メモ作成」はブランチ化せず、ボトムナビゲーションバー上の専用ボタンから`context.push`でトップレベルのルートを開く。このルートは`fullscreenDialog: true`のモーダルとして表示され、閉じると直前に選択していたブランチへ戻る。

```
AppShell (BottomNavigationBar: メモ一覧 / メモ作成(ボタン) / 設定)
 ├─ StatefulShellBranch "/notes"    → NotesTabScreen（List/Map切替。REQ-3, REQ-4）
 ├─ StatefulShellBranch "/settings" → SettingsScreen（REQ-9）
 └─ トップレベルroute "/memo/new"   → MemoEditScreen（fullscreenDialog、ブランチ外）
```

- 「メモ一覧」タブ = `NotesTabScreen`。内部で`ViewToggle`により`ListScreen`/`MapScreen`を切り替える（既存設計のまま）。
- 「メモ作成」はタブとして選択状態を持たない。モーダルを閉じた後は`StatefulShellRoute`の状態保持により、直前のタブのスクロール位置等がそのまま復元される。
- メモ一覧から既存メモをタップした場合は`MemoDetailScreen`をタブ内のスタックにpushする（モーダルではなく通常のpush遷移）。

## アーキテクチャ概要

レイヤードアーキテクチャを採用する。

```
presentation (Screens / Widgets)
      ↓ 参照
application (Riverpod Providers / Notifiers)
      ↓ 参照
domain (Entities / UseCases / Repositoryインターフェース)
      ↓ 実装
data (Repository実装 / drift DB / Google Places・Mapsクライアント)
```

- presentation層はapplication層のProviderのみを参照し、domain/data層を直接参照しない。
- domain層はFlutter/外部SDKに依存しない純粋なDartとし、テスト容易性を確保する。
- data層がGoogle Places API・drift DBへの実際のアクセスを担う。

## コンポーネント/モジュール構成

### presentation層
- `AppShell`: ボトムナビゲーション（メモ一覧/メモ作成/設定）を持つルートウィジェット。`go_router`の`StatefulShellRoute`に対応（REQ-8）
- `NotesTabScreen`: 「メモ一覧」ブランチのルート画面。`ViewToggle`で`ListScreen`/`MapScreen`を切り替える（REQ-8）
- `ListScreen`: メモの一覧表示（REQ-3）、フィルタUI（REQ-5）を含む
- `MapScreen`: メモの地図表示（REQ-4）
- `ViewToggle`: `ListScreen` / `MapScreen` を切り替えるUI（REQ-4）
- `SettingsScreen`: 「設定」ブランチのルート画面。ニックネーム編集・アイコン選択・アプリバージョン表示を含む（REQ-9）
- `MemoEditScreen`: 写真取り込み・Exif抽出結果の確認・手動編集（REQ-1, REQ-2, REQ-5）。感想リストの追加・編集・削除（REQ-6）、5軸評価の入力（REQ-7）もここで行う
- `StoreCandidatePicker`: 店舗候補から選択、または手動入力するダイアログ/シート（REQ-2）
- `ServingMachineFilterBar`: サービングマシンでの絞り込みUI（REQ-5）
- `MemoDetailScreen`: メモの閲覧専用画面。感想リストの表示（REQ-6）、`TasteRadarChart`による5軸評価の表示（REQ-7）。編集ボタンから`MemoEditScreen`へ遷移する
- `ImpressionListEditor`: 感想を箇条書きで追加・編集・削除するウィジェット（REQ-6）
- `TasteRadarChart`: 5軸評価を五角形のレーダーチャートとして描画するウィジェット。未評価時は代わりにプレースホルダーを表示する（REQ-7）

### application層（Riverpod）
- `memoListProvider`: フィルタ条件込みでメモ一覧をwatchする
- `viewModeProvider`: リスト/マップの表示状態を保持する
- `servingMachineFilterProvider`: 選択中のフィルタ条件を保持する
- `memoEditProvider`: 写真取り込みからExif抽出・店舗候補取得・保存までの一連のフローを制御する
- `profileProvider`: `UserProfile`（ニックネーム・アイコン）の取得・更新を行う
- `appVersionProvider`: `package_info_plus`から取得したアプリバージョンを保持する

### domain層
- エンティティ: `Memo`（`impressions: List<String>`, `tasteRating: TasteRating?` を含む）, `StoreCandidate`, `ServingMachine`, `TasteRating`（口当たり・素材の活かし方・個性的・フレーバーの良さ・温度管理を各1〜5のintで保持）, `UserProfile`（`nickname: String?`, `iconPath: String?`）
- ユースケース:
  - `ExtractPhotoMetadataUseCase`: 写真からExifの日時・GPSを抽出する
  - `SearchNearbyStoresUseCase`: 位置情報から店舗候補を取得する
  - `SaveMemoUseCase`: メモを作成・更新する
  - `WatchMemosUseCase`: フィルタ条件付きでメモ一覧を購読する
  - `SaveProfileUseCase` / `WatchProfileUseCase`: プロフィールの保存・購読を行う
- リポジトリインターフェース: `MemoRepository`, `StoreSearchRepository`, `ProfileRepository`

### data層
- `MemoRepositoryImpl`: driftで実装。CRUDとフィルタ付きクエリを提供
- `StoreSearchRepositoryImpl`: Google Places API (Nearby Search) をラップ
- `ExifService`: `exif` パッケージを使い写真バイナリから日時・GPSタグを抽出
- `ProfileRepositoryImpl`: `shared_preferences`でニックネーム・アイコンパスを保存・取得。選択されたアイコン画像はキャッシュ領域ではなくアプリのドキュメントディレクトリにコピーしてから保存する（一時ファイルが消えて参照切れになるのを防ぐため）
- drift定義: `AppDatabase`, `Memos` テーブル, `MemoImpressions` テーブル

## データモデル・API/インターフェース

### `Memos` テーブル（drift）

| カラム | 型 | 説明 |
|---|---|---|
| id | int, PK, autoincrement | メモID |
| photoPath | text | 取り込んだ写真のローカルパス |
| eatenDate | text, nullable | `yyyy-MM-dd`。Exifから取得、無ければ手動入力までnull |
| latitude | real, nullable | Exif GPSから取得 |
| longitude | real, nullable | Exif GPSから取得 |
| storeName | text, nullable | 確定した店舗名 |
| storePlaceId | text, nullable | Google Places候補から選択した場合のplace_id |
| servingMachine | text, nullable | 事前定義リストの値、または自由入力文字列 |
| mouthfeelRating | int, nullable | 口当たり（1〜5） |
| ingredientUseRating | int, nullable | 素材の活かし方（1〜5） |
| uniquenessRating | int, nullable | 個性的（1〜5） |
| flavorQualityRating | int, nullable | フレーバーの良さ（1〜5） |
| temperatureControlRating | int, nullable | 温度管理（1〜5） |
| createdAt | datetime | 作成日時 |
| updatedAt | datetime | 更新日時 |

サービングマシンの事前定義リストはDBテーブルではなくアプリ内定数として保持する（例: `["カルピジャーニ", "日世", "その他"]`）。フィルタ・保存時の値は自由入力文字列も同じ`servingMachine`カラムにそのまま格納する。

5軸評価はMemoごとに固定5項目・1:1の関係のため、子テーブルではなく`Memos`テーブルの列として保持する。5項目すべてがnullの場合は「未評価」として扱う（REQ-7）。

### `MemoImpressions` テーブル（drift）

| カラム | 型 | 説明 |
|---|---|---|
| id | int, PK, autoincrement | 感想ID |
| memoId | int, FK → Memos.id | 紐づくメモ |
| text | text | 感想の本文（箇条書きの1項目） |
| sortOrder | int | 表示順 |
| createdAt | datetime | 作成日時 |

感想は1メモに対して複数件持てるため、`Memos`とは1対多の別テーブルとする。保存時は`SaveMemoUseCase`が対象メモの感想を全件洗い替え（delete-then-insert）する方式とし、個別更新API は設けない（MVPとして簡素化）。

### 主要インターフェース

```dart
abstract class MemoRepository {
  Stream<List<Memo>> watchAll({String? servingMachineFilter});
  Future<void> save(Memo memo);
}

abstract class StoreSearchRepository {
  Future<List<StoreCandidate>> searchNearby(double lat, double lng);
}

abstract class ProfileRepository {
  Stream<UserProfile> watch();
  Future<void> save(UserProfile profile);
}

class ExifMetadata {
  final DateTime? capturedAt;
  final double? latitude;
  final double? longitude;
}

class TasteRating {
  final int mouthfeel;            // 口当たり 1-5
  final int ingredientUse;        // 素材の活かし方 1-5
  final int uniqueness;           // 個性的 1-5
  final int flavorQuality;        // フレーバーの良さ 1-5
  final int temperatureControl;   // 温度管理 1-5
}
```

## 各要件と設計要素の対応関係

| 要件 | 対応する設計要素 |
|---|---|
| REQ-1 (日付記録) | `ExifService` → `ExtractPhotoMetadataUseCase` → `Memo.eatenDate`（nullable, `MemoEditScreen`で手動編集可） |
| REQ-2 (店舗紐付け) | `ExifService`（GPS抽出）→ `SearchNearbyStoresUseCase` → `StoreSearchRepositoryImpl`（Google Places） → `StoreCandidatePicker` → `Memo.storeName` / `storePlaceId` |
| REQ-3 (リスト表示) | `ListScreen` + `memoListProvider` + `MemoRepository.watchAll()` |
| REQ-4 (マップ表示) | `MapScreen`（`google_maps_flutter`）+ `viewModeProvider`。`latitude`/`longitude`が非nullのメモのみマーカー表示 |
| REQ-5 (サービングマシン記録・フィルタ) | `Memo.servingMachine` + `ServingMachineFilterBar` + `servingMachineFilterProvider` + `MemoRepository.watchAll(servingMachineFilter: ...)` |
| REQ-6 (感想の記録) | `ImpressionListEditor`（`MemoEditScreen`に組み込み）→ `Memo.impressions` → `MemoImpressions`テーブル（洗い替え保存） → `MemoDetailScreen`で一覧表示 |
| REQ-7 (5軸評価・レーダーチャート) | `MemoEditScreen`の評価入力UI → `Memo.tasteRating` → `Memos`テーブルの5列 → `TasteRadarChart`（`MemoDetailScreen`に表示、未評価時はプレースホルダー） |
| REQ-8 (ナビゲーション構造) | `AppShell` + `go_router`の`StatefulShellRoute`（Notes/Settingsブランチ） + トップレベルモーダルroute（メモ作成） + `NotesTabScreen`内`ViewToggle` |
| REQ-9 (プロフィール設定) | `SettingsScreen` → `profileProvider` → `SaveProfileUseCase`/`WatchProfileUseCase` → `ProfileRepositoryImpl`（`shared_preferences`） / `appVersionProvider`（`package_info_plus`） |

## 検討したが採用しなかった代替案

- **flutter_map + OpenStreetMap**: APIキー不要・無料だが、日本国内の店舗POI精度がGoogleに劣るためREQ-2の店舗候補提示の質が下がると判断し不採用（ユーザー承認済み）。
- **Isar (NoSQL)**: セットアップは簡単だが、サービングマシン×日付など複合条件のフィルタをSQLほど自然に表現できないため不採用。
- **感想をJSON文字列として`Memos`テーブルの1カラムに格納する案**: 実装は簡単だが、将来的な検索・集計の余地を残すため不採用。1対多の`MemoImpressions`テーブルとして正規化する。
- **同一店舗の複数メモを横断してレーダーチャートを重ね合わせ表示する案**: 比較の価値はあるが、集計・UI実装コストが高くMVPスコープを超えるため今回は不採用（1メモ=1チャートに限定）。
- **「メモ作成」を`StatefulShellRoute`の3つ目のブランチとして常駐タブ化する案**: 実装は単純だが、押すたびに空の作成フォームへ強制遷移しタブの選択状態も持ち続けるため、Notes/Settingsのタブ位置に戻りたい操作感を損なうと判断し不採用。フルスクリーンモーダル方式を採用。
- **プロフィールをdriftのテーブルとして保存する案**: 単一レコードしか持たずSQLクエリの恩恵が薄いため、`shared_preferences`によるシンプルな保存を採用。

## 既知のリスク

- **APIコスト**: Google Places API・Google Mapsは利用量に応じて課金される。同一座標への重複リクエストを避けるキャッシュ、または利用量アラートの設定を実装時に検討する。
- **Exif欠損**: スクリーンショットや一部SNS経由の画像はExifが失われている場合があり、その際はREQ-1/REQ-2の空欄保存・手動編集フローに委ねる。
- **権限**: 写真ライブラリアクセス（iOS: `NSPhotoLibraryUsageDescription`、Android 13+: `READ_MEDIA_IMAGES`）の許諾フローが必要。位置情報の常時許可は不要（Exifに埋め込まれた位置情報を読むのみで、リアルタイム位置取得は行わない）。
