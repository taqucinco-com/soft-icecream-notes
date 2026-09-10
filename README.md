# soft-icecream-notes
食べたソフトクリームの写真からメモを作成するアプリ

## 初期設定

```sh
rbenv install
rbenv rehash
bundle install
```

## claude

claudeを活用した仕様駆動開発を行う

## 環境変数

`.env.sample`を参考に、リポジトリ直下に`.env.local`（gitignore対象）を作成する。

```
GOOGLE_MAP_KEY={Google Maps SDKのAPIキー}
```

`mobile/`アプリの起動・ビルドは`--dart-define-from-file`でこのファイルを読み込む。

```sh
cd mobile
# iOSの場合は事前にビルド
fvm flutter build ios --dart-define-from-file=.env.sample
fvm flutter run --dart-define-from-file=.env.local
```
