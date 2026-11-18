#!/usr/bin/env bash
# my-skills installer.
# Copies skills/ and agents/ into your user-level Claude config, merges the
# Flutter/Firebase rules into your CLAUDE.md (without overwriting), installs the
# MCP servers with --scope user, then runs `claude mcp list`.
#
# Safety:
#   * Anything already present with the same name is moved to
#     "$CLAUDE_HOME/backups/my-skills-<timestamp>/" before being replaced.
#   * CLAUDE.md is MERGED: a clearly-marked block is inserted/updated, the rest of
#     your file is preserved byte-for-byte.
#   * If any step fails, the script stops immediately and prints the error.
#   * MY_SKILLS_TEST=1 (or --skip-remote) skips all network/npx/claude steps so the
#     script can be tested hermetically (no network, nothing outside $CLAUDE_HOME).
#
# Env:    CLAUDE_HOME     — user-level Claude config dir (default: ~/.claude)
#         MY_SKILLS_TEST  — 1 = test mode (skip remote steps)
# Flags:  --skip-remote   — skip npx/claude steps
#         --help          — show this header
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CLAUDE_HOME/backups/my-skills-$STAMP"
TEST_MODE="${MY_SKILLS_TEST:-0}"
SKIP_REMOTE=0
for arg in "$@"; do
  case "$arg" in
    --skip-remote) SKIP_REMOTE=1 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install.sh: unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done
if [ "$TEST_MODE" = "1" ]; then SKIP_REMOTE=1; fi

note() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

BACKUP_USED=0
backup_path() { # $1 = existing path to preserve
  mkdir -p "$BACKUP_DIR"
  local dest="$BACKUP_DIR/$(basename "$1")" i=1
  while [ -e "$dest" ]; do dest="$BACKUP_DIR/$(basename "$1").$i"; i=$((i+1)); done
  mv "$1" "$dest"
  BACKUP_USED=1
  ok "backed up $(basename "$1") -> $dest"
}

COPIED_COUNT=0
copy_tree() { # $1 = source dir, $2 = target dir, $3 = label (handles files AND dirs)
  local src="$1" dst="$2" label="$3" item name
  mkdir -p "$dst"
  COPIED_COUNT=0
  for item in "$src"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    if [ -e "$dst/$name" ] || [ -L "$dst/$name" ]; then
      backup_path "$dst/$name"
    fi
    cp -r "$item" "$dst/$name"
    ok "$label/$name"
    COPIED_COUNT=$((COPIED_COUNT+1))
  done
}

# MCP server definitions — keep in sync with mcp/servers.json (a consistency
# check runs below when node is available). Arguments are word-split intentionally.
# name|scope|command|args
SERVER_LINES=(
  'playwright|user|npx|-y @playwright/mcp@latest'
  'context7|user|npx|-y @upstash/context7-mcp@latest'
  'sequential-thinking|user|npx|-y @modelcontextprotocol/server-sequential-thinking@latest'
  'firebase|user|npx|-y firebase-tools@latest mcp'
  'dart|user|dart|mcp-server'
)

# Verify mcp/servers.json parses and covers exactly the servers above (warning only).
check_servers_json_sync() {
  command -v node >/dev/null 2>&1 || return 0
  node -e '
    const fs=require("fs");
    const expected=["playwright","context7","sequential-thinking","firebase","dart"].sort();
    try {
      const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
      const actual=j.servers.map(s=>s.name).sort();
      if (JSON.stringify(actual)!==JSON.stringify(expected))
        { console.error("servers.json names "+JSON.stringify(actual)+" != expected "+JSON.stringify(expected)); process.exit(1); }
    } catch(e) { console.error("servers.json unusable: "+e.message); process.exit(1); }
  ' "$REPO_ROOT/mcp/servers.json" || warn "mcp/servers.json does not match the built-in server list — update both (see README)."
}

mcp_command_for() { # $1 = server line -> prints the claude command (for display/manual use)
  local line="$1"
  local name scope cmd args
  name="${line%%|*}"; line="${line#*|}"
  scope="${line%%|*}"; line="${line#*|}"
  cmd="${line%%|*}";   args="${line#*|}"
  printf 'claude mcp add --scope %s %s %s -- %s' "$scope" "$name" "$cmd" "$args"
}

