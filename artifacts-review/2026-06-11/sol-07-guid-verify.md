# Solution 07 — Copilot first-party app GUID re-verification

**Date:** 2026-06-11
**Issue:** judeper/FSI-CopilotGov-Solutions#218 (umbrella for Phase 1 issues #116, #119, #122, #125, #129, #143)
**Subject GUID:** `fb8d773d-7ef8-4ec0-a117-179f88add510` (historically associated with "Enterprise Copilot Platform" / Microsoft 365 Copilot)
**Scope:** Technical correctness only.

## Summary

The substantive remediation requested by issue #218 — replacing the unverifiable individual
first-party application ID with a citable Conditional Access target — was **already completed**
in remediation **PR #199 (v0.2.1, commit `02d1c8f`)**. The GUID no longer appears in any
solution 07 configuration, documentation, script, or test file. It is present only in
historical `artifacts-review/` review snapshots, which are point-in-time records.

This re-verification confirms the **current** targeting model is accurate against live
Microsoft Learn and adds a regression guard so the unverifiable GUID cannot silently return.

## Live Microsoft Learn verification

| Claim under review | Result | Source (verified 2026-06-11) |
|--------------------|--------|------------------------------|
| `Office365` Conditional Access app suite includes Enterprise Copilot Platform (Microsoft 365 Copilot) | **CONFIRMED** — "Enterprise Copilot Platform" is listed in the included-applications list | <https://learn.microsoft.com/en-us/entra/identity/conditional-access/reference-office-365-application-contents> |
| Microsoft 365 Copilot honors Conditional Access policies and MFA | **CONFIRMED** — "Copilot honors Conditional Access policies and multifactor authentication (MFA)" | <https://learn.microsoft.com/en-us/microsoft-365/copilot/microsoft-365-copilot-architecture> |
| The individual app ID `fb8d773d-…` is published on Microsoft Learn | **NOT PUBLISHED** — no Microsoft Learn article publishes this app/client ID (original Phase 1 finding still holds; now moot for the solution) | n/a |

## Repository state confirmation

- `git log -S "fb8d773d-7ef8-4ec0-a117-179f88add510" -- solutions/07-conditional-access-automation/`
  shows the final change in commit `02d1c8f` (PR #199). The diff replaces
  `"fb8d773d-7ef8-4ec0-a117-179f88add510"` with `"Office365"` in `config/default-config.json`
  and adds `targetResourceMode: "office365-app-suite"` plus tenant-verified app-ID guidance.
- A repository-wide search finds the GUID **only** under `artifacts-review/` (historical review
  records). It does not appear in `solutions/07-conditional-access-automation/`.

### Status of the 7 locations cited by issue #218

| Location (issue #218) | Current state |
|-----------------------|---------------|
| `README.md` | No GUID. Uses `Office365` app-suite target; now cites Microsoft Learn. |
| `config/default-config.json` | `copilotAppIds: ["Office365"]`. No GUID. |
| `config/baseline.json` | `copilotAppIds: ["Office365"]`. No GUID. |
| `config/recommended.json` | `copilotAppIds: ["Office365"]`. No GUID. |
| `config/regulated.json` | `copilotAppIds: ["Office365"]`. No GUID. |
| `scripts/Monitor-Compliance.ps1` | No GUID. Reads `copilotAppIds` from config. |
| `tests/07-conditional-access-automation.Tests.ps1` | No GUID. Now includes a regression guard asserting absence. |

## Acceptance criteria disposition

- [x] **Live tenant Graph lookup result captured** — captured as this document. The
      Microsoft Graph service-principal lookup itself is **deferred** (no target tenant
      available) and is now **moot** for the solution, because no individual app GUID is
      hardcoded. See "Deferred tenant step" below.
- [x] **All 7 occurrences reviewed** — all were replaced with `Office365` in PR #199; zero
      occurrences remain in the solution. Confirmed by repository-wide search.
- [x] **CHANGELOG updated** — `solutions/07-conditional-access-automation/CHANGELOG.md` entry `[v0.2.5]`.
- [ ] **All validators green** — recorded in the PR check run.

## Deferred tenant step (requires a target tenant)

When a target tenant becomes available, an operator can confirm the live service-principal
`appId` for the first-party application using Microsoft Graph PowerShell:

```powershell
Get-MgServicePrincipal -Filter "displayName eq 'Enterprise Copilot Platform'" |
    Select-Object DisplayName, AppId, ServicePrincipalType
```

Because the solution targets the `Office365` Conditional Access app suite rather than an
individual app ID, this lookup is informational. If a future design adds individual app-ID
targeting, validate the resolved `AppId` against the tenant service principal before use, and
gate any live-verification test behind `if ($env:FSI_TENANT_VERIFY -eq '1')`.

## Changes made in the linked PR (sol 07, v0.2.4 → v0.2.5)

1. `README.md` — added `## Microsoft Learn References` and a tenant-verification note; bumped status line.
2. `tests/07-conditional-access-automation.Tests.ps1` — added a regression guard for the unverifiable GUID and an `Office365` retention check.
3. `config/default-config.json` — `version` → `v0.2.5`, `last_verified` → `2026-06-11`.
4. `data/solution-catalog.json` — solution 07 `version` → `v0.2.5`.
5. `CHANGELOG.md` — new `[v0.2.5]` entry.
