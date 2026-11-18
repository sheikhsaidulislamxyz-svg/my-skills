#!/usr/bin/env bash
# my-skills hook: run `dart format` on any .dart file written/edited by the agent.
# Wire it into settings.json as a PostToolUse hook (see hooks/README.md).
# Exit 0 = nothing to do / formatted ok. Exit 1 = formatting failed (agent sees the error).
set -uo pipefail

FILE="${1:-}"

if [ -z "$FILE" ]; then
  # Claude Code passes hook input as JSON on stdin: {"tool_input": {"file_path": "..."}}
  INPUT="$(cat 2>/dev/null || true)"
  if command -v node >/dev/null 2>&1; then
    FILE="$(printf '%s' "$INPUT" | node -e 'try{const j=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write((j.tool_input&&j.tool_input.file_path)||"")}catch(e){process.stdout.write("")}' 2>/dev/null)"
  fi
  if [ -z "$FILE" ]; then
    # bash fallback: first "file_path": "..." occurrence
    FILE="$(printf '%s' "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n1 | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  fi
fi

# Only dart files, only existing files
case "$FILE" in
  *.dart) ;;
  *) exit 0 ;;
esac
if [ ! -f "$FILE" ]; then
  exit 0
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "my-skills/dart-format: 'dart' not found on PATH — skipping format for $FILE" >&2
  exit 0
fi

if dart format "$FILE" >/dev/null 2>&1; then
  echo "my-skills/dart-format: formatted $FILE"
  exit 0
else
  echo "my-skills/dart-format: FAILED to format $FILE" >&2
  dart format "$FILE" >&2
  exit 1
fi
