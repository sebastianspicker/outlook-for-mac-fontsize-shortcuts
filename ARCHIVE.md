# Archive Notice

This repository is **archived**. It is no longer maintained and is kept for reference and reuse.

## What This Repo Is

**Outlook Text Display Size Controller** — A Hammerspoon-based tool to adjust "Text display size" in New Outlook and Legacy Outlook for Mac via global hotkeys, menubar dropdown, and JSON configuration. See [README.md](README.md) for features, installation, and usage.

## Keep / Remove / Move Summary

### Kept (runnable code and minimal docs)

| Path | Reason |
|------|--------|
| `init.lua` | Hammerspoon entry point; loads the module |
| `outlook-font.lua` | Main module; hotkeys, menubar, config |
| `outlook_font/` | Library (ax.lua, util.lua) |
| `outlook-font.json` | Example config for overrides |
| `spec/` | Busted tests (all `*_spec.lua`, `spec_helper.lua`) |
| `.github/workflows/ci.yml` | CI: format check, lint, test, gitleaks |
| `.github/ISSUE_TEMPLATE/` | Bug/feature issue templates |
| `Makefile` | tools, lint, fmt, test, ci |
| `LICENSE` | License |
| `.editorconfig`, `.luacheckrc`, `.stylua.toml` | Editor/lint/format config |
| `.gitignore` | Ignore Lua artifacts, coverage, caches, OS/editor files |
| `README.md` | User-facing docs and validation commands |

### Removed (WIP / process artifacts)

| Path | Reason |
|------|--------|
| `.codex/` | Tooling and branding removed; content moved to `docs/issue-audit/` |
| `docs/LOG.md` | Iteration log (process only) |
| `docs/FINDINGS.md` | Findings log (process only) |
| `docs/DECISIONS.md` | Empty/minimal decisions log (process only) |

### Moved (Issue Audit preserved)

| From | To | Reason |
|------|----|--------|
| `.codex/ralph-audit/` | `docs/issue-audit/` | Preserve Issue Audit; remove tool-specific path and branding |
| (CODEX.md) | `docs/issue-audit/AUDIT_AGENT_INSTRUCTIONS.md` | Renamed and stripped external references |
| (ralph.sh) | `docs/issue-audit/ralph.sh` | Kept as reference-only stub (no executable runner) |

All references to third-party tooling have been removed from the retained audit docs. The Issue Audit (PRD, instructions, progress, stub script) is in **English** and suitable for GitHub.

## Final Folder Structure

```
.
├── .editorconfig
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   └── workflows/
│       └── ci.yml
├── .gitignore
├── .luacheckrc
├── .stylua.toml
├── ARCHIVE.md          (this file)
├── LICENSE
├── Makefile
├── README.md
├── docs/
│   └── issue-audit/    (Issue Audit: PRD, instructions, progress, reference script)
│       ├── AUDIT_AGENT_INSTRUCTIONS.md
│       ├── README.md
│       ├── progress.txt
│       ├── prd.json
│       └── ralph.sh
├── init.lua
├── outlook-font.json
├── outlook-font.lua
├── outlook_font/
│   ├── ax.lua
│   └── util.lua
└── spec/
    ├── ax_spec.lua
    ├── config_spec.lua
    ├── core_spec.lua
    ├── module_load_spec.lua
    ├── spec_helper.lua
    └── util_spec.lua
```

## Validation Commands

Run from repo root:

| Goal | Command |
|------|---------|
| Install Lua tooling | `make tools` (requires `luarocks`) |
| Format check | `make fmt-check` (requires `stylua`) |
| Lint | `make lint` |
| Test | `make test` |
| CI (format + lint + test) | `make ci` |
| Format code | `make fmt` |

To **run** the Hammerspoon module: copy `init.lua`, `outlook-font.lua`, and `outlook_font/` to `~/.hammerspoon/`, optionally `outlook-font.json`, then reload Hammerspoon.

If `make lint` or `make test` fail with a path error (e.g. a different repo path in the message), remove the Lua tree and reinstall: `rm -rf .luarocks && make tools`, then run the commands again.
