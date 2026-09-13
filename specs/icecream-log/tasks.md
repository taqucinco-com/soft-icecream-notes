# icecream-log タスクリスト

対応する設計書: [design.md](./design.md) / 要件定義: [requirements.md](./requirements.md)

> 各タスクは「実装」と「検証」をセットで完了とする（design.mdの「テスト容易性とループエンジニアリングでの検証可能性」を参照）。人手の目視確認ではなく、各タスクに記載した検証が自動テストとしてgreenになることを完了条件とする。

## 基盤

- [ ] T1: リポジトリ直下に`mobile/`ディレクトリを作成し、その配下に`fvm`でFlutter SDKバージョンを固定した上でFlutterプロジェクトを新規作成する。依存パッケージ（drift, riverpod, riverpod_generator, google_maps_flutter, image_picker, exif, fl_chart, go_router, shared_preferences, package_info_plus, mocktail等）とbuild_runnerを追加し、Android/iOSの権限設定とGoogle Maps/Places APIキー設定を行う。（design: リポジトリ構成, 技術選定, DIの方針, 既知のリスク-権限）
  - 検証: `fvm flutter analyze`と`fvm flutter test`が（テストファイルが空でも）エラーなく完了すること。
- [ ] T2: `go_router`で`AppShell`を実装する。`StatefulShellRoute.indexedStack`で「メモ一覧」「設定」の2ブランチを用意し、ボトムナビゲーション中央の「メモ作成」ボタンからフルスクリーンモーダルとしてメモ作成ルートを開く導線を用意する（各画面はこの時点ではプレースホルダーで良い）。（REQ-8）— 依存: T1
  - 検証: Widgetテストで、タブ切替時に各ブランチのスタックが保持されること、中央ボタンでモーダルが開き、閉じると直前のタブに戻ることを確認する。

## domain層

- [ ] T3: エンティティ（`Memo`（`impressions`, `tasteRating`を含む）, `StoreCandidate`, `ServingMachine`, `TasteRating`, `UserProfile`）とリポジトリインターフェース（`MemoRepository`, `StoreSearchRepository`, `ProfileRepository`）を定義する。（design: domain層）— 依存: T1
  - 検証: エンティティの等価性・不変条件（`TasteRating`の各項目が1〜5の範囲であることなど）をユニットテストで確認する。

## data層

- [ ] T4: driftで`AppDatabase`、`Memos`テーブル（5軸評価の5列を含む）、`MemoImpressions`テーブル、`StoreSearchCache`テーブルを実装する。（design: データモデル）— 依存: T3
  - 検証: `NativeDatabase.memory()`によるインメモリDBに対し、各テーブルへの挿入・取得が期待通り動くことをユニットテストで確認する。
- [ ] T5: `MemoRepositoryImpl`を実装し、CRUD（感想リストの洗い替え保存を含む）と`servingMachineFilter`付き`watchAll`を提供する。戻り値の型を`MemoRepository`とする`@riverpod`関数（`memoRepository`）も併せて定義する。（design: data層, DIの方針）— 依存: T4
  - 検証: インメモリDBを使い、保存後に`watchAll()`のStreamへ反映されること、フィルタ条件での絞り込み、感想の洗い替え（更新のたびに古い感想が消え新しい感想に置き換わる）をユニットテストで確認する。
- [ ] T6: `ExifService`を実装する。写真から撮影日時・GPS情報を抽出する。`@riverpod`関数（`exifService`）も併せて定義する。（REQ-1, REQ-2, design: DIの方針）— 依存: T1
  - 検証: Exifあり/なしのテスト用画像フィクスチャを用意し、日時・GPS抽出とnullフォールバックの双方をユニットテストで確認する。
- [ ] T7: `StoreSearchRepositoryImpl`を実装する。座標を丸めたキーで`StoreSearchCache`を検索し、TTL（30日）以内のキャッシュがあればそれを返し、無ければGoogle Places Nearby Searchを呼んで結果をキャッシュにupsertする。戻り値の型を`StoreSearchRepository`とする`@riverpod`関数（`storeSearchRepository`）も併せて定義する。（REQ-2, design: DIの方針, 状態管理・キャッシュ方針）— 依存: T1, T4
  - 検証: フェイクのAPIクライアント（`mocktail`）とインメモリDBを使い、キャッシュミス時にAPIが呼ばれること、キャッシュヒット時にAPIを呼ばないこと、TTL失効後は再度APIが呼ばれることの3パターンをユニットテストで確認する。
