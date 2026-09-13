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

`mobile/.env.sample`を参考に、`mobile/`直下に`.env.local`（gitignore対象）を作成する。

```
GOOGLE_MAP_KEY_ANDROID={Google Maps SDKのAPIキー（Android用）}
GOOGLE_MAP_KEY_IOS={Google Maps SDKのAPIキー（iOS用）}
```

プラットフォームごとに別のキーを使う。

| キー | 読む場所 |
|---|---|
| `GOOGLE_MAP_KEY_ANDROID` | `mobile/android/app/build.gradle.kts`が`manifestPlaceholders`経由でAndroidManifest.xmlに注入 |
| `GOOGLE_MAP_KEY_IOS` | `mobile/ios/Runner/AppDelegate.swift`がInfo.plistの`DartDefines`経由で取得 |

いずれもビルド時に値が埋め込まれるため、キーを変えたらビルドし直す必要がある。

`mobile/`アプリの起動・ビルドは`--dart-define-from-file`でこのファイルを読み込む。

```sh
cd mobile
# iOSの場合は事前にビルド
fvm flutter build ios --dart-define-from-file=.env.local
fvm flutter run --dart-define-from-file=.env.local
```

# AI agentが直接iOS Simulatorと対話する

```sh
brew trust facebook/fb
brew install facebook/fb/idb
brew install facebook/fb/idb-companion
pip3 install fb-idb
# 事前にどれかのSimulatorを立ち上げておく
idb list-targets
# bootedになっているUDIDを記録
idb connect EC48ECD5-ED72-4650-AC8C-5443A278D0BC
# e.g. 任意の場所をタップ => https://fbidb.io/docs/idb/commands
idb ui tap 20 200 
# simctlと組み合わせることで現状の状態をスクリーンキャプチャで取得できる
xcrun simctl io EC48ECD5-ED72-4650-AC8C-5443A278D0BC screenshot screenshot.png
```

なお`idb ui`が扱う座標はポイント（例: iPhone 17なら402x874）で、`simctl`が撮るスクリーンショットのピクセル（同1206x2622）とは3倍ずれる。画像を見て座標を決める場合は換算が必要。

Claudeに検証させる場合は`flutter-ui-ios-verify`スキル（`.claude/skills/flutter-ui-ios-verify/SKILL.md`）を使う。

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

# 実行するシミュレータのUDIDを控える（Booted のものを使う）
xcrun simctl list devices booted
# 起動していなければ Simulator.app を開くか、maestroに作らせる
# 指定できるモデル名・OS名は `maestro list-devices` で確認できる
maestro start-device --platform ios --device-model iPhone-17 --device-os iOS-26-5

# maestroはビルドをせず、インストール済みのアプリをappIdで起動するだけなので、
# 先にシミュレータ向けにビルドしてインストールしておく
cd mobile
fvm flutter build ios --simulator --dart-define-from-file=.env.local
xcrun simctl install {UDID} build/ios/iphonesimulator/Runner.app
cd ..

# maestro cli
maestro test ./mobile/test/e2e/maestro/page_transfar.yaml --udid={UDID}
```

`idb connect`に相当する接続コマンドはmaestroには無い（`maestro --help`のコマンド一覧にも存在しない）。
maestroは自分でデバイスを探すので、**シミュレータが起動していて、アプリがインストール済み**でありさえすればよい。
`--udid`に渡すのはその起動済みシミュレータのUDID。

https://github.com/user-attachments/assets/158512b7-e83d-43e3-a109-ac28ab2ea8d0

# AWS

## secret登録

```sh
aws secretsmanager create-secret \   
    --name "taqucinco-com/soft-icecream-notes/secrets" \   
    --description "taqucinco-com/soft-icecream-notesのsecret" \
    --secret-string '{"username":"admin","password":"Password123!"}'
```

## secret取得

```sh
aws secretsmanager get-secret-value \
    --secret-id "taqucinco-com/soft-icecream-notes/secrets"
```

## parameter登録

```sh
aws ssm put-parameter \
    --name "/taqucinco-com/soft-icecream-notes/example" \
    --description "taqucinco-com/soft-icecream-notesのparameter" \
    --value "Password123!" \
    --type "SecureString"
```

## parameter取得

```sh
aws ssm get-parameter \
    --name "/taqucinco-com/soft-icecream-notes/example" \
    --with-decryption
```

## ロールへのポリシーのアタッチ

GitHub Actions用のIAMロール（`github-taqucinco-com-soft-icecream-notes-oidc`）に、Secrets ManagerやParameter Storeを読むための権限を付与する方法。

### 既存のポリシー（マネージドポリシー）をアタッチする場合

AWSが用意しているマネージドポリシーをそのままアタッチする方法。手軽だが権限の範囲が広くなりがち（例えばSecrets Manager内の全シークレットを読めてしまう）。

```sh
aws iam attach-role-policy \
    --role-name github-taqucinco-com-soft-icecream-notes-oidc \
    --policy-arn arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess
```

### インラインポリシーをアタッチする場合

特定のリソース（今回のparameter 1件）だけに絞った最小権限のポリシーをその場で作成してアタッチする方法。Parameter StoreのSecureStringは、値の復号に`ssm:GetParameter`だけでなく暗号化に使われたKMSキーへの`kms:Decrypt`権限も必要になる点に注意。`<KMS_KEY_ID>`は次のコマンドで調べられる（SecureStringを作成時にKMSキーを指定していなければ、デフォルトでAWS管理キー`alias/aws/ssm`が使われる）。

```sh
aws kms describe-key --key-id "alias/aws/ssm" --query "KeyMetadata.KeyId" --output text
```

```sh
cat > ssm-read-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:ap-northeast-1:<AWS_ACCOUNT_ID>:parameter/taqucinco-com/soft-icecream-notes/example"
        },
        {
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "arn:aws:kms:ap-northeast-1:<AWS_ACCOUNT_ID>:key/<KMS_KEY_ID>"
        }
    ]
}
EOF

aws iam put-role-policy \
    --role-name github-taqucinco-com-soft-icecream-notes-oidc \
    --policy-name SSMParameterStoreReadExample \
    --policy-document file://ssm-read-policy.json
```

反映されたインラインポリシーの確認:

```sh
aws iam get-role-policy \
    --role-name github-taqucinco-com-soft-icecream-notes-oidc \
    --policy-name SSMParameterStoreReadExample
```

## AWS OIDCの設定確認

GitHub Actionsからのディスパッチの履歴をAdministrator Accessで確認できる。

```
aws cloudtrail lookup-events \
  --profile Administrator \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --start-time "2026-09-12T11:44:00Z" \
  --end-time "2026-09-12T11:49:00Z" \
  --region ap-northeast-1

```
