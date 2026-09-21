#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash), CI-only (.claude/settings.ci.json).
# gh workflow run / gh pr comment / gh issue comment は、非対話CIセッションでは
# 単一の単純なコマンドとして実行しないと承認待ちのまま失敗する(Issue #56/#68の教訓)。
# 他コマンドとの連結(;, &&, ||, コマンド置換, バッククォート)を検出したら拒否する。
# 注意: 改行の有無では判定しない。`--body`/`-f original_request=`に埋め込む複数行の
# コメント本文は、単一引用符で1つの引数として渡す限り正当な使い方であり
# (android-emu-verify-dispatch/ios-sim-verify-dispatchスキルの既定パターン)、
# それを誤検知させないため。
#
# 連結演算子の判定はシェルのクォート規則に従う。単一引用符の中はいかなる記号も
# シェルにとって特別な意味を持たないため、;/&/|/バッククォート/$(はすべて連結と
# みなさない。二重引用符の中では;/&/|は連結演算子として機能しないため連結と
# みなさないが、バッククォート/$(はコマンド置換として展開されるため引き続き
# 連結とみなす。これにより、投稿本文（クォートの中身）に記号や連結演算子を
# 説明する文章を含めても誤検知しない。
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

if printf '%s' "$cmd" | grep -qE '(gh workflow run|gh pr comment|gh issue comment)'; then
  # コマンド中のどこかに対象コマンドがあり、かつクォートの外（または連結演算子の
  # 種類によっては二重引用符の中）に連結演算子があれば違反とする。
  # 例: "gh pr comment ... && rm -rf" も "gh --version && gh pr comment ..." も両方拒否する。
  # バッククォート・単一引用符はawkスクリプト中に直接書くとシェル側のクォート解釈と
  # 衝突するため、文字コード経由(sprintf)で扱う。プログラムは-f -ではなく引数として
  # 渡す（-f -にすると標準入力がプログラム読み込みに使われ、パイプで渡す$cmdの方が
  # awkに届かなくなるため）。
  is_compound="$(printf '%s' "$cmd" | awk '
{
  in_single = 0
  in_double = 0
  sq = sprintf("%c", 39)
  dq = "\""
  bq = sprintf("%c", 96)
  n = length($0)
  for (i = 1; i <= n; i++) {
    c = substr($0, i, 1)
    if (c == "\\" && !in_single) { i++; continue }
    if (c == sq && !in_double) { in_single = !in_single; continue }
    if (c == dq && !in_single) { in_double = !in_double; continue }
    if (!in_single && !in_double && (c == ";" || c == "&" || c == "|")) { print 1; exit }
    if (!in_single && c == bq) { print 1; exit }
    if (!in_single && c == "$" && substr($0, i + 1, 1) == "(") { print 1; exit }
  }
  print 0
}
')"

  if [ "$is_compound" = "1" ]; then
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "非対話CIセッションでは gh workflow run / gh pr comment / gh issue comment を、他コマンドとの連結（;, &&, ||, コマンド置換, バッククォート）や複数行を使わない単一の単純なコマンドとして実行すること。事前の疎通確認や他コマンドとの連結は承認待ちのまま失敗する（Issue #56/#68の教訓、CLAUDE.md参照）。"
      }
    }'
    exit 0
  fi
fi

# 起動元コメントへの返信は1 job実行につき1回のみで良い。mark-ci-reply-posted.sh
# (PostToolUse) が作るマーカーが既にあれば、gh pr comment/gh issue commentの新規投稿
# （--edit-lastを除く）を二重投稿として拒否する。モデルが「途中経過」と「最終報告」を
# 別々に投稿しようとするケースも含め、投稿要否をモデルの自己判断に委ねず機械的に防ぐ。
marker="${CLAUDE_PROJECT_DIR:-.}/.ci-tmp/claude_ci_reply_posted_${GITHUB_RUN_ID:-local}"
if [ -f "$marker" ] \
  && printf '%s' "$cmd" | grep -qE '^[[:space:]]*(gh pr comment|gh issue comment)([[:space:]]|$)' \
  && ! printf '%s' "$cmd" | grep -q -- '--edit-last'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "起動元コメントへの返信はこのjob実行中に既に投稿済みです。二重投稿になるため新規投稿は不要です。内容を修正・追記したい場合はgh pr comment <番号> --edit-last --body \"...\"（issueならgh issue comment <番号> --edit-last --body \"...\"）で既存コメントを編集してください。"
    }
  }'
  exit 0
fi

exit 0