- [ ] T8: `ProfileRepositoryImpl`を実装する。`shared_preferences`にニックネームを保存し、選択されたアイコン画像はアプリのドキュメントディレクトリにコピーしてからパスを保存する。戻り値の型を`ProfileRepository`とする`@riverpod`関数（`profileRepository`）も併せて定義する。（REQ-9, design: DIの方針）— 依存: T3
  - 検証: `SharedPreferences.setMockInitialValues`を使い、保存・取得の往復をユニットテストで確認する。
- [ ] T9: `package_info_plus`をラップしたアプリバージョン取得ユーティリティを実装する。（REQ-9）— 依存: T1
  - 検証: `PackageInfo.setMockInitialValues`を使い、バージョン文字列が期待通り取得できることをユニットテストで確認する。

## domain層（ユースケース）

- [ ] T10: `ExtractPhotoMetadataUseCase`, `SearchNearbyStoresUseCase`, `SaveMemoUseCase`（感想・5軸評価の保存を含む）, `WatchMemosUseCase`を実装し、それぞれに対応する`@riverpod`関数（DI用プロバイダ）を定義する。（design: domain層, DIの方針）— 依存: T5, T6, T7
  - 検証: `test/fakes/`のフェイクリポジトリ（`mocktail`または手書きフェイク）を使い、各ユースケースをリポジトリ実体（drift/API）から切り離してユニットテストする。
- [ ] T11: `SaveProfileUseCase`, `WatchProfileUseCase`を実装し、それぞれに対応する`@riverpod`関数（DI用プロバイダ）を定義する。（REQ-9, design: DIの方針）— 依存: T8
  - 検証: フェイクの`ProfileRepository`を使い、保存・購読をユニットテストする。

## application層

- [ ] T12: UI向けRiverpod Providers（`memoListProvider`, `viewModeProvider`, `servingMachineFilterProvider`, `memoEditProvider`）を実装する。内部でT10のユースケース用`@riverpod`関数を`ref.watch`する。（design: application層）— 依存: T10
  - 検証: `ProviderContainer(overrides: [...])`でDI用プロバイダをフェイクに差し替え、フィルタ変更で`memoListProvider`が再購読されること、`viewModeProvider`のトグルが期待通り動くことをユニットテストで確認する。
- [ ] T13: UI向けRiverpod Providers（`profileProvider`, `appVersionProvider`）を実装する。内部でT11のユースケース用`@riverpod`関数と`package_info_plus`ラッパー（T9）を`ref.watch`する。（design: application層）— 依存: T11, T9
  - 検証: `ProviderContainer(overrides: [...])`でフェイクに差し替え、プロフィール更新が反映されることをユニットテストで確認する。

## presentation層（メモ作成・編集）

- [ ] T14: `MemoEditScreen`を実装し、T2で用意したモーダルルートに接続する。写真取り込み→Exif抽出結果表示→日付欄が空欄の場合の手動入力に対応する。（REQ-1, REQ-8, Figma: 03_メモ作成編集 node-id 2:4）— 依存: T2, T12
  - 検証: `ProviderScope(overrides: [...])`で`image_picker`/`memoEditProvider`をフェイクに差し替え、Exifありの場合は日付が自動表示され、Exifなしの場合は手動入力欄が表示されることをWidgetテストで確認する。
- [ ] T15: `StoreCandidatePicker`を実装し`MemoEditScreen`に組み込む。フォーム内インラインの候補チップ（候補1・候補2・手動で入力）として表示し、位置情報が無い場合の手動入力にも対応する。（REQ-2, Figma: 03_メモ作成編集 node-id 2:4）— 依存: T14
  - 検証: フェイクの`StoreSearchRepository`が返す候補一覧から選択できること、位置情報が無い場合は手動入力欄が表示されることをWidgetテストで確認する。
- [ ] T16: `MemoEditScreen`にサービングマシンの選択UI（事前定義リスト＋自由入力）を追加する。（REQ-5, Figma: 03_メモ作成編集 node-id 2:4）— 依存: T14
  - 検証: 事前定義リストからの選択と自由入力の両方が`Memo.servingMachine`に反映されることをWidgetテストで確認する。
- [ ] T17: `ImpressionListEditor`を実装し、`MemoEditScreen`に組み込む（感想の箇条書き追加・編集・削除）。（REQ-6, Figma: 03_メモ作成編集 node-id 2:4）— 依存: T14
  - 検証: 追加・編集・削除の操作でリストの内容が期待通り変化することをWidgetテストで確認する。
