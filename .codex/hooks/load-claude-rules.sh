#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
rules_dir="$root/.claude/rules"

[ -d "$rules_dir" ] || exit 0

files=()
while IFS= read -r f; do
  files+=("$f")
done < <(find "$rules_dir" -type f -name '*.md' | LC_ALL=C sort)

[ "${#files[@]}" -gt 0 ] || exit 0

echo "以下は .claude/rules/ のルールです。AGENTS.md に追加された指示として従ってください。"
echo "「適用対象パス」が付いたルールは、そのパスに一致するファイルを扱うときだけ適用してください。"

for f in "${files[@]}"; do
  rel="${f#"$root"/}"
  echo
  echo "## $rel"
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { in_fm = 0; next }
    in_fm { fm = fm $0 "\n"; next }
    !printed { if (fm ~ /(^|\n)paths:/) { gsub(/\n/, " ", fm); sub(/^paths: */, "", fm); print "適用対象パス: " fm; print "" } printed = 1 }
    { print }
  ' "$f"
done