note "my-skills installer"
echo "repo:         $REPO_ROOT"
echo "claude home:  $CLAUDE_HOME"
echo "test mode:    $TEST_MODE"

# --- 1. skills -----------------------------------------------------------------
note "skills -> $CLAUDE_HOME/skills/"
mkdir -p "$CLAUDE_HOME"
copy_tree "$REPO_ROOT/skills" "$CLAUDE_HOME/skills" "skill"
SKILLS_COUNT=$COPIED_COUNT

# --- 2. agents -----------------------------------------------------------------
note "agents -> $CLAUDE_HOME/agents/"
copy_tree "$REPO_ROOT/agents" "$CLAUDE_HOME/agents" "agent"
AGENTS_COUNT=$COPIED_COUNT

# --- 3. merge CLAUDE.md ---------------------------------------------------------
note "merging Flutter/Firebase rules into $CLAUDE_HOME/CLAUDE.md"
BEGIN_MARK='<!-- >>> my-skills managed block (Flutter/Firebase) >>> -->'
END_MARK='<!-- <<< my-skills managed block <<< -->'
TARGET_CLAUDE="$CLAUDE_HOME/CLAUDE.md"
BLOCK_TMP="$(mktemp)"
{
  echo "$BEGIN_MARK"
  cat "$REPO_ROOT/templates/CLAUDE.md"
  echo "$END_MARK"
} > "$BLOCK_TMP"

if [ -f "$TARGET_CLAUDE" ]; then
  backup_path "$TARGET_CLAUDE"
  OLD_CLAUDE="$BACKUP_DIR/CLAUDE.md"
  MERGED_TMP="$(mktemp)"
  # Drop any previous my-skills block (markers are single dedicated lines),
  # keep everything else byte-for-byte.
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0 == b { skip=1; next }
    $0 == e { skip=0; next }
    skip != 1 { print }
  ' "$OLD_CLAUDE" > "$MERGED_TMP"
  # Ensure separation, then append the fresh block
  [ -s "$MERGED_TMP" ] && printf '\n' >> "$MERGED_TMP"
  cat "$BLOCK_TMP" >> "$MERGED_TMP"
  mv "$MERGED_TMP" "$TARGET_CLAUDE"
  ok "merged (existing rules preserved; old file in backup)"
else
  cp "$BLOCK_TMP" "$TARGET_CLAUDE"
  ok "created $TARGET_CLAUDE"
fi
rm -f "$BLOCK_TMP"

# --- 4. remote skills via npx (no license file upstream — never copied) ---------
# A failure in one remote skill does NOT abort the others: it is recorded and
# reported at the end of the run (script exits 1 in that case).
note "remote skills (npx skills add)"
REMOTE_SKILLS=(
  'anthropics/skills'        # official Anthropic — no LICENSE file in repo
  'vercel-labs/agent-skills' # official Vercel — no LICENSE file in repo
)
REMOTE_FAILED=()
if [ "$SKIP_REMOTE" = "1" ]; then
  warn "skipped remote installs. Would run:"
  for pkg in "${REMOTE_SKILLS[@]}"; do
    echo "      npx --yes skills add $pkg -g -a claude-code -s '*' -y"
  done
else
  command -v npx >/dev/null 2>&1 || die "npx not found on PATH. Install Node.js 18+ and re-run, or use --skip-remote."
  for pkg in "${REMOTE_SKILLS[@]}"; do
    echo "      npx --yes skills add $pkg -g -a claude-code -s '*' -y"
    if npx --yes skills add "$pkg" -g -a claude-code -s '*' -y; then
      ok "installed remote skills from $pkg"
    else
      warn "remote install failed for '$pkg' — continuing with the rest"
      REMOTE_FAILED+=("$pkg")
    fi
  done
fi
check_servers_json_sync

