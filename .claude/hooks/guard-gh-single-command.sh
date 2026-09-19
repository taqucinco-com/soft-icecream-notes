#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash), CI-only (.claude/settings.ci.json).
# gh workflow run / gh pr comment / gh issue comment は、非対話CIセッションでは
# 単一の単純なコマンドとして実行しないと承認待ちのまま失敗する(Issue #56/#68の教訓)。
# 他コマンドとの連結(;, &&, ||, コマンド置換, バッククォート)を検出したら拒否する。
# 注意: 改行の有無では判定しない。`--body`/`-f original_request=`に埋め込む複数行の
# コメント本文は、単一引用符で1つの引数として渡す限り正当な使い方であり
# (android-emu-verify-dispatch/ios-sim-verify-dispatchスキルの既定パターン)、
# それを誤検知させないため。
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

if printf '%s' "$cmd" | grep -qE '(gh workflow run|gh pr comment|gh issue comment)'; then
  # コマンド中のどこかに対象コマンドがあり、かつどこかに複合演算子があれば違反とする。
  # 例: "gh pr comment ... && rm -rf" も "gh --version && gh pr comment ..." も両方拒否する。
  is_compound=0
  printf '%s' "$cmd" | grep -qE ';|&&|\|\||\$\(|`' && is_compound=1

  if [ "$is_compound" = "1" ]; then
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "非対話CIセッションでは gh workflow run / gh pr comment / gh issue comment を、他コマンドとの連結（;, &&, ||, コマンド置換, バッククォート）や複数行を使わない単一の単純なコマンドとして実行すること。事前の疎通確認や他コマンドとの連結は承認待ちのまま失敗する（Issue #56/#68の教訓、CLAUDE.md参照）。"
      }
    }'
  fi
fi
exit 0
