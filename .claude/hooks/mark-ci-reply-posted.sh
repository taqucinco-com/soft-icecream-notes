#!/usr/bin/env bash
# PostToolUse hook (matcher: Bash), CI-only (.claude/settings.ci.json).
# gh pr comment / gh issue comment が成功実行されたことを示すマーカーファイルを作る。
# require-ci-reply.sh (Stopフック) がこれを見て、返信投稿済みかどうかを判定する。
#
# マーカーは作業ディレクトリ配下（.ci-tmp/）に置く。Bashツールのサンドボックスは
# 作業ディレクトリとセッション専用の$TMPDIRにのみ書き込みを許可する仕様のため。
input="$(cat)"
exit_code="$(printf '%s' "$input" | jq -r '.tool_response.exit_code // 1')"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

if [ "$exit_code" = "0" ] && printf '%s' "$cmd" | grep -qE '^[[:space:]]*(gh pr comment|gh issue comment)([[:space:]]|$)'; then
  marker_dir="${CLAUDE_PROJECT_DIR:-.}/.ci-tmp"
  mkdir -p "$marker_dir"
  : > "$marker_dir/claude_ci_reply_posted_${GITHUB_RUN_ID:-local}"
fi
exit 0
