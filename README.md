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

# AI agentが直接iOS Simulatorと対話する

```sh
brew trust facebook/fb
brew install facebook/fb/idb
brew install facebook/fb/idb-companion
pip3 install fb-idb
# 事前にどれかのSimulatorを立ち上げておく
idb list-targests
# bootedになっているUDIDを記録
idb connect EC48ECD5-ED72-4650-AC8C-5443A278D0BC
# e.g. 任意の場所をタップ => https://fbidb.io/docs/idb/commands
idb ui tap 20 200 
# simctlと組み合わせることで現状の状態をスクリーンキャプチャで取得できる
xcrun simctl screenshot screenshot.png
```

# E2E

Maestro

```sh
# maestro cli
brew tap mobile-dev-inc/tap
brew trust --formula mobile-dev-inc/tap/maestro
brew install mobile-dev-inc/tap/maestro
## 以下のように表示される場合はlinkする
## To link this version, run:
##  brew link mobile-dev-inc/tap/maestro

# maestro studio
# https://docs.maestro.dev/get-started/quickstart#ios にある通りdmgをダウンロード
maestro studio

# maestro cli
maestro test ./mobile/test/e2e/maestro/page_transfar.yaml --udid={UDID}
```

https://github.com/user-attachments/assets/158512b7-e83d-43e3-a109-ac28ab2ea8d0
