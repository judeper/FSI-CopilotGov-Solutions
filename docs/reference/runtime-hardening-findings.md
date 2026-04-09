# Runtime Hardening Findings

> **Note:** This document was produced during the v0.2.0–v0.2.1 hardening cycle. The findings listed below informed the semantic corrections applied in v0.2.1. This document is retained for audit trail purposes.

## Overview

- **Solutions Analyzed:** 01, 04, 11, 12, 13
- **Shared Modules:** GraphAuth, EvidenceExport, DataverseHelpers, IntegrationConfig, PurviewHelpers, EntraHelpers, TeamsNotification

---

## Overstated Implementation Claims (4 of 5 Solutions)

### Solution 01: Copilot Readiness Scanner

| Aspect | Detail |
|--------|--------|
| **Claim** | "Performs Graph API-based scanning across 6 domains" |
| **Reality** | Returns hardcoded test scores (82, 74, 76, 84, 67, 80) |
| **Test data** | `Monitor-Compliance.ps1` lines 221–329 |

**Files to fix:**

- `README.md` line 11
- `docs/architecture.md` lines 68–71
- `scripts/common/GraphAuth.psm1` (add clarifying comment)

### Solution 04: FINRA Supervision Workflow

- ✓ **ACCURATE** — Already discloses "documentation-first"
- No changes needed

### Solution 11: Risk-Tiered Rollout Automation

| Aspect | Detail |
|--------|--------|
| **Claim** | "Sequences Copilot license assignment" |
| **Reality** | Generates wave manifests only; no actual license assignment |
| **Test data** | `Deploy-Solution.ps1` returns manifest JSON, no Graph calls |

**Files to fix:**

- `README.md` lines 9, 27–28
- `docs/architecture.md` lines 22–47

### Solution 12: Regulatory Compliance Dashboard

| Aspect | Detail |
|--------|--------|
| **Claim** | "Aggregates evidence into Dataverse and Power BI" |
| **Reality** | Power BI is documentation-first; Dataverse connections manual |
| **Test data** | Flows documented but not deployed by scripts |

**Files to fix:**

- `README.md` lines 8, 35–36, 112–116
- `docs/architecture.md` lines 58–76

### Solution 13: DORA Operational Resilience Monitor

| Aspect | Detail |
|--------|--------|
| **Claim** | "Captures service health snapshots through Graph" |
| **Reality** | v0.1.0 uses test data; Graph integration pending |
| **Test data** | No actual Graph API calls in current version |

**Files to fix:**

- `README.md` line 20
- `scripts/Monitor-Compliance.ps1` help text

---

## Shared Module Clarifications Needed

### `GraphAuth.psm1`

- **Function:** `New-CopilotGovGraphContext`
- **Issue:** Returns context structure only; no actual authentication
- **Fix:** Add comment: "Context structure only; real authentication deferred to caller"

### `DataverseHelpers.psm1`

- **Function:** `New-DataverseTableContract`
- **Issue:** Defines schema; doesn't create tables or execute CRUD
- **Fix:** Add comment: "Schema contract only; customer must deploy tables manually"

### `PurviewHelpers.psm1`

- **Function:** `New-PurviewAssessmentRecord`
- **Issue:** Creates record structure; doesn't invoke Purview scan
- **Fix:** Add comment: "Record structure only; no actual Purview API calls"

### `IntegrationConfig.psm1`

- All functions map configuration values
- **Issue:** No help text explaining this supports stub implementations
- **Fix:** Add file-level comment: "Shared contract; supports stub and live implementations"

### `EvidenceExport.psm1`

- **Function:** `Test-CopilotGovEvidencePackage`
- **Issue:** Validates schema/hash; not data freshness
- **Fix:** Add to help: "Validates schema and hash integrity only; not data quality"

---

## Validation Commands (Copy/Paste Ready)

### Command 1: Find Overstated Claims in READMEs

```powershell
grep -r "Graph API.*scanning|polling|automatically|sequences.*assign" `
  solutions/{01,11,12,13}-*/README.md
```

### Command 2: Find Hardcoded Test Scores (82, 74, 76, 84, 67, 80)

```powershell
grep -n "BaseScore (82|74|76|84|67|80)" `
  solutions/*/scripts/Monitor-Compliance.ps1
```

### Command 3: Verify No Live API Calls Exist

