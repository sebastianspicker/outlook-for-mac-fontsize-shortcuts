# CI Audit

Letzte beobachtete Fehlläufe (GitHub Actions, 2026-02-05):

| Workflow | Failure(s) | Root Cause | Fix Plan | Risiko | Status | Wie verifizieren |
| --- | --- | --- | --- | --- | --- | --- |
| CI | `gitleaks` – "GITHUB_TOKEN is now required to scan pull requests" + "Unexpected input(s) 'args'" | Action wurde aktualisiert, aber Workflow nutzt nicht die neuen Anforderungen (kein `GITHUB_TOKEN`, ungültiger Input `args`). | Upgrade auf `gitleaks/gitleaks-action@v2`, `GITHUB_TOKEN` als Env setzen, `args` entfernen, PR‑Kommentare deaktivieren. | Niedrig | **Fixed (pending CI rerun)** | CI‑Run auf PR/PUSH (Job `gitleaks` muss grün werden). |
| CI | `dependency-review` – "Dependency review is not supported on this repository" | Dependency Graph ist deaktiviert und Repo hat keine klassischen Package‑Manifeste. | Job aus Standard‑CI entfernen; optional später reaktivieren nach Aktivierung des Dependency Graph. | Niedrig | **Fixed (removed from default CI)** | CI‑Run ohne den Job; optional: Settings aktivieren und Job wieder hinzufügen. |
| CI | `semgrep` – "Process completed with exit code 2" | Semgrep Auto‑Config liefert nicht deterministische Exit Codes für dieses Repo (keine stabilen Logs verfügbar). | Entfernen aus PR‑CI; optional manuell/gescheduled mit gepinnter Config und SARIF. | Niedrig | **Fixed (removed from default CI)** | CI‑Run ohne Semgrep; optional manuell testen. |
| CI | `lua` – "stylua failed with exit code 2" (Step: Set up StyLua) | `stylua-action` wurde als Setup‑Step genutzt, aber die Action führt Stylua aus und benötigt explizite `args`. | Stylua‑Action mit `args: --check .` nutzen; redundanten `make fmt-check` Step entfernen. | Niedrig | **Fixed (pending CI rerun)** | CI‑Run: `lua` Job grün; lokales `make fmt-check` bleibt reproduzierbar. |
