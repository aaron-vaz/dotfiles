#!/usr/bin/env python3
"""
Audit ~/.claude/tool-audit.log against current settings.json allow rules.
Outputs uncovered tool calls as suggested allow entries.

Usage:
    ~/.claude/scripts/audit-permissions.sh [--days N] [--min-count N]

Options:
    --days N        Only look at last N days of logs (default: 30)
    --min-count N   Only suggest patterns seen >= N times (default: 2)
"""

import json
import sys
import fnmatch
import re
from pathlib import Path
from collections import Counter
from datetime import datetime, timezone, timedelta

SETTINGS_PATH = Path.home() / ".claude/settings.json"
AUDIT_LOG = Path.home() / ".claude/tool-audit.log"

# --- Parse args ---
days = 30
min_count = 2
args = sys.argv[1:]
for i, arg in enumerate(args):
    if arg == "--days" and i + 1 < len(args):
        days = int(args[i + 1])
    elif arg == "--min-count" and i + 1 < len(args):
        min_count = int(args[i + 1])

cutoff = datetime.now(timezone.utc) - timedelta(days=days)

# --- Load current allow rules ---
with open(SETTINGS_PATH) as f:
    settings = json.load(f)

allow_entries = settings.get("permissions", {}).get("allow", [])

# Extract Bash glob patterns (e.g. "Bash(command:git log*)" -> "git log*")
bash_patterns = []
allowed_tools = set()
for entry in allow_entries:
    m = re.match(r'^Bash\(command:(.+)\)$', entry)
    if m:
        bash_patterns.append(m.group(1))
    else:
        # Bare tool name or Read/Write/Edit with path
        allowed_tools.add(entry)

def bash_covered(cmd):
    return any(fnmatch.fnmatch(cmd, p) for p in bash_patterns)

def tool_covered(name):
    # Exact match or wildcard match against allowed_tools
    return any(
        entry == name or fnmatch.fnmatch(name, entry)
        for entry in allowed_tools
    )

# --- Parse audit log ---
bash_cmds = []
tool_calls = []

if not AUDIT_LOG.exists():
    print(f"No audit log found at {AUDIT_LOG}")
    print("Make sure ~/.claude/hooks/log-tool-calls.sh is wired up in settings.json PostToolUse hooks.")
    sys.exit(1)

for line in AUDIT_LOG.read_text().splitlines():
    parts = line.split("\t", 2)
    if len(parts) < 3:
        continue
    ts_str, kind, value = parts
    try:
        ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
    except ValueError:
        continue
    if ts < cutoff:
        continue
    if kind == "Bash":
        bash_cmds.append(value.strip())
    elif kind == "Tool":
        tool_calls.append(value.strip())

# --- Analyse Bash commands ---
uncovered_bash: dict[str, dict] = {}
for cmd, count in Counter(bash_cmds).most_common():
    if not cmd or bash_covered(cmd):
        continue
    prefix = cmd.split()[0] if cmd.split() else cmd
    pattern = f"Bash(command:{prefix}*)"
    if pattern not in uncovered_bash:
        uncovered_bash[pattern] = {"count": 0, "examples": []}
    uncovered_bash[pattern]["count"] += count
    if len(uncovered_bash[pattern]["examples"]) < 3:
        uncovered_bash[pattern]["examples"].append(cmd[:100])

# --- Analyse other tool calls ---
uncovered_tools: Counter = Counter()
for t in tool_calls:
    if t and not tool_covered(t):
        uncovered_tools[t] += 1

# --- Report ---
print(f"\n{'='*60}")
print(f"Permission Audit — last {days} days  (min-count={min_count})")
print(f"{'='*60}")

bash_suggestions = {p: v for p, v in uncovered_bash.items() if v["count"] >= min_count}
tool_suggestions = {t: c for t, c in uncovered_tools.items() if c >= min_count}

if not bash_suggestions and not tool_suggestions:
    print("\nNo uncovered tool calls found! Your allow list looks comprehensive.")
    sys.exit(0)

if bash_suggestions:
    print(f"\n--- Uncovered Bash commands ({len(bash_suggestions)} patterns) ---")
    for pattern, info in sorted(bash_suggestions.items(), key=lambda x: -x[1]["count"]):
        print(f"\n  {info['count']}x  \"{pattern}\"")
        for ex in info["examples"]:
            print(f"       e.g. {ex}")

if tool_suggestions:
    print(f"\n--- Uncovered tool calls ({len(tool_suggestions)} tools) ---")
    for tool, count in tool_suggestions.most_common():
        print(f"\n  {count}x  \"{tool}\"")

print(f"\n{'='*60}")
print("To add suggestions, copy the quoted strings above into the")
print("\"permissions\": {{ \"allow\": [...] }} array in ~/.claude/settings.json")
print(f"{'='*60}\n")
