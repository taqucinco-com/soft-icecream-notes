#!/usr/bin/env bash
# PreToolUse hook (matcher: Task|Agent), CI-only (.claude/settings.ci.json).
# CLAUDE.mdのGitHub Actions応答ルール: 非対話CIセッションではsubagent呼び出しは
# 必ず同期的(run_in_background: false)に行うこと。非同期呼び出しは後続ターンが
# 無いCIでは完了通知を受け取れず、判定結果を使えないままターンが終わる。
input="$(cat)"
run_in_bg="$(printf '%s' "$input" | jq -r '.tool_input.run_in_background // false')"

if [ "$run_in_bg" = "true" ]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "CI（非対話）セッションではsubagentの呼び出しは同期的（run_in_background: false）に行うこと。非対話ターンには後続ターンが無く、非同期呼び出しの完了通知を受け取れないため判定結果を使えないままターンが終わる（CLAUDE.mdのGitHub Actions応答ルール参照。実際にこの事故が発生している）。"
    }
  }'
fi
exit 0
