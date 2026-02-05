# REPO_MAP

## Overview
Hammerspoon Lua module to adjust Outlook for Mac "Text display size" for both Legacy and New Outlook via UI automation.

## Entry Points
- `init.lua`: Hammerspoon config entry point. Binds hotkeys, sets up notifications, and creates the menubar item.
- `outlook-font.lua`: Main module implementing configuration, UI automation, and toggle logic.

## Core Modules
- `outlook_font/ax.lua`: Accessibility tree helpers (find nodes by role/label and button groups).
- `outlook_font/util.lua`: Utility functions (deep copy/merge, JSONC stripping).

## Configuration
- `outlook-font.json`: Sample JSONC configuration for overriding defaults.
- Runtime config file: `~/.hammerspoon/outlook-font.json` (loaded by `outlook-font.lua`).

## Tests
- `spec/module_load_spec.lua`: Ensures module loads without Hammerspoon.
- `spec/util_spec.lua`: Unit tests for `util` helpers.
- `spec/ax_spec.lua`: Unit tests for accessibility helper logic.

## Tooling / CI
- `Makefile`: Local commands for tools, lint, format, tests, clean.
- `.github/workflows/ci.yml`: CI pipeline (fmt-check, lint, test).

## Hotspots / Risk Areas
- UI automation and accessibility tree traversal (`outlook-font.lua`, `outlook_font/ax.lua`).
- Timing/retry logic for window discovery and button presses (`outlook-font.lua`).
- JSONC parsing and config merge behavior (`outlook_font/util.lua`).

