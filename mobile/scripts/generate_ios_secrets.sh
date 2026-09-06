#!/bin/bash
set -euo pipefail

# リポジトリ直下の.env.local（--dart-define-from-fileで使うのと同じファイル）から
# ios/Flutter/Secrets.xcconfig を生成する。
#
# Androidはbuild.gradle.ktsがFlutter Gradle Pluginの"dart-defines"プロパティ経由で
# dart-defineの値をmanifestPlaceholdersへ直接取り込めるが、iOSのXcodeビルドには
# 個々のdart-defineをxcconfig変数として展開する仕組みが無いため、
# ビルド前にこのスクリプトを実行してSecrets.xcconfigを用意する必要がある。
#
# 使い方: mobile/scripts/generate_ios_secrets.sh [.env.localのパス]
# （省略時はリポジトリ直下の.env.localを使う）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${1:-$MOBILE_DIR/../.env.local}"
OUTPUT_FILE="$MOBILE_DIR/ios/Flutter/Secrets.xcconfig"

if [ ! -f "$ENV_FILE" ]; then
  echo "エラー: $ENV_FILE が見つかりません。.env.sampleを参考に作成してください。" >&2
  exit 1
fi

{
  echo "// このファイルは scripts/generate_ios_secrets.sh により自動生成されます。手動編集しないでください。"
  grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$' | while IFS='=' read -r key value; do
    echo "$key = $value"
  done
} > "$OUTPUT_FILE"

echo "✅ $OUTPUT_FILE を生成しました。"