# --- 5. MCP servers (claude mcp add --scope user) --------------------------------
note "MCP servers (claude mcp add --scope user)"
dart_ok=1
if command -v dart >/dev/null 2>&1; then
  DART_VER="$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
  DART_MAJOR="${DART_VER%%.*}"; DART_MINOR="$(printf '%s' "$DART_VER" | cut -d. -f2)"
  if [ "${DART_MAJOR:-0}" -lt 3 ] || { [ "${DART_MAJOR:-0}" = "3" ] && [ "${DART_MINOR:-0}" -lt 9 ]; }; then
    dart_ok=0
    warn "Dart ${DART_VER:-unknown} found — dart MCP requires >= 3.9. Skipping dart MCP (everything else unaffected)."
  else
    ok "Dart ${DART_VER:-unknown} (>= 3.9) — dart MCP will be installed"
  fi
else
  dart_ok=0
  warn "dart not found on PATH — skipping dart MCP. Install Dart >= 3.9 and re-run to add it."
fi

if [ "$TEST_MODE" = "1" ]; then
  warn "test mode: not calling 'claude mcp add'. Would run:"
  for line in "${SERVER_LINES[@]}"; do
    name="${line%%|*}"
    [ "$name" = "dart" ] && [ "$dart_ok" = "0" ] && continue
    echo "      $(mcp_command_for "$line")"
  done
elif command -v claude >/dev/null 2>&1; then
  for line in "${SERVER_LINES[@]}"; do
    name="$(printf '%s' "$line" | cut -d'|' -f1)"
    scope="$(printf '%s' "$line" | cut -d'|' -f2)"
    cmd="$(printf '%s' "$line" | cut -d'|' -f3)"
    rest="$(printf '%s' "$line" | cut -d'|' -f4-)"
    if [ "$name" = "dart" ] && [ "$dart_ok" = "0" ]; then
      echo "      (dart MCP skipped — see warning above)"
      continue
    fi
    echo "      $(mcp_command_for "$line")"
    # args are intentionally word-split into separate flags/values
    if ! claude mcp add --scope "$scope" "$name" "$cmd" -- $rest; then
      die "failed to add MCP server '$name'. Fix the error above and re-run (replaced files were backed up in $BACKUP_DIR)."
    fi
    ok "MCP server '$name' added (scope: $scope)"
  done
else
  warn "'claude' CLI not found on PATH. Skipping automatic MCP setup."
  echo "      Run these manually on the machine where Claude Code is installed:"
  for line in "${SERVER_LINES[@]}"; do
    name="${line%%|*}"
    [ "$name" = "dart" ] && [ "$dart_ok" = "0" ] && continue
    echo "      $(mcp_command_for "$line")"
  done
fi

# --- 6. verify ------------------------------------------------------------------
if [ "$TEST_MODE" != "1" ] && command -v claude >/dev/null 2>&1; then
  note "claude mcp list"
  claude mcp list || die "'claude mcp list' failed — run it manually to inspect server state."
else
  note "claude mcp list (skipped: test mode or claude CLI not on PATH)"
fi

# --- summary ---------------------------------------------------------------------
note "summary"
echo "  skills copied      : $SKILLS_COUNT  -> $CLAUDE_HOME/skills/"
echo "  agents copied      : $AGENTS_COUNT  -> $CLAUDE_HOME/agents/"
echo "  CLAUDE.md          : merged block inserted (full file: $TARGET_CLAUDE)"
if [ "$BACKUP_USED" = "1" ]; then
  echo "  backups            : $BACKUP_DIR"
else
  echo "  backups            : none (nothing was replaced)"
fi
echo
echo "Plugin installs are manual (the installer never runs /plugin):"
echo "  Superpowers:  /plugin marketplace add obra/superpowers-marketplace"
echo "                /plugin install superpowers@superpowers-marketplace"
echo "  Flutter/Dart: /plugin marketplace add flutter/agent-plugins"
echo "                /plugin install dart-flutter@dart-flutter"
if [ "$TEST_MODE" = "1" ]; then
  echo "TEST MODE: no network calls were made and nothing outside $CLAUDE_HOME was written."
elif [ "${#REMOTE_FAILED[@]}" -gt 0 ]; then
  echo
  warn "FAILED remote installs (${#REMOTE_FAILED[@]}):"
  for pkg in "${REMOTE_FAILED[@]}"; do
    echo "      $pkg"
    echo "      retry: npx --yes skills add $pkg -g -a claude-code -s '*' -y"
  done
  ok "local setup is complete — only the remote installs above failed"
  exit 1
else
  ok "remote installs: all succeeded"
fi
ok "done"
