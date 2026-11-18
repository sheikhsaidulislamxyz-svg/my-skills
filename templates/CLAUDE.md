# Global working agreement — Flutter/Firebase (managed by my-skills)

These are global defaults for every project on this machine. Project-level `CLAUDE.md` files can override specifics; they should not contradict the safety rules.

## Code quality bar

- Dart: follow Effective Dart and `package:lints/recommended` (or `flutter_lints`). Run `dart format` on every file you touch. Zero analyzer errors before a task is "done" — `flutter analyze` must pass.
- Prefer `final`, `const` constructors, and immutable models (`freezed`/`copyWith` where the project already uses them). Avoid `late` unless genuinely needed.
- Null safety is not a formality: no `!` without a proof in scope, no `dynamic` crossing layer boundaries.
- Small functions, single responsibility, early returns. Comments explain *why*, not *what*.

## Architecture defaults

- Feature-first structure: `lib/features/<feature>/{data,domain,presentation}`. Shared code in `lib/core` or `lib/shared`.
- One-directional dependency: UI → domain → data. Widgets never call Firestore/HTTP directly; they go through repositories.
- State management: stay consistent with the project (Riverpod preferred for new code, Bloc acceptable when already established). No setState for anything beyond trivial local UI state.
- Async: always `await` futures or handle errors explicitly; cancel stream subscriptions in `dispose()`; guard `setState`/navigation after `await` with `mounted` / `context.mounted`.

## Firebase rules (non-negotiable)

- Never ship `allow read, write: if true` — not even "temporarily". Every rule gets an ownership/role check and field validation.
- Firestore access from Flutter only through repositories with bounded queries (`limit`, proper `where`).
- Client code contains no secrets. Firebase client config is public by design; security lives in Security Rules + App Check. Enforce App Check for sensitive collections before public release.
- Any change to Firestore/Storage rules ships with a rules unit test (`@firebase/rules-unit-testing` or the Firebase emulator).
- Cloud Functions: validate input, check auth/claims server-side, return generic errors, never log secrets.

## UI/UX bar

- Material 3 first; respect platform conventions (Cupertino where the project targets iOS-first).
- Accessibility is part of done: semantic labels on custom controls, 48dp touch targets, WCAG AA contrast, layouts tested at 1.3x text scale and on a small screen.
- Responsive by default: use `LayoutBuilder`/`MediaQuery` breakpoints, not fixed pixel widths. No overflow exceptions tolerated.
- Loading, empty and error states are required for every async view. A spinner with no retry path is a bug.

## Testing bar

- New logic ships with tests: unit tests for domain/data, widget tests for UI states, integration/emulator tests for Firebase rules and critical flows.
- Bug fixes land with a regression test that fails on the old code.
- Don't claim a task complete without running the relevant tests (`flutter test`, rules tests) and `flutter analyze`. "It should work" is not verification.

## Debugging & verification protocol

- Reproduce first, then fix. One hypothesis at a time. Read the actual error, stack trace and logs before editing.
- After any fix: re-run the failing scenario, then the full test suite, then analyze. Report results honestly — including failures.

## Git & delivery

- Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`…). Small, reviewable commits. Never commit `.env*`, `google-services.json` from untrusted sources, keystores, or build artifacts.
- `flutter build` output and `.dart_tool/`, `build/`, `*.iml` stay gitignored.
- Before opening a PR: format, analyze, test, and summarize what changed and why in the PR body.

## Security & privacy

- No PII in logs (print/Crashlytics/Analytics). Strip debug logging from release builds.
- Dependencies: check `pub outdated` and advisories before adding or bumping packages; pin versions you rely on.
- Validate and sanitize everything from the network; treat deep links and push-notification payloads as untrusted input.

## Communication

- Be concise and direct. Lead with the answer or the change. Show the diff summary and verification evidence, not a narration of your process.
- When blocked or a step fails, stop and report the exact error — no silent fallbacks, no guessing at file paths, flags or credentials.
