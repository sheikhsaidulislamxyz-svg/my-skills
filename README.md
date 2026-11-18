# my-skills

A one-command, professional Claude Code setup for **Flutter/Dart, Firebase, backend, UI/UX design, testing, security and disciplined code editing** — curated from the best open-source agent skills, with verified licenses, an idempotent installer, and no guesswork.

## What's inside

| Area | Contents |
|---|---|
| 🎨 Design | `impeccable` (Apache-2.0), `design-taste-frontend` (MIT) — design vocabulary, polish/critique/audit, anti-slop frontend art direction |
| 🎯 Flutter / Dart | 15 official **dart-lang** skills (BSD-3) + 12 **dash_skills** (Apache-2.0) — unit tests, mocks, coverage, static analysis, doc validation, package maintenance |
| 🔥 Firebase | 14 official **firebase/agent-skills** (Apache-2.0) — Firestore, Auth, Hosting, FCM (crashlytics, remote-config, analytics), **firebase-security-rules-auditor**, firestore-rules-creation |
| ✅ Code review | `code-review-skill` (MIT) — architecture, performance, security, language-specific pitfalls incl. Dart/Flutter |
| 📖 Documentation | `beautify-github-readme` (MIT) — READMEs that are good *and* good-looking |
| 🧠 Planning / debugging / TDD / git-flow | **Superpowers** plugin (MIT) — brainstorming → writing-plans → executing-plans → TDD → systematic-debugging → verification-before-completion → git worktrees *(manual `/plugin` install)* |
| 🤖 Subagents | `agents/code-reviewer.md`, `agents/security-reviewer.md` (OWASP, Firestore rules, secrets, deps — Flutter/Firebase-focused) |
| 🔌 MCP servers | playwright, context7, sequential-thinking, firebase, dart (see `mcp/servers.json`) — added with `--scope user` |
| 📐 Global rules | `templates/CLAUDE.md` — Flutter/Firebase professional defaults (architecture, Firebase non-negotiables, testing bar, git hygiene, communication) |
| 🪝 Hooks | `hooks/dart-format.{sh,ps1}` — auto `dart format` after agent edits (manual wiring, by design) |
| 🖼️ Official Dart/Flutter MCP | `dart mcp-server` (official, ships with Dart ≥ 3.9) |

Plus two upstream skill sets installed at install-time via the `skills` ecosystem installer (their repositories carry **no license file**, so we deliberately do not copy them): **anthropics/skills** (skill-creator, docx/pdf/pptx/xlsx…) and **vercel-labs/agent-skills** (react-best-practices, web-design-guidelines…).

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI on `PATH`
- **Node.js 18+** with `npx` (for remote skills and MCP servers)
- `git`, and **Dart ≥ 3.9** (optional — only for the `dart` MCP server; older Dart or missing Dart skips just that server with a notice)
- macOS/Linux/WSL, or Windows with Git Bash (`install.sh`) or PowerShell (`install.ps1`)

## Quick start (new computer)

**The two code blocks below are platform-specific. Use only the one that matches your OS — do NOT paste both into the same terminal.**

**macOS / Linux / Git Bash / WSL** (bash/zsh) — paste this whole block:

```bash
git clone https://github.com/sheikhsaidulislamxyz-svg/my-skills.git
cd my-skills
chmod +x install.sh   # only if your checkout lost the exec bit
./install.sh
```

**Windows PowerShell** only (`powershell` or `pwsh`) — paste this whole block:

```powershell
git clone https://github.com/sheikhsaidulislamxyz-svg/my-skills.git
cd my-skills
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Mixing the two (e.g. `./install.sh` in cmd.exe/PowerShell, or the PowerShell line in a bash terminal) will fail — on Windows, bash-style `./install.sh` needs Git Bash/WSL, and `.\install.ps1` needs PowerShell. If in doubt on Windows: open **Git Bash** and use the first block, or open **PowerShell** and use the second.

The installer:

1. Copies everything in `skills/` → `~/.claude/skills/` and `agents/` → `~/.claude/agents/`
2. **Backs up** anything already present with the same name into `~/.claude/backups/my-skills-<timestamp>/` — never silently overwrites
3. **Merges** `templates/CLAUDE.md` into `~/.claude/CLAUDE.md` inside a clearly-marked block (`<!-- >>> my-skills managed block (Flutter/Firebase) >>> -->` … `<!-- <<< my-skills managed block <<< -->`). Your existing file is preserved; re-running the installer only refreshes the managed block. Nothing is overwritten.
4. Installs the MCP servers from `mcp/servers.json` with `claude mcp add --scope user …` (dart MCP skipped automatically if Dart < 3.9)
5. Runs `npx --yes skills add anthropics/skills -g -a claude-code -s '*' -y` and the same for `vercel-labs/agent-skills` (the `skills` CLI valid agent id is `claude-code`, not `claude`)
6. Finishes with `claude mcp list` so you see the result

A failed **remote skill install** (step 5) does **not** abort the rest: every remote skill is attempted, and at the end of the run the installer prints which ones failed (with exact retry commands) and exits non-zero so CI/scripts can detect it. All other failures **stop the install with the error printed** — nothing fails silently. Useful flags: `--skip-remote` (skip npx/claude steps), `MY_SKILLS_TEST=1` + `CLAUDE_HOME=<tmpdir>` for a hermetic dry run.

### After installing: two plugins are manual on purpose

The installer cannot (and must not) run `/plugin`. Run these inside Claude Code:

```text
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Official Flutter/Dart plugin (skills + MCP auto-config + rules):

