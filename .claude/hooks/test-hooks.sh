#!/usr/bin/env bash
set -euo pipefail

# テスト用のテンポラリディレクトリを作成
TEST_DIR="$(mktemp -d)"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
export GITHUB_RUN_ID="test-run-123"

echo "=== Hooks Unit Test Suite ==="

# 1. mark-ci-reply-posted.sh のテスト
# PostToolUseはBashツールの呼び出しが成功した場合のみ発火するため、このフックへの
# 入力は常に実際のBashツールのtool_response形状（stdout/stderr/interrupted/isImage）
# を使う。https://code.claude.com/docs/en/hooks#posttooluse-input
echo "Testing mark-ci-reply-posted.sh..."
MARKER="$TEST_DIR/.ci-tmp/claude_ci_reply_posted_test-run-123"

# 対象コマンドでないケース
PAYLOAD_OTHER='{"tool_input": {"command": "gh pr view 1"}, "tool_response": {"stdout": "", "stderr": "", "interrupted": false, "isImage": false}}'
printf '%s' "$PAYLOAD_OTHER" | bash .claude/hooks/mark-ci-reply-posted.sh
if [ -f "$MARKER" ]; then
  echo "FAIL: Marker created for a non-comment command"
  exit 1
fi

# gh issue comment が実行されたケース (PostToolUse発火時点で成功が保証されている)
PAYLOAD_SUCC='{"tool_input": {"command": "gh issue comment 1 --body \"test\""}, "tool_response": {"stdout": "", "stderr": "", "interrupted": false, "isImage": false}}'
printf '%s' "$PAYLOAD_SUCC" | bash .claude/hooks/mark-ci-reply-posted.sh
if [ ! -f "$MARKER" ]; then
  echo "FAIL: Marker NOT created for gh issue comment"
  exit 1
fi
echo "PASS: mark-ci-reply-posted.sh"

# マーカーを一度削除して require-ci-reply.sh のテスト
rm -f "$MARKER"
rm -rf "$TEST_DIR/.ci-tmp"

# 2. require-ci-reply.sh のテスト (5回ブロックで強制突破するか)
echo "Testing require-ci-reply.sh circuit breaker..."
COUNTER_FILE="$TEST_DIR/.ci-tmp/claude_ci_reply_retry_count_test-run-123"

for i in {1..9}; do
  OUTPUT="$(bash .claude/hooks/require-ci-reply.sh || true)"
  if ! echo "$OUTPUT" | grep -q "decision"; then
    echo "FAIL: Expected block decision on attempt $i, got: $OUTPUT"
    exit 1
  fi
done

# 10回目は強制突破して exit 0 になるべき
OUTPUT_10="$(bash .claude/hooks/require-ci-reply.sh || true)"
if echo "$OUTPUT_10" | grep -q "decision"; then
  echo "FAIL: Expected circuit breaker to pass on attempt 10, got: $OUTPUT_10"
  exit 1
fi
echo "PASS: require-ci-reply.sh circuit breaker"

# 3. CLAUDE_CI_FORCE_EXIT のテスト
echo "Testing CLAUDE_CI_FORCE_EXIT..."
rm -rf "$TEST_DIR/.ci-tmp"
export CLAUDE_CI_FORCE_EXIT="true"
OUTPUT_FORCE="$(bash .claude/hooks/require-ci-reply.sh || true)"
if echo "$OUTPUT_FORCE" | grep -q "decision"; then
  echo "FAIL: Expected CLAUDE_CI_FORCE_EXIT to pass immediately, got: $OUTPUT_FORCE"
  exit 1
fi
echo "PASS: CLAUDE_CI_FORCE_EXIT"

# 4. guard-gh-single-command.sh のテスト
# 連結演算子の判定はシェルのクォート規則に従う。;/&/|は単一引用符・二重引用符の
# どちらの中でも連結として機能しないため、投稿本文中にこれらの記号を含めても
# 誤検知してはならない。バッククォート/$()は二重引用符の中でもコマンド置換として
# 展開されるため、二重引用符の中・クォート外では引き続き検出する。
echo "Testing guard-gh-single-command.sh..."

assert_guard_allowed() {
  local desc="$1" cmd="$2"
  local payload out
  payload="$(jq -n --arg c "$cmd" '{tool_input: {command: $c}}')"
  out="$(printf '%s' "$payload" | bash .claude/hooks/guard-gh-single-command.sh)"
  if printf '%s' "$out" | grep -q "permissionDecision"; then
    echo "FAIL: expected ALLOWED but got BLOCKED: $desc"
    exit 1
  fi
}

assert_guard_blocked() {
  local desc="$1" cmd="$2"
  local payload out
  payload="$(jq -n --arg c "$cmd" '{tool_input: {command: $c}}')"
  out="$(printf '%s' "$payload" | bash .claude/hooks/guard-gh-single-command.sh)"
  if ! printf '%s' "$out" | grep -q "permissionDecision"; then
    echo "FAIL: expected BLOCKED but got ALLOWED: $desc"
    exit 1
  fi
}

assert_guard_allowed "単一引用符内の記号(;,&&,||,バッククォート)は連結とみなさない" \
  "gh issue comment 111 --body 'セミコロン ; アンパサンド && パイプ || バッククォート \` について説明する文章'"

assert_guard_allowed "二重引用符内の;/&/|は連結とみなさない" \
  'gh issue comment 111 --body "セミコロン ; アンパサンド 一つ & パイプ | について説明する文章"'

assert_guard_blocked "クォート外の&&は連結とみなす" \
  "gh issue comment 111 --body 'ok' && rm -rf /"

assert_guard_blocked "クォート外の;は連結とみなす" \
  "gh pr comment 1 --body 'ok'; echo pwned"

assert_guard_blocked "二重引用符内の\$()はコマンド置換として連結とみなす" \
  'gh issue comment 111 --body "danger $(whoami)"'

assert_guard_blocked "二重引用符内のバッククォートはコマンド置換として連結とみなす" \
  'gh issue comment 111 --body "danger `whoami`"'

assert_guard_allowed "対象コマンド(gh pr/issue comment等)でなければ判定しない" \
  "echo hello && rm -rf /tmp/x"

echo "PASS: guard-gh-single-command.sh"

# クリーンアップ
rm -rf "$TEST_DIR"
echo "=== All Hook Tests Passed Successfully! ==="
