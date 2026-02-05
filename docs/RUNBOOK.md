# RUNBOOK

This runbook captures the local development and CI commands for this repository.

## Prerequisites
- macOS (runtime target is Hammerspoon on macOS)
- Homebrew packages:
  - `lua`
  - `luarocks`
  - `stylua`
- Hammerspoon (for manual runtime validation)

## Setup
Install Lua tooling into the local `.luarocks` tree (pinned versions in Makefile):

```bash
make tools
```

## Format
```bash
make fmt
```

## Format Check (CI parity)
```bash
make fmt-check
```

## Lint
```bash
make lint
```

## Tests
```bash
make test
```

## Clean
```bash
make clean
```

## Fast Loop
Minimal checks used for quick iteration:

```bash
make fmt-check lint test
```

## Full Loop
Same as CI:

```bash
make fmt-check lint test
```

## Security Checks (Local, Best-Effort)
CI runs the security baseline (gitleaks, dependency review, semgrep). Local runs
are optional and best-effort if tools are installed.

Secret scan (common patterns):
```bash
rg --hidden -n -g '!.git' -g '!.luarocks' -e '(AKIA|ASIA|AIza|-----BEGIN PRIVATE KEY-----|xox[baprs]-|ghp_|github_pat_)'
```

Secret scan (gitleaks, optional):
```bash
gitleaks detect --redact --no-git -s .
```

SAST (semgrep, optional):
```bash
semgrep --config=auto --error --metrics=off --severity=ERROR
```

Dependency review (local LuaRocks tree):
```bash
luarocks list --tree ./.luarocks
```

## Manual Runtime Validation (Hammerspoon)
1. Copy `init.lua`, `outlook-font.lua`, and `outlook_font/` into `~/.hammerspoon/`.
2. Reload Hammerspoon.
3. Trigger the hotkeys and verify:
   - Settings/Preferences open correctly.
   - Text size changes as expected.
   - Notifications and overlay appear.
