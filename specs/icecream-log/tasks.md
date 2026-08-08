# icecream-log タスクリスト

対応する設計書: [design.md](./design.md) / 要件定義: [requirements.md](./requirements.md)

## 基盤

- [ ] T1: リポジトリ直下に`mobile/`ディレクトリを作成し、その配下に`fvm`でFlutter SDKバージョンを固定した上でFlutterプロジェクトを新規作成する。依存パッケージ（drift, riverpod, google_maps_flutter, image_picker, exif, fl_chart, go_router, shared_preferences, package_info_plus等）を追加し、Android/iOSの権限設定とGoogle Maps/Places APIキー設定を行う。（design: リポジトリ構成, 技術選定, 既知のリスク-権限）
- [ ] T2: `go_router`で`AppShell`を実装する。`StatefulShellRoute.indexedStack`で「メモ一覧」「設定」の2ブランチを用意し、ボトムナビゲーション中央の「メモ作成」ボタンからフルスクリーンモーダルとしてメモ作成ルートを開く導線を用意する（各画面はこの時点ではプレースホルダーで良い）。（REQ-8）— 依存: T1

## domain層

- [ ] T3: エンティティ（`Memo`（`impressions`, `tasteRating`を含む）, `StoreCandidate`, `ServingMachine`, `TasteRating`, `UserProfile`）とリポジトリインターフェース（`MemoRepository`, `StoreSearchRepository`, `ProfileRepository`）を定義する。（design: domain層）— 依存: T1

## data層

- [ ] T4: driftで`AppDatabase`、`Memos`テーブル（5軸評価の5列を含む）、`MemoImpressions`テーブルを実装する。（design: データモデル）— 依存: T3
- [ ] T5: `MemoRepositoryImpl`を実装し、CRUD（感想リストの洗い替え保存を含む）と`servingMachineFilter`付き`watchAll`を提供する。（design: data層）— 依存: T4
- [ ] T6: `ExifService`を実装し、写真から撮影日時・GPS情報を抽出する。（REQ-1, REQ-2）— 依存: T1
- [ ] T7: `StoreSearchRepositoryImpl`を実装し、Google Places Nearby Searchで店舗候補を取得する。（REQ-2）— 依存: T1, T3
- [ ] T8: `ProfileRepositoryImpl`を実装する。`shared_preferences`にニックネームを保存し、選択されたアイコン画像はアプリのドキュメントディレクトリにコピーしてからパスを保存する。（REQ-9）— 依存: T3
- [ ] T9: `package_info_plus`をラップしたアプリバージョン取得ユーティリティを実装する。（REQ-9）— 依存: T1

## domain層（ユースケース）

- [ ] T10: `ExtractPhotoMetadataUseCase`, `SearchNearbyStoresUseCase`, `SaveMemoUseCase`（感想・5軸評価の保存を含む）, `WatchMemosUseCase`を実装する。（design: domain層）— 依存: T5, T6, T7
- [ ] T11: `SaveProfileUseCase`, `WatchProfileUseCase`を実装する。（REQ-9）— 依存: T8

## application層

- [ ] T12: Riverpod Providers（`memoListProvider`, `viewModeProvider`, `servingMachineFilterProvider`, `memoEditProvider`）を実装する。（design: application層）— 依存: T10
- [ ] T13: Riverpod Providers（`profileProvider`, `appVersionProvider`）を実装する。（design: application層）— 依存: T11, T9

## presentation層（メモ作成・編集）

- [ ] T14: `MemoEditScreen`を実装し、T2で用意したモーダルルートに接続する。写真取り込み→Exif抽出結果表示→日付欄が空欄の場合の手動入力に対応する。（REQ-1, REQ-8）— 依存: T2, T12
- [ ] T15: `StoreCandidatePicker`を実装し`MemoEditScreen`に組み込む。位置情報が無い場合の手動入力にも対応する。（REQ-2）— 依存: T14
- [ ] T16: `MemoEditScreen`にサービングマシンの選択UI（事前定義リスト＋自由入力）を追加する。（REQ-5）— 依存: T14
- [ ] T17: `ImpressionListEditor`を実装し、`MemoEditScreen`に組み込む（感想の箇条書き追加・編集・削除）。（REQ-6）— 依存: T14
- [ ] T18: `MemoEditScreen`に5軸評価（口当たり・素材の活かし方・個性的・フレーバーの良さ・温度管理、各1〜5）の入力UIを追加する。（REQ-7）— 依存: T14

## presentation層（メモ一覧・地図）

- [ ] T19: `ListScreen`を実装し、日付・お店・サービングマシンを含む一覧表示を行う。（REQ-3）— 依存: T12
- [ ] T20: `ServingMachineFilterBar`を実装し`ListScreen`に組み込む。（REQ-5）— 依存: T19
- [ ] T21: `MapScreen`を実装し、位置情報を持つメモをピン表示する。（REQ-4）— 依存: T12
- [ ] T22: `ViewToggle`を実装し、`ListScreen`/`MapScreen`を切り替えられるようにする。（REQ-4）— 依存: T19, T21
- [ ] T23: `NotesTabScreen`として`ListScreen`/`MapScreen`/`ViewToggle`をまとめ、T2の「メモ一覧」ブランチに接続する。（REQ-8）— 依存: T22
- [ ] T24: フィルタ条件がリスト表示・マップ表示の両方に反映されることを確認する。（REQ-5）— 依存: T20, T23
- [ ] T25: `TasteRadarChart`を`fl_chart`で実装する。5軸評価が未入力の場合は未評価プレースホルダーを表示する。（REQ-7）— 依存: T12
- [ ] T26: `MemoDetailScreen`を実装し、感想リストの表示と`TasteRadarChart`の表示、`MemoEditScreen`への編集導線を提供する。メモ一覧からのタップで（モーダルではなく）タブ内スタックにpushする。（REQ-6, REQ-7, REQ-8）— 依存: T17, T18, T25, T23

## presentation層（設定）

- [ ] T27: `SettingsScreen`を実装し、T2の「設定」ブランチに接続する。ニックネーム編集、アイコン選択・表示、アプリバージョン表示を行う。（REQ-9）— 依存: T13, T2

## テスト

- [ ] T28: domain層ユースケースのユニットテストを追加する（Exif欠損時のフォールバック、フィルタ条件、感想の洗い替え保存、5軸評価の未入力ケース、プロフィール保存など）。— 依存: T10, T11
- [ ] T29: 主要フロー（写真取り込み→編集→一覧反映、リスト⇔マップ切替、感想・5軸評価の入力→詳細画面での表示、タブ切替とメモ作成モーダルの開閉、設定画面でのプロフィール編集）のウィジェット/結合テストを追加する。— 依存: T24, T26, T27
