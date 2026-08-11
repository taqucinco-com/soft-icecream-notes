# icecream-log 技術設計書

対応する要件定義: [requirements.md](./requirements.md)

## Figmaワイヤーフレームとの対応関係

主要フローのワイヤーフレームを以下のFigmaファイルで管理する。実装・Widgetテスト（将来的なgoldenテストを含む）双方の視覚的なリファレンスとして用いる。

参照: [soft-icecream-notes ワイヤーフレーム](https://www.figma.com/design/SJrMIHprlAHd0LQVMDTaGz/soft-icecream-notes-%E3%83%AF%E3%82%A4%E3%83%A4%E3%83%BC%E3%83%95%E3%83%AC%E3%83%BC%E3%83%A0)（Wireframesページ）

| Figmaフレーム（node-id） | 対応する画面/コンポーネント | 対応要件 |
|---|---|---|
| 01_メモ一覧_リスト（2:2） | `ListScreen`（`NotesTabScreen`内） | REQ-3, REQ-5, REQ-8 |
| 02_メモ一覧_マップ（2:3） | `MapScreen`（`NotesTabScreen`内） | REQ-4, REQ-5, REQ-8 |
| 03_メモ作成編集（2:4） | `MemoEditScreen`（`StoreCandidatePicker`, サービングマシン選択, `ImpressionListEditor`, 5軸評価入力を内包） | REQ-1, REQ-2, REQ-5, REQ-6, REQ-7, REQ-8 |
| 04_メモ詳細（2:5） | `MemoDetailScreen`（`TasteRadarChart`を含む） | REQ-6, REQ-7 |
| 05_設定（2:6） | `SettingsScreen` | REQ-9 |

各フレームへの直接リンクは、上記URLに`?node-id=<node-idのハイフン区切り>`を付与して開く（例: 03は`?node-id=2-4`）。

ワイヤーフレームで判明した設計上の詳細を1点反映する: `StoreCandidatePicker`は独立したダイアログ/シートではなく、フォーム内にインラインの候補チップ（候補1・候補2・手動で入力）として表示される構成になっている（後述のコンポーネント一覧を参照）。

## 技術選定（確定事項）

| 項目 | 選定 | 理由 |
|---|---|---|
| 店舗候補検索 | Google Places API (Nearby Search) | 日本国内の小規模店舗も含めた網羅性・精度を優先 |
| 店舗検索結果キャッシュ | drift（`StoreSearchCache`テーブル、TTL既定30日） | APIコスト削減のため、アプリ再起動をまたいで永続化する |
| 地図表示 | Google Maps (`google_maps_flutter`) | 表示品質・情報量を優先 |
| ローカルDB | SQLite (`drift`) | フィルタ・検索条件をSQLで型安全に表現できる |
| 状態管理 | Riverpod | Flutterで標準的で、非同期のDB/API呼び出しとの相性が良い |
| Exif読み取り | `exif` パッケージ（Dart実装） | ネイティブ依存が少なく日時・GPSタグの読み取りに十分 |
| 写真取り込み | `image_picker` | カメラ撮影・ギャラリー選択の両方を標準サポート |
| レーダーチャート | `fl_chart`（RadarChart） | 純Dart実装でAPIキー・追加のネイティブ設定が不要。5軸評価の可視化に対応 |
| ルーティング | `go_router`（`StatefulShellRoute`） | ボトムナビゲーションのタブごとに画面スタックを保持しつつ、宣言的にモーダル遷移も扱える |
| プロフィール保存 | `shared_preferences` | ニックネーム・アイコンパスは単一レコードのみで、SQLによる検索・フィルタが不要なため |
| アプリバージョン取得 | `package_info_plus` | ビルド設定からアプリバージョンを取得する標準的な手段 |
| DI（依存性注入） | Riverpod（`riverpod_generator`の`@riverpod`） | 状態管理とDIを1つの仕組みに統一できる。2026年時点でもRiverpod単体でのDIが主流であり、`get_it`/`injectable`は不採用（参考: [live4inc/magma-app](https://github.com/live4inc/magma-app)） |
| テストダブル | `mocktail` | コード生成不要でループエンジニアリングの反復速度を落とさないため、`mockito`（要build_runner）より優先 |

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

## 依存性注入（DI）の方針

DIコンテナは別途導入せず、Riverpodのプロバイダグラフをそのまま依存解決に用いる。`get_it`・`injectable`は使用しない。この方針は[live4inc/magma-app](https://github.com/live4inc/magma-app)（Riverpodのみで全DIを構成し、`get_it`/`injectable`を持たない）を参考にしており、2026年時点でもRiverpod単体でのDIが主流という調査結果とも合致する。

- Provider定義には`riverpod_generator`の`@riverpod`アノテーションを用いる（手書きの`Provider()`は使わない）。`build_runner`はdrift・freezedと合わせて実行する。
- domain層のリポジトリ/ユースケースごとに、実装を返す`@riverpod`関数を1つ用意し、戻り値の型はインターフェース（例: `MemoRepository`）にする。呼び出し側はインターフェース型のみに依存し、実装クラスを直接importしない。
- 依存の合成は`ref.watch`で行う。例えば`MemoRepositoryImpl`が`AppDatabase`に依存する場合、`memoRepository`プロバイダ関数内で`ref.watch(appDatabaseProvider)`を渡す。

```dart
@riverpod
MemoRepository memoRepository(Ref ref) {
  return MemoRepositoryImpl(ref.watch(appDatabaseProvider));
}
```

DI用プロバイダの一覧（呼び出し名は生成される`xxxProvider`）:
- data層: `appDatabase`, `memoRepository`, `storeSearchRepository`, `exifService`, `profileRepository`
- domain層（ユースケース）: `extractPhotoMetadataUseCase`, `searchNearbyStoresUseCase`, `saveMemoUseCase`, `watchMemosUseCase`, `saveProfileUseCase`, `watchProfileUseCase`

これらのDI用プロバイダはpresentation層から直接参照せず、application層のUI向けProvider（`memoListProvider`等）を経由してのみ利用する。

## 状態管理・キャッシュ方針

Riverpodでの状態管理は、データの性質によって3つの方針に分ける。

### ローカル永続データ（メモ一覧）

`MemoRepository.watchAll()`はdriftの`watch()`クエリで実装するため、書き込み（`SaveMemoUseCase`実行）後は自動的に新しい値がStreamに流れる。`memoList`は`@riverpod`の`Stream`関数とし、`servingMachineFilterProvider`を`ref.watch`することでフィルタ変更時も自動的に再購読される。手動での`ref.invalidate()`は不要。

```dart
@riverpod
Stream<List<Memo>> memoList(Ref ref) {
  final filter = ref.watch(servingMachineFilterProvider);
  return ref.watch(memoRepositoryProvider).watchAll(servingMachineFilter: filter);
}
```

### 外部APIデータ（Google Places候補）

課金対象のAPIのため、`StoreSearchRepositoryImpl`がdriftへの永続キャッシュを持つ（詳細は「データモデル・API/インターフェース」の`StoreSearchCache`テーブルを参照）。座標を小数点以下4桁（緯度経度とも約11m四方）に丸めたキーでキャッシュを引き、TTL（既定30日）以内ならAPIを呼ばずキャッシュ済みの結果を返す。Riverpod側の`searchNearbyStores`プロバイダはこのキャッシュ込みの`StoreSearchRepository`を呼ぶだけで良く、Riverpod自体に追加のキャッシュ機構は持たせない。

### 一時的なUI状態

`servingMachineFilterProvider`, `viewModeProvider`, `memoEditProvider`はいずれも`@riverpod`のデフォルト（`autoDispose`）でよい。go_routerの`StatefulShellRoute`が「メモ一覧」「設定」各ブランチのWidgetツリーを保持し続けるため、タブ切り替えではフィルタ等の状態は消えない。`memoEditProvider`（編集中の下書き状態）はモーダル（メモ作成/編集画面）を閉じるとWidgetごと破棄されるため、下書きが意図せず次回に持ち越されることもない。

### DI用プロバイダ

`appDatabase`, `memoRepository`, `storeSearchRepository`, `profileRepository`, `exifService`はアプリ全体で使い回すシングルトンとして扱うため`@Riverpod(keepAlive: true)`を付与し、画面遷移のたびに再生成・再接続されないようにする。

## テスト容易性（テスタビリティ）とループエンジニアリングでの検証可能性

本プロジェクトの実装は「実装 → 自動テストによる検証 → 次のタスクへ」というループ（ループエンジニアリング）を前提に進める。そのため、人手による目視確認に頼らず、各タスクが自動テストのみで合否判定できることを設計上の必須制約とする。

### 原則

- domain層はFlutter SDK・プラットフォームチャネル・外部パッケージのAPIに一切依存しない純粋なDartとする（アーキテクチャ概要の制約を再掲）。これにより`flutter test`のみでエミュレータ・実機なしに高速検証できる。
- data層の実装（`MemoRepositoryImpl`等）はコンストラクタ経由で依存（`AppDatabase`、HTTPクライアント等）を受け取り、テストでは本物の代わりにフェイク/インメモリ実装に差し替えられる構造にする（DIの方針でRiverpod経由の差し替えができる構造がすでに前提）。
- 外部I/O（Google Places API、Google Maps描画、端末の写真ライブラリ、位置情報、`shared_preferences`）に実際にアクセスするテストは書かない。代わりに次を用いる:
  - drift: `NativeDatabase.memory()`によるインメモリDBでCRUD・フィルタ・Stream発火・`StoreSearchCache`のTTL判定をテストする
  - Google Places API: `StoreSearchRepository`インターフェースをテスト用フェイクに差し替える。HTTP通信自体を検証したい場合のみモックHTTPクライアントを使う
  - Exif抽出: Exifあり/なしのテスト用画像フィクスチャで`ExifService`を直接テストし、それより上位の層は`ExifMetadata`を返すフェイクに差し替える
  - `shared_preferences`: `SharedPreferences.setMockInitialValues`、`package_info_plus`: `PackageInfo.setMockInitialValues`を用いる
  - `image_picker` / `google_maps_flutter`等プラットフォームチャネルに依存するWidgetは、Riverpodの`ProviderScope(overrides: [...])`でDI用プロバイダをフェイクに差し替えた上でWidgetテストする
- tasks.mdの各タスクは「実装」と「その実装を検証する自動テスト」を同一タスク内で完了させることを原則とし、テストを後続タスクへ先送りしない。1タスク（ループの1イテレーション）の完了条件は「対応するテストがgreenであること」とする。
- presentation層のWidgetテストは、「Figmaワイヤーフレームとの対応関係」に挙げた該当フレームを一次情報とし、要素の有無・大まかな配置がワイヤーフレームと矛盾しないことを確認する。将来goldenテストを導入する場合も、このフレームのスクリーンショットを比較対象の起点とする。

### テストダブルの方針

- モックライブラリは`mocktail`を採用する。`mockito`はコード生成（`@GenerateMocks`+build_runner）が必要でループの反復速度を落とすため、コード生成不要な`mocktail`を優先する。
- リポジトリ・ユースケースのフェイク実装は`test/fakes/`配下にまとめ、複数のテストから再利用する。

## コンポーネント/モジュール構成

### presentation層
- `AppShell`: ボトムナビゲーション（メモ一覧/メモ作成/設定）を持つルートウィジェット。`go_router`の`StatefulShellRoute`に対応（REQ-8）
- `NotesTabScreen`: 「メモ一覧」ブランチのルート画面。`ViewToggle`で`ListScreen`/`MapScreen`を切り替える（REQ-8）
- `ListScreen`: メモの一覧表示（REQ-3）、フィルタUI（REQ-5）を含む
- `MapScreen`: メモの地図表示（REQ-4）
- `ViewToggle`: `ListScreen` / `MapScreen` を切り替えるUI（REQ-4）
- `SettingsScreen`: 「設定」ブランチのルート画面。ニックネーム編集・アイコン選択・アプリバージョン表示を含む（REQ-9）
- `MemoEditScreen`: 写真取り込み・Exif抽出結果の確認・手動編集（REQ-1, REQ-2, REQ-5）。感想リストの追加・編集・削除（REQ-6）、5軸評価の入力（REQ-7）もここで行う
- `StoreCandidatePicker`: `MemoEditScreen`のフォーム内にインライン表示する候補チップ群。店舗候補（例: 候補1・候補2）から選択、または「手動で入力」を選ぶと自由入力欄に切り替わる（REQ-2、Figma: 03_メモ作成編集）
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

### `StoreSearchCache` テーブル（drift）

| カラム | 型 | 説明 |
|---|---|---|
| id | int, PK, autoincrement | キャッシュID |
| latBucket | real | 緯度を小数点以下4桁（約11m四方）に丸めた値。キャッシュキーの一部 |
| lngBucket | real | 経度を同様に丸めた値。キャッシュキーの一部 |
| resultsJson | text | `List<StoreCandidate>`をシリアライズしたJSON |
| fetchedAt | datetime | APIから取得した日時。TTL判定に用いる |

`(latBucket, lngBucket)`に一意インデックスを張る。`StoreSearchRepositoryImpl.searchNearby(lat, lng)`は、入力座標を丸めてこのテーブルを検索し、`fetchedAt`からTTL（既定30日）以内のレコードがあればAPIを呼ばずに`resultsJson`をデシリアライズして返す。無ければGoogle Places APIを呼び、結果をここにupsertしてから返す。

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
| REQ-2 (店舗紐付け) | `ExifService`（GPS抽出）→ `SearchNearbyStoresUseCase` → `StoreSearchRepositoryImpl`（Google Places、`StoreSearchCache`で永続キャッシュ） → `StoreCandidatePicker` → `Memo.storeName` / `storePlaceId` |
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
- **`get_it`/`injectable`によるDIコンテナ導入案**: Riverpod単体で状態管理・DIの両方を賄え、参照実装（live4inc/magma-app）や2026年時点の主流とも合致するため、追加のDIライブラリは導入コストに見合わないと判断し不採用。
- **Google Places検索結果をRiverpodのプロバイダキャッシュ（メモリのみ）で済ませる案**: 実装は簡素だが、アプリ再起動でキャッシュが消え同じ店への再訪問のたびにAPI課金が発生するため不採用。driftによる永続キャッシュ（`StoreSearchCache`）を採用。
- **`mockito`をテストダブルに採用する案**: `@GenerateMocks`によるコード生成が必要で、ループエンジニアリングの1イテレーションごとに`build_runner`実行を挟むことになり反復速度が落ちるため不採用。コード生成不要な`mocktail`を採用。

## 既知のリスク

- **APIコスト**: Google Places API・Google Mapsは利用量に応じて課金される。Places APIについては`StoreSearchCache`による永続キャッシュ（TTL30日）で同一座標への重複リクエストを避ける設計としたが、Google Maps自体の表示課金やキャッシュ対象外のケースに備え、利用量アラートの設定は実装時に別途検討する。
- **Exif欠損**: スクリーンショットや一部SNS経由の画像はExifが失われている場合があり、その際はREQ-1/REQ-2の空欄保存・手動編集フローに委ねる。
- **権限**: 写真ライブラリアクセス（iOS: `NSPhotoLibraryUsageDescription`、Android 13+: `READ_MEDIA_IMAGES`）の許諾フローが必要。位置情報の常時許可は不要（Exifに埋め込まれた位置情報を読むのみで、リアルタイム位置取得は行わない）。