```powershell
grep -r "Invoke-MgGraphRequest|Get-MgSubscribedSku|New-AdminFlow|New-CrmRecord" `
  solutions/*/scripts/
```

### Command 4: Check Evidence Freshness

```powershell
Get-ChildItem -Path solutions/*/artifacts/*-evidence.json |
  ForEach-Object {
    $json = Get-Content $_ | ConvertFrom-Json
    Write-Host "$($_.Name): $($json.metadata.exportedAt)"
  }
```

### Command 5: Run Test Suite

```powershell
Invoke-Pester solutions/*/tests/*.Tests.ps1
.\scripts\validate-evidence.ps1 -ConfigurationTier regulated
```

---

## Files to Inspect/Change — Priority Order

### Highest Priority — Semantic Accuracy (Regulatory Impact)

- [ ] `solutions/01-copilot-readiness-scanner/README.md`
- [ ] `solutions/01-copilot-readiness-scanner/docs/architecture.md`
- [ ] `solutions/11-risk-tiered-rollout/README.md`
- [ ] `solutions/11-risk-tiered-rollout/docs/architecture.md`
- [ ] `solutions/12-regulatory-compliance-dashboard/README.md`
- [ ] `solutions/12-regulatory-compliance-dashboard/docs/architecture.md`
- [ ] `solutions/13-dora-resilience-monitor/README.md`

### Medium Priority — Module Help Text (Code Clarity)

- [ ] `scripts/common/GraphAuth.psm1`
- [ ] `scripts/common/DataverseHelpers.psm1`
- [ ] `scripts/common/PurviewHelpers.psm1`
- [ ] `scripts/common/IntegrationConfig.psm1`
- [ ] `scripts/common/EvidenceExport.psm1`

### Medium Priority — Test Extensions (Runtime Validation)

- [ ] Create: `scripts/validate-implementation-liveness.ps1`
- [ ] Extend: `solutions/01-*/tests/*.Tests.ps1`
- [ ] Extend: `solutions/12-*/tests/*.Tests.ps1`
- [ ] Extend: `solutions/13-*/tests/*.Tests.ps1`

---

## Specific Line-by-Line Changes

| Location | Before | After |
|----------|--------|-------|
| `01-copilot-readiness-scanner/README.md:11` | "Performs Graph API-based scanning across licensing…" | "Provides scanning framework with test data; ready for Graph API integration" |
| `01-copilot-readiness-scanner/docs/architecture.md:68-71` | *(no disclaimer)* | Add: "Note: Repository version uses sample data. For live implementation, customer must bind Graph, Purview, and SharePoint endpoints." |
| `11-risk-tiered-rollout/README.md:9` | "sequences Copilot license assignment" | "prepares license assignment wave manifests for manual execution" |
| `11-risk-tiered-rollout/README.md:27-28` | "stages license-assignment actions" | "generates license assignment manifests (requires manual approval and execution)" |
| `12-regulatory-compliance-dashboard/README.md:8` | "aggregates evidence exports…into Dataverse and Power BI" | "documents aggregation pattern; customer must deploy Dataverse connections and Power BI bindings" |
| `13-dora-resilience-monitor/README.md:20` | *(no disclaimer)* | Add: "(v0.1.0: includes polling framework; Graph integration required for live deployment)" |

---

## Tests That Already Exist (Sufficient)

- ✓ `solutions/01-*/tests/01-copilot-readiness-scanner.Tests.ps1` — Validates file structure, configs, syntax; checks retention settings tier-appropriate
- ✓ `solutions/12-*/tests/12-regulatory-compliance-dashboard.Tests.ps1` — Validates configs, help text, script syntax; checks retention ≥ 365 days for regulated
- ✓ `solutions/13-*/tests/13-dora-resilience-monitor.Tests.ps1` — Validates files, configs, script parameters; checks solution codes, control definitions
- ✓ `scripts/validate-evidence.ps1` — Runs all `Export-Evidence.ps1` scripts; validates evidence packages against schema; checks hash integrity

---

## Smoke Check Commands to Add

**Create:** `scripts/validate-implementation-liveness.ps1`

**Purpose:** Detect oversold features, ensure honest semantics.

**Tests to include:**

1. Hardcoded test scores detection — FAIL if domain scans return only test values
2. Graph connectivity check — FAIL if Graph context not authenticated
3. Dataverse write verification — FAIL if table operations not executed
4. Power Automate flow existence — FAIL if flows not deployed in environment
5. Evidence freshness check — FAIL if `exportedAt` > 24h old (regulated tier)
6. Data quality audit — FAIL if artifacts contain template/placeholder content

---

## Risk Summary

### Regulatory Risk: HIGH

- READMEs overstate implementation depth (Graph scanning, license assignment)
- Examiners may expect live functionality based on claims
- Stubs/placeholders not always clearly distinguished in documentation

### Operational Risk: MEDIUM

- Customers may attempt to use scripts in production expecting live integration
- No smoke checks validate actual vs. test data
- Service dependencies (Dataverse, Power Automate, Power BI) not auto-verified

### Documentation Risk: HIGH

- Architecture diagrams show "License Assigner", "Evidence Aggregator" as deployed
- Feature descriptions read as implemented, not planned
- Known limitations buried; main claims overstated

### Mitigation

Update 7 files (README/architecture docs), add 5 module comments, create 1 validation script, extend 4 test suites.
