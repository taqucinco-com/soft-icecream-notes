#!/usr/bin/env bash
# PostToolUse hook (matcher: Bash), CI-only (.claude/settings.ci.json).
# gh pr comment / gh issue comment が成功実行されたことを示すマーカーファイルを作る。
# require-ci-reply.sh (Stopフック) がこれを見て、返信投稿済みかどうかを判定する。
#
# マーカーは作業ディレクトリ配下（.ci-tmp/）に置く。Bashツールのサンドボックスは
# 作業ディレクトリとセッション専用の$TMPDIRにのみ書き込みを許可する仕様のため。
#
# PostToolUseはBashツールの呼び出しが成功した場合にのみ発火し、失敗時は
# PostToolUseFailureが発火してこのフックは実行されない。そのためコマンドの
# 終了コードをこのフック側で改めて検証する必要はない（tool_responseは
# stdout/stderr/interrupted/isImageのみを持ち、終了コードそのものを表す
# フィールドは存在しない）。
# https://code.claude.com/docs/en/hooks#posttooluse-input
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

if printf '%s' "$cmd" | grep -qE '^[[:space:]]*(gh pr comment|gh issue comment)([[:space:]]|$)'; then
  marker_dir="${CLAUDE_PROJECT_DIR:-.}/.ci-tmp"
  mkdir -p "$marker_dir"
  : > "$marker_dir/claude_ci_reply_posted_${GITHUB_RUN_ID:-local}"
fi
exit 0
