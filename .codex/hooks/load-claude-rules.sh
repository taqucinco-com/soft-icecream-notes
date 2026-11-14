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
  # CRLF を LF にそろえてから処理する（frontmatter の判定が崩れないようにする）
  tr -d '\r' < "$f" | awk '
    function add_path(s) {
      gsub(/^[ \t]+|[ \t]+$/, "", s)
      gsub(/^["\x27]|["\x27]$/, "", s)
      if (s != "") paths = paths (paths == "" ? "" : ", ") s
    }
    NR == 1 && $0 ~ /^---[ \t]*$/ { in_fm = 1; next }
    in_fm && $0 ~ /^---[ \t]*$/ { in_fm = 0; next }
    in_fm {
      if ($0 ~ /^paths:/) {
        in_paths = 1
        v = $0
        sub(/^paths:[ \t]*/, "", v)
        gsub(/^\[|\]$/, "", v)
        n = split(v, parts, ",")
        for (k = 1; k <= n; k++) add_path(parts[k])
      } else if (in_paths && $0 ~ /^[ \t]*-[ \t]+/) {
        v = $0
        sub(/^[ \t]*-[ \t]+/, "", v)
        add_path(v)
      } else if ($0 ~ /^[A-Za-z_-]+:/) {
        in_paths = 0
      }
      next
    }
    !printed {
      if (paths != "") { print "適用対象パス: " paths; print "" }
      printed = 1
    }
    { print }
  '
done
