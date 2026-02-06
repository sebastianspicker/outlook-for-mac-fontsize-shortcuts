# CI

## Überblick
Workflow: `.github/workflows/ci.yml`

Trigger:
- `pull_request` (gegen `main`)
- `push` auf `main`
- `workflow_dispatch`

Jobs:
- **Lua quality + tests**
  - StyLua `--check .`
  - `make tools` (luacheck, busted via LuaRocks)
  - `make lint`
  - `make test`
- **Secret scan (gitleaks)**
  - gitleaks Scan ohne PR‑Kommentare

## Lokal ausführen
Voraussetzungen (macOS):
- `lua`
- `luarocks`
- `stylua`

Empfohlene Befehle:
```bash
make tools
make fmt-check
make lint
make test
# oder alles zusammen:
make ci
```

## Caching
- LuaRocks wird in `.luarocks` installiert und in Actions gecached.
- Zusätzlich wird `~/.cache/luarocks` gecached.

## Secrets & Settings
- Keine Repo‑Secrets erforderlich.
- `GITHUB_TOKEN` wird automatisch von GitHub bereitgestellt (read‑only).
- Falls das Repo später in eine Organization umzieht: gitleaks benötigt dann ein `GITLEAKS_LICENSE` Secret.

## Jobs erweitern
- Neue Jobs immer mit:
  - minimalen `permissions`
  - `timeout-minutes`
  - klaren Step‑Namen
  - deterministischen Tool‑Versionen
- Für langsame oder environment‑gebundene Checks: `workflow_dispatch` oder `schedule` nutzen.
