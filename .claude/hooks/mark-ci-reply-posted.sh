#!/usr/bin/env bash
# PostToolUse hook (matcher: Bash), CI-only (.claude/settings.ci.json).
# gh pr comment / gh issue comment が成功実行されたことを示すマーカーファイルを作る。
# require-ci-reply.sh (Stopフック) がこれを見て、返信投稿済みかどうかを判定する。
#
# マーカーは作業ディレクトリ配下（.ci-tmp/）に置く。サンドボックス化Bashツールの
# デフォルト書き込み許可対象は「作業ディレクトリ」と「セッション専用の$TMPDIR」のみで、
# 裸の/tmp直下は対象外のため、/tmp/...への書き込みはサンドボックスにブロックされ、
# require-ci-reply.shが永遠にマーカーを検出できず無限ブロックする不具合が実際に発生した
# (PR #82 issuecomment-5738741533/5738782798)。詳細は
# https://code.claude.com/docs/en/sandboxing の「Temporary directories」参照。
input="$(cat)"
success="$(printf '%s' "$input" | jq -r '.tool_response.success // false')"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

if [ "$success" = "true" ] && printf '%s' "$cmd" | grep -qE '^[[:space:]]*(gh pr comment|gh issue comment)([[:space:]]|$)'; then
  marker_dir="${CLAUDE_PROJECT_DIR:-.}/.ci-tmp"
  mkdir -p "$marker_dir"
  : > "$marker_dir/claude_ci_reply_posted_${GITHUB_RUN_ID:-local}"
fi
exit 0
