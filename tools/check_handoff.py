#!/usr/bin/env python3
"""Check the durable project handoff entry points; no chat collection or file mutation."""
from pathlib import Path
import argparse
import re
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
required = [
    "AGENTS.md",
    "docs/PROJECT_SETTINGS.md",
    "STATUS.md",
    "docs/NEXT_SESSION.md",
    "docs/MULTI_AGENT_DEVELOPMENT.md",
    "docs/contracts/README.md",
    "docs/agents/GAME_DESIGNER.md",
    "docs/WORK_PROMPT.md",
]
failures = []
for name in required:
    path = root / name
    if not path.is_file() or len(path.read_text(encoding="utf-8").strip()) < 100:
        failures.append(f"Missing or empty handoff document: {name}")
agents = (root / "AGENTS.md").read_text(encoding="utf-8")
for name in required[1:4]:
    if name not in agents:
        failures.append(f"AGENTS.md must link {name}")
for name in ["docs/MULTI_AGENT_DEVELOPMENT.md", "docs/agents/GAME_DESIGNER.md", "docs/WORK_PROMPT.md"]:
    if name not in agents:
        failures.append(f"AGENTS.md must link {name}")
next_session = (root / "docs/NEXT_SESSION.md").read_text(encoding="utf-8")
if "PROJECT_SETTINGS.md" not in next_session:
    failures.append("NEXT_SESSION must identify PROJECT_SETTINGS.md as the current settings source")
if "PROJECT_SETTINGS.md" not in (root / "README.md").read_text(encoding="utf-8"):
    failures.append("README must expose the settings entry point")
# Only staged implementation changes are checked, preserving unrelated local files.
parser = argparse.ArgumentParser()
parser.add_argument("--base", default="", help="Optional previous commit for CI; default checks staged changes")
args = parser.parse_args()
command = ["git", "diff", "--cached", "--name-only"]
if args.base and args.base != "0" * 40:
    if not re.fullmatch(r"[0-9a-f]{40}", args.base):
        parser.error("base must be a full commit SHA")
    command = ["git", "diff", "--name-only", args.base, "HEAD"]
staged = subprocess.run(command, cwd=root,
                        capture_output=True, text=True, check=True).stdout.splitlines()
product = [p for p in staged if p.endswith((".gd", ".tscn")) and not p.startswith("tools/")]
if product:
    for name in ["STATUS.md", "docs/NEXT_SESSION.md"]:
        if name not in staged:
            failures.append(f"Stage {name} together with implementation changes")
for failure in failures:
    print("HANDOFF FAIL: " + failure)
if not failures:
    print("HANDOFF PASS: settings/status/next-session entry points and staged implementation handoff")
sys.exit(1 if failures else 0)
