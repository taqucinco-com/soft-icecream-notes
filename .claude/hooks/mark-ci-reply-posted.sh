#!/usr/bin/env bash
# PostToolUse hook (matcher: Bash), CI-only (.claude/settings.ci.json).
# gh pr comment / gh issue comment が成功実行されたことを示すマーカーファイルを作る。
# require-ci-reply.sh (Stopフック) がこれを見て、返信投稿済みかどうかを判定する。
input="$(cat)"
success="$(printf '%s' "$input" | jq -r '.tool_response.success // false')"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

if [ "$success" = "true" ] && printf '%s' "$cmd" | grep -qE '^[[:space:]]*(gh pr comment|gh issue comment)([[:space:]]|$)'; then
  : > "/tmp/claude_ci_reply_posted_${GITHUB_RUN_ID:-local}"
fi
exit 0
