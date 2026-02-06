# CI-Entscheidung

## Entscheidung
**FULL CI** (schnelle Quality Gates + Tests + Secret Scan) auf `push` und `pull_request`.

## Begründung
- Repo enthält ausführbaren Lua-Code + Tests (`busted`), daher bringen Format/Lint/Test echten Nutzen.
- Checks sind schnell (< 1–2 min), deterministisch und benötigen keine Secrets oder externe Infrastruktur.
- Sicherheitsnutzen durch Secret Scan (gitleaks) ohne Risiko für Secrets/Exfiltration.

## Was läuft wann?
- `pull_request` (gegen `main`):
  - Formatcheck (StyLua)
  - Lint (luacheck)
  - Tests (busted)
  - Secret Scan (gitleaks)
- `push` auf `main`:
  - gleiche Checks wie PR
- `workflow_dispatch` (manuell):
  - gleiche Checks wie PR

## Threat Model für CI
- **Fork PRs** sind untrusted: keine Secrets, kein `pull_request_target`, nur Read‑Permissions.
- `GITHUB_TOKEN` ist read‑only (`contents: read`, `pull-requests: read`) und wird nur für gitleaks benötigt.
- Keine Deployments, keine externen Credentials, keine privileged steps.
- Cache enthält nur Tooling/Abhängigkeiten (`.luarocks`), keine Secrets.

## Grenzen / Annahmen
- Kein Integrationstest gegen reale Outlook-Instanzen (nicht reproduzierbar in GitHub‑Runnern).
- Keine Dependency‑Review (Repo hat keine klassischen Package‑Manifeste; Dependency Graph ist aktuell deaktiviert).
- Kein Semgrep in PR‑CI (Auto‑Config lieferte nicht deterministische Exit‑Codes; optional später).

## Wenn wir später „erweitertes“ Security‑CI wollen
- **Dependency Review**:
  - Dependency Graph in den Repo‑Settings aktivieren.
  - Danach Job wieder hinzufügen.
- **Semgrep**:
  - Konfiguration pinnen (`semgrep --config p/ci` oder eigenes Regelset),
  - optional als `schedule`/`workflow_dispatch`,
  - klare Baseline und SARIF‑Upload.
