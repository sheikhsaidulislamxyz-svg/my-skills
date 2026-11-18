# Third-Party Notices

my-skills redistributes the following third-party skill content verbatim (no file content is modified except where noted). Each copied skill ships with a `LICENSE` file inside its own folder. The licenses below were verified on 2026-11-18 against the upstream repositories.

## Copied into `skills/`

### impeccable — `skills/impeccable/`
- Source: https://github.com/pbakaus/impeccable (path: `.claude/skills/impeccable/`)
- License: Apache-2.0 — full text: `skills/impeccable/LICENSE`, plus upstream `skills/impeccable/NOTICE.md` (contains additional third-party attributions — kept)
- Description: Design vocabulary for coding agents (polish, critique, audit…)
- Modifications: none (files copied as-is)

### design-taste-frontend — `skills/design-taste-frontend/`
- Source: https://github.com/Leonxlnx/taste-skill (path: `skills/taste-skill/`)
- License: MIT — Copyright (c) 2026 Leonxlnx — full text: `skills/design-taste-frontend/LICENSE`
- Modifications: folder renamed from `taste-skill` to `design-taste-frontend` (the skill's declared `name:`); file contents unchanged

### Dart official skills — `skills/dart-add-unit-test/` … `skills/dart-write-documentation/` (15 skills)
- Source: https://github.com/dart-lang/skills (path: `skills/`)
- License: BSD-3-Clause — Copyright 2012, the Dart project authors — full text: `skills/<name>/LICENSE`
- Skills: dart-add-unit-test, dart-build-cli-app, dart-collect-coverage, dart-fix-runtime-errors, dart-generate-test-mocks, dart-migrate-to-checks-package, dart-resolve-package-conflicts, dart-run-static-analysis, dart-setup-ffi-assets, dart-use-doc-examples, dart-use-ffigen, dart-use-path-package, dart-use-pattern-matching, dart-use-primary-constructors, dart-write-documentation
- Modifications: none

### dash_skills — `skills/dart-best-practices/`, `dart-doc-validation/`, `dart-long-lines/`, `dart-matcher-best-practices/`, `dart-modern-features/`, `dart-multiline-strings/`, `dart-package-maintenance/`, `dart-seal-type-hierarchies/`, `dart-test-coverage/`, `dart-test-fundamentals/`, `dash-discover/`, `profile-dart-code/` (12 skills)
- Source: https://github.com/kevmoo/dash_skills (path: `skills/`)
- License: Apache-2.0 — full text: `skills/<name>/LICENSE`
- Modifications: none

### Firebase official skills — `skills/extension-to-functions-codebase/` … `skills/xcode-project-setup/` (14 skills)
- Source: https://github.com/firebase/agent-skills (path: `skills/`)
- License: Apache-2.0 — full text: `skills/<name>/LICENSE`
- Skills: extension-to-functions-codebase, firebase-ai-logic-basics, firebase-analytics, firebase-app-hosting-basics, firebase-auth-basics, firebase-basics, firebase-crashlytics, firebase-data-connect-basics, firebase-firestore, firebase-hosting-basics, firebase-remote-config-basics, firebase-security-rules-auditor, firestore-rules-creation, xcode-project-setup
- Modifications: none

### code-review-skill — `skills/code-review-skill/`
- Source: https://github.com/awesome-skills/code-review-skill
- License: MIT — Copyright (c) 2025 awesome-skills — full text: `skills/code-review-skill/LICENSE`
- Modifications: only the skill payload was copied (`SKILL.md`, `reference/`, `scripts/`); the repo's website/gallery files were not copied

### beautify-github-readme — `skills/beautify-github-readme/`
- Source: https://github.com/oil-oil/beautify-github-readme (path: `skills/beautify-github-readme/`)
- License: MIT — Copyright (c) 2026 oil-oil — full text: `skills/beautify-github-readme/LICENSE`
- Modifications: none

## Installed via `npx skills add` at install time (NOT redistributed by this repo)

Upstream repositories carry no license file, or an unverifiable one, so we do not copy their code. The installer runs `npx --yes skills add <repo> -g -a claude -s '*' -y`:

- https://github.com/anthropics/skills — "Public repository for Agent Skills" (Anthropic). No LICENSE file in repo; delegating to the ecosystem installer.
- https://github.com/vercel-labs/agent-skills — "Vercel's official collection of agent skills" (MIT is shown in the repository sidebar but no LICENSE file is present); delegating to the ecosystem installer.

## Plugin / marketplace installs (NOT redistributed by this repo)

- https://github.com/obra/superpowers (MIT, Copyright obra) — Claude Code plugin `superpowers`; install via `/plugin` commands documented in README.md.
- https://github.com/flutter/agent-plugins (BSD-3-Clause, Flutter project authors) — official Flutter plugin `dart-flutter`; install via `/plugin` commands documented in README.md.
- https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp_server — the official Dart & Flutter MCP server (ships inside the Dart SDK as `dart mcp-server`, requires Dart >= 3.9).

## MCP servers (NOT redistributed by this repo)

Installed by the installer as executables, not copied source:

- @playwright/mcp — https://github.com/microsoft/playwright-mcp (Apache-2.0, Microsoft)
- @upstash/context7-mcp — https://github.com/upstash/context7 (MIT, Upstash)
- @modelcontextprotocol/server-sequential-thinking — https://github.com/modelcontextprotocol/servers (reference server; see upstream LICENSE/NOTICE files)
- firebase-tools (MCP mode) — https://github.com/firebase/firebase-tools (Apache-2.0, Google)

---

my-skills' own original content (installers, templates, agents, hooks, docs) is MIT — see [LICENSE](LICENSE). Upstream trademarks and skill names belong to their respective owners.
