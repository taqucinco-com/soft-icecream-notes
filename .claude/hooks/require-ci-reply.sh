#!/usr/bin/env bash
# Stop hook, CI-only (.claude/settings.ci.json).
# CLAUDE.mdのGitHub Actions応答ルール: ターンを終える前に必ずgh pr comment/gh issue
# commentで起動元コメントへの返信を投稿すること。mark-ci-reply-posted.sh (PostToolUse)
# が作るマーカーファイルが無ければ、まだ投稿されていないとみなして停止をブロックする。
#
# マーカーのパスは作業ディレクトリ配下（.ci-tmp/）。Bashツールのサンドボックスは
# 作業ディレクトリとセッション専用の$TMPDIRにのみ書き込みを許可する仕様のため。
#
# CLAUDE_CI_INTERNAL_STEP=true または CLAUDE_CI_FORCE_EXIT=true の場合はこのチェックをスキップする。
if [ "${CLAUDE_CI_INTERNAL_STEP:-false}" = "true" ] || [ "${CLAUDE_CI_FORCE_EXIT:-false}" = "true" ]; then
  exit 0
fi

marker="${CLAUDE_PROJECT_DIR:-.}/.ci-tmp/claude_ci_reply_posted_${GITHUB_RUN_ID:-local}"
counter_file="${CLAUDE_PROJECT_DIR:-.}/.ci-tmp/claude_ci_reply_retry_count_${GITHUB_RUN_ID:-local}"

if [ ! -f "$marker" ]; then
  # 試行回数（ブロック回数）をカウントし、10回以上の場合は無限ループを防ぐために強制突破させる
  mkdir -p "$(dirname "$counter_file")"
  count=0
  if [ -f "$counter_file" ]; then
    count="$(cat "$counter_file" 2>/dev/null || echo 0)"
  fi
  count=$((count + 1))
  echo "$count" > "$counter_file"

  if [ "$count" -ge 10 ]; then
    # 10回以上ブロックされた場合は無限ループ防止のため強制的に通過させる
    exit 0
  fi

  jq -n '{
    decision: "block",
    reason: "CLAUDE.mdのGitHub Actions応答ルールにより、ターンを終える前に必ずgh pr comment/gh issue commentで起動元コメントへの返信を投稿すること。まだそのコマンドの成功実行が確認できていません。投稿してから終了してください。"
  }'
fi
exit 0
