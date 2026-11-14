#!/usr/bin/env python3
"""`.claude/agents/<name>.md` から `.codex/agents/<name>.toml` を生成する。

使い方:
  python3 -I .codex/scripts/sync-agents.py          生成して書き込む
  python3 -I .codex/scripts/sync-agents.py --check  差分があれば終了コード1で終わる（書き込まない）
"""
import json
import re
import subprocess
import sys
from pathlib import Path

READ_ONLY_TOOLS = {"Read", "Grep", "Glob"}

READ_ONLY_NOTICE = """## 使用できる操作の制限

このエージェントが使ってよい操作は、ファイルの読み取りと検索（`Read`・`Grep`・`Glob`相当）のみ。ファイルの編集・作成・削除、コマンドの実行、外部サービスへの書き込みは行わない。"""


def parse(md: str) -> tuple[dict, str]:
    m = re.match(r"---\n(.*?)\n---\n(.*)\Z", md, re.S)
    if not m:
        raise ValueError("frontmatterがありません")
    meta = {}
    for line in m.group(1).split("\n"):
        key, _, value = line.partition(":")
        meta[key.strip()] = value.strip()
    return meta, m.group(2).strip("\n")


def toml_multiline(body: str) -> str:
    if "'''" not in body:
        return f"'''\n{body}\n'''"
    escaped = body.replace("\\", "\\\\").replace('"""', '\\"\\"\\"')
    return f'"""\n{escaped}\n"""'


def convert(md: str) -> str:
    meta, body = parse(md)
    tools = {t.strip() for t in meta.get("tools", "").split(",") if t.strip()}
    if tools and tools <= READ_ONLY_TOOLS:
        body = f"{body}\n\n{READ_ONLY_NOTICE}"
    return (
        f"name = {json.dumps(meta['name'], ensure_ascii=False)}\n"
        f"description = {json.dumps(meta['description'], ensure_ascii=False)}\n"
        f"developer_instructions = {toml_multiline(body)}\n"
    )


def main() -> int:
    check = "--check" in sys.argv[1:]
    root = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
        ).stdout.strip()
    )
    src_dir = root / ".claude" / "agents"
    dst_dir = root / ".codex" / "agents"
    dst_dir.mkdir(parents=True, exist_ok=True)

    expected = {}
    for src in sorted(src_dir.glob("*.md")):
        meta, _ = parse(src.read_text())
        expected[f"{meta['name']}.toml"] = convert(src.read_text())

    problems = []
    for name, content in expected.items():
        dst = dst_dir / name
        if not dst.exists() or dst.read_text() != content:
            problems.append(f"差分あり: .codex/agents/{name}")
            if not check:
                dst.write_text(content)
    for dst in sorted(dst_dir.glob("*.toml")):
        if dst.name not in expected:
            problems.append(f"対応する.claude/agents/が無い: .codex/agents/{dst.name}")

    for p in problems:
        print(p)
    if check and problems:
        print("`python3 -I .codex/scripts/sync-agents.py` で再生成してください。")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
