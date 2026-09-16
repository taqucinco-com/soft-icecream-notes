#!/usr/bin/env bash
# Stop hook, CI-only (.claude/settings.ci.json).
# CLAUDE.mdのGitHub Actions応答ルール: ターンを終える前に必ずgh pr comment/gh issue
# commentで起動元コメントへの返信を投稿すること。mark-ci-reply-posted.sh (PostToolUse)
# が作るマーカーファイルが無ければ、まだ投稿されていないとみなして停止をブロックする。
marker="/tmp/claude_ci_reply_posted_${GITHUB_RUN_ID:-local}"

if [ ! -f "$marker" ]; then
  jq -n '{
    decision: "block",
    reason: "CLAUDE.mdのGitHub Actions応答ルールにより、ターンを終える前に必ずgh pr comment/gh issue commentで起動元コメントへの返信を投稿すること。まだそのコマンドの成功実行が確認できていません。投稿してから終了してください。"
  }'
fi
exit 0