```text
/plugin marketplace add flutter/agent-plugins
/plugin install dart-flutter@dart-flutter
```

Optionally wire the Dart-format hook — see [hooks/README.md](hooks/README.md). The installer deliberately does **not** edit `settings.json` (it may hold private env vars).

## Using in a new project

Skills are user-level, so new projects pick them up automatically. For best results per-project, add a short project `CLAUDE.md` (stack, commands, invariants) — it layers on top of the global one. A typical session flow with Superpowers: `brainstorming` → `writing-plans` → `executing-plans` → tests → `verification-before-completion` → `/code-review` or the `code-review-skill`.

For experiments without touching your real config:

```bash
MY_SKILLS_TEST=1 CLAUDE_HOME=$(mktemp -d) ./install.sh   # copies only, no network
```

## Updating

```bash
cd my-skills && git pull && ./install.sh
```

Re-running is safe: skills/agents are re-copied (old versions backed up first), the CLAUDE.md managed block is refreshed in place, and `claude mcp add` is idempotent per server name (it errors if a name already exists — in that case remove the server with `claude mcp remove <name>` and re-run, or use `--skip-remote`).

## Adding a new skill

1. Find or write the skill: `skills/<skill-name>/SKILL.md` with **mandatory frontmatter**:
   ```yaml
   ---
   name: <skill-name>        # lowercase, hyphenated, matches folder
   description: <what it does + when to use it — be specific; this is how the agent decides to load it>
   ---
   ```
2. License check **before** copying anything in: the upstream repo needs a redistribution-permitting license (MIT, Apache-2.0, BSD-2/3, ISC…). Copy its `LICENSE` into the skill folder and add a row in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) (source URL, license, copyright, modifications — usually "none"). If there is **no license file** or it is ambiguous: do **not** copy — add an `npx skills add <repo>` line in both installers instead.
3. Keep skill folders self-contained; reference `scripts/`/`reference/` inside the skill folder only.
4. Run the verification: `MY_SKILLS_TEST=1 CLAUDE_HOME=$(mktemp -d) ./install.sh` and the frontmatter check described in [Verification](#verification).
5. Update the tables in this README and `THIRD_PARTY_NOTICES.md`.

## Repository layout

```text
my-skills/
├── skills/            # 45 curated skills (each with its upstream LICENSE)
├── agents/            # code-reviewer.md, security-reviewer.md (subagents)
├── mcp/servers.json   # MCP inventory with commands, scope, prerequisites
├── templates/CLAUDE.md# global Flutter/Firebase working agreement (merged, not overwritten)
├── hooks/             # dart-format post-edit hooks + wiring notes
├── install.sh         # installer (bash) — MY_SKILLS_TEST=1 for dry runs
├── install.ps1        # installer (PowerShell)
├── THIRD_PARTY_NOTICES.md
└── LICENSE            # MIT (this repo's own content)
```

## Verification

bash — on Windows run this in **Git Bash**, not cmd/PowerShell:

```bash
# 1. Dry-run installer in a throwaway config dir (no network, no real config touched)
MY_SKILLS_TEST=1 CLAUDE_HOME=$(mktemp -d)/.claude ./install.sh

# 2. Frontmatter sanity check — every skill must declare name + description
#    (run from the repo root; needs Python 3)
python -I - <<'EOF'
import pathlib, re, sys
bad = []
for d in sorted(p for p in pathlib.Path('skills').iterdir() if p.is_dir()):
    t = (d / 'SKILL.md').read_text(encoding='utf-8', errors='replace')
    m = re.match(r'^---\s*\n(.*?)\n---', t, re.S)
    fm = m.group(1) if m else ''
    if 'name:' not in fm or 'description:' not in fm:
        bad.append(str(d))
print('bad:', bad if bad else 'none')
sys.exit(1 if bad else 0)
EOF
```

## Troubleshooting

- **`claude` not on PATH** — the installer prints the exact `claude mcp add --scope user …` commands to run manually; the rest of the setup still completes.
- **Dart < 3.9 or not installed** — the `dart` MCP server is skipped with a warning; install Dart ≥ 3.9 and re-run `./install.sh` to add it (`dart mcp-server` ships in the SDK).
- **`npx skills add` failed** — you'll see a `FAILED remote installs` list at the end with exact retry commands. Run `./install.sh --skip-remote` while iterating, then the two `npx` commands (with `-a claude-code`) manually once you have network access.
- **Conflict with an existing `~/.claude/skills/<name>`** — the installer moves it to `~/.claude/backups/my-skills-<timestamp>/` first; nothing is lost.
- **MCP server already exists** — `claude mcp remove <name>` then re-run, or keep your existing server.

## Credits & licenses

This repo is MIT (see [LICENSE](LICENSE)). Bundled third-party skills remain under their own licenses — every one is verified and attributed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) with source URL, license and copyright. Notable upstreams: Anthropic skills ecosystem, dart-lang, Flutter/Key/kevmoo, Firebase, awesome-skills, oil-oil, pbakaus, Leonxlnx, obra (Superpowers, plugin), Vercel Labs, Microsoft, Upstash, MCP reference servers.

## Contributing

PRs welcome — but the license gate above is enforced: no third-party code lands without a redistribution-compatible license file and a THIRD_PARTY_NOTICES.md entry.

## License

MIT © my-skills contributors. See [LICENSE](LICENSE).