- [ ] T18: `MemoEditScreen`に5軸評価（口当たり・素材の活かし方・個性的・フレーバーの良さ・温度管理、各1〜5）の入力UIを追加する。（REQ-7, Figma: 03_メモ作成編集 node-id 2:4）— 依存: T14
  - 検証: 各軸の入力操作が`Memo.tasteRating`の対応する値に反映されることをWidgetテストで確認する。

## presentation層（メモ一覧・地図）

- [ ] T19: `ListScreen`を実装し、日付・お店・サービングマシンを含む一覧表示を行う。（REQ-3, Figma: 01_メモ一覧_リスト node-id 2:2）— 依存: T12
  - 検証: フェイクの`memoListProvider`にテストデータを流し、一覧に日付・お店・サービングマシンが表示されることをWidgetテストで確認する。
- [ ] T20: `ServingMachineFilterBar`を実装し`ListScreen`に組み込む。（REQ-5）— 依存: T19
  - 検証: フィルタ選択操作で`servingMachineFilterProvider`の値が更新されることをWidgetテストで確認する。
- [ ] T21: `MapScreen`を実装し、位置情報を持つメモをピン表示する。（REQ-4, Figma: 02_メモ一覧_マップ node-id 2:3）— 依存: T12
  - 検証: `google_maps_flutter`をフェイクに差し替え、位置情報を持つメモの数だけマーカーが生成されること、位置情報が無いメモは除外されることをWidgetテストで確認する。
- [ ] T22: `ViewToggle`を実装し、`ListScreen`/`MapScreen`を切り替えられるようにする。（REQ-4）— 依存: T19, T21
  - 検証: トグル操作で`viewModeProvider`が切り替わり、表示されるWidgetが`ListScreen`/`MapScreen`間で切り替わることをWidgetテストで確認する。
- [ ] T23: `NotesTabScreen`として`ListScreen`/`MapScreen`/`ViewToggle`をまとめ、T2の「メモ一覧」ブランチに接続する。（REQ-8）— 依存: T22
  - 検証: T2で用意したナビゲーションのWidgetテストを拡張し、「メモ一覧」タブの中身が`NotesTabScreen`として表示されることを確認する。
- [ ] T24: フィルタ条件がリスト表示・マップ表示の両方に反映されることを確認する。（REQ-5）— 依存: T20, T23
  - 検証: フィルタ設定後、`ListScreen`と`MapScreen`の両方で同じ絞り込み結果になることをWidgetテストで確認する。
- [ ] T25: `TasteRadarChart`を`fl_chart`で実装する。5軸評価が未入力の場合は未評価プレースホルダーを表示する。（REQ-7）— 依存: T12
  - 検証: 5軸評価ありの場合はレーダーチャートが描画されること、未入力（全項目null）の場合はプレースホルダーが表示されることをWidgetテストで確認する。
- [ ] T26: `MemoDetailScreen`を実装し、感想リストの表示と`TasteRadarChart`の表示、`MemoEditScreen`への編集導線を提供する。メモ一覧からのタップで（モーダルではなく）タブ内スタックにpushする。（REQ-6, REQ-7, REQ-8, Figma: 04_メモ詳細 node-id 2:5）— 依存: T17, T18, T25, T23
  - 検証: 感想リスト・レーダーチャートが表示されること、編集ボタンから`MemoEditScreen`へ遷移すること、一覧からのタップがモーダルではなく通常pushであることをWidgetテストで確認する。

## presentation層（設定）

- [ ] T27: `SettingsScreen`を実装し、T2の「設定」ブランチに接続する。ニックネーム編集、アイコン選択・表示、アプリバージョン表示を行う。（REQ-9, Figma: 05_設定 node-id 2:6）— 依存: T13, T2
  - 検証: ニックネーム編集・アイコン選択（フェイクの`image_picker`）が`profileProvider`に反映されること、アプリバージョンが表示されることをWidgetテストで確認する。

## テスト（横断的な統合検証）

- [ ] T28: 個別タスクの単体テストではカバーしきれない、複数ユースケースにまたがるdomain層の統合的なテストを追加する（例: Exif欠損時のフォールバックと感想・5軸評価の保存を組み合わせたシナリオ、複数フィルタ条件の組み合わせなど）。— 依存: T10, T11
- [ ] T29: 主要フロー（写真取り込み→編集→一覧反映、リスト⇔マップ切替、感想・5軸評価の入力→詳細画面での表示、タブ切替とメモ作成モーダルの開閉、設定画面でのプロフィール編集）を一気通貫で検証する結合テストを追加する。個別タスクの検証はすべて完了している前提で、画面間の連携部分に絞る。— 依存: T24, T26, T27
