# Hooks

Optional hook scripts. **The installer does not touch your `settings.json` automatically** — on most machines that file contains private environment variables, so wiring hooks is a deliberate manual step.

## dart-format — format Dart files after every edit

**macOS / Linux / Git Bash:**

```jsonc
// ~/.claude/settings.json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/dart-format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Windows (PowerShell):**

```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\\.claude\\hooks\\dart-format.ps1",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Notes:

- Copy or symlink the scripts anywhere stable (e.g. `~/.claude/hooks/`) before referencing them — if you move the repo, update the path.
- The hook reads the edited file path from the hook JSON on stdin; it ignores non-`.dart` files, silently succeeds when `dart` is not on PATH, and exits `1` (so the agent sees it) when formatting fails.
- Make the `.sh` executable: `chmod +x hooks/dart-format.sh`.
- To disable later, remove the `PostToolUse` entry — nothing else needs cleanup.
