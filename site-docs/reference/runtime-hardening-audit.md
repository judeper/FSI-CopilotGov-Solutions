# Runtime Hardening Audit

> **Note:** This document was produced during the v0.2.0–v0.2.1 hardening cycle. The findings listed below informed the semantic corrections applied in v0.2.1. This document is retained for audit trail purposes.

## Target Solutions Reviewed

- Solution 01: Copilot Readiness Assessment Scanner
- Solution 04: FINRA Supervision Workflow
- Solution 11: Risk-Tiered Rollout Automation
- Solution 12: Regulatory Compliance Dashboard
- Solution 13: DORA Operational Resilience Monitor

## Key Shared Modules

- `scripts/common/GraphAuth.psm1`
- `scripts/common/EvidenceExport.psm1`
- `scripts/common/DataverseHelpers.psm1`
- `scripts/common/IntegrationConfig.psm1`
- `scripts/common/PurviewHelpers.psm1`
- `scripts/common/EntraHelpers.psm1`
- `scripts/common/TeamsNotification.psm1`

---

## Category 1: Graph Scanning Claims vs. Actual Implementation

### Overstated: Solution 01 README Line 11

<!-- fsi-lang:allow="performs graph api scanning" reason="audit document quotes overstated phrasing verbatim to recommend correction" -->
**Claim:** "Performs Graph API-based scanning across licensing, identity, security, compliance, governance, and Copilot configuration domains."

**Reality:**

- `Monitor-Compliance.ps1` calls `New-CopilotGovGraphContext` (lines 335–340) but this is a STUB
- `GraphAuth.psm1` only returns a `pscustomobject` with `TenantId` and `Scopes` — no actual Graph calls
- All domain scans (`Invoke-LicensingScan`, `Invoke-IdentityScan`, etc.) return HARDCODED scores: 82, 74, 76, 84, 67, 80
- Lines 221–329: Each domain function returns test data with placeholder issues
- README Line 80: "Live Microsoft 365 and Purview API calls still require tenant-specific authentication wiring"

**Files to inspect/change:**

- `solutions/01-copilot-readiness-scanner/README.md` (Line 11)
- `solutions/01-copilot-readiness-scanner/docs/architecture.md` (Lines 68–71)
- `scripts/common/GraphAuth.psm1` (Entire file — add clarifying comment)

**Validation command:**

Grep all `Monitor-Compliance.ps1` files for live Graph invocations (should find only stub placeholders):

```powershell
grep -r "Invoke-GraphRequest|Get-MgDirectoryObject|Get-MgUser|Get-MgSubscribedSku" solutions/*/scripts/Monitor-Compliance.ps1
```

---

## Category 2: Purview/Compliance Scanning Claims vs. Actual Implementation

### Overstated: Solution 01 Scanning Claims

**Claim:** Domain scan functions perform Purview compliance scan, DLP policy coverage checks, sensitivity label reviews.

**Reality:**

- `Invoke-PurviewScan` (lines 274–290) returns hardcoded score of 84
- No actual Purview API calls; placeholder issues only
- `PurviewHelpers.psm1` only contains `New-PurviewAssessmentRecord` (creates metadata, not actual assessments)
- README Line 81: "Sensitivity label taxonomy quality cannot be fully validated from metadata alone and still requires compliance owner review"

**Files to inspect/change:**

- `solutions/01-copilot-readiness-scanner/scripts/Monitor-Compliance.ps1` (Lines 274–290)
- `scripts/common/PurviewHelpers.psm1` (add disclaimer in help)

**Validation command:**

Verify `PurviewHelpers` only builds records, doesn't scan:

```powershell
grep -n "Purview|Compliance|DLP|Label" scripts/common/PurviewHelpers.psm1
```

---

## Category 3: Automation & Deployment Stubs Mischaracterized

### Overstated: Solution 11 Deployment Claims

<!-- fsi-lang:allow="sequences license assignment" reason="audit document quotes overstated phrasing verbatim to recommend correction" -->
**Claim:** "Risk-tiered Rollout Automation sequences Copilot license assignment" with "License Assigner" and "wave orchestration."

**Status Header:** "Detailed design and deployment stubs"

**Reality:**

- `Deploy-Solution.ps1` is a manifest generator, NOT a deployment orchestrator
- Lines 28, 289: Scripts are "documentation-first implementation stub" and "does not call Microsoft Graph directly"
- `TriggerLicenseAssignment` switch stages actions but never executes them
- No actual license assignments occur
- Power Automate flows are "documented as the approval layer" but not deployed

**Files to inspect/change:**

- `solutions/11-risk-tiered-rollout/README.md` (Lines 3, 9, 27–28, 123–126)
- `solutions/11-risk-tiered-rollout/docs/architecture.md` (Lines 22–47 — architecture diagram)
- `solutions/11-risk-tiered-rollout/scripts/Deploy-Solution.ps1` (Line 10 — clarify in help)

**Validation command:**

Search for live license assignment code (should find zero):

```powershell
grep -r "Set-MgUserLicense|Update-MgDirectorySettingTemplate" solutions/11*/scripts/
```

---

## Category 4: Dashboard Aggregation & Power BI Claims

### Overstated: Solution 12 "Dashboard" Claims

**Claim:** "Regulatory Compliance Dashboard aggregates evidence from upstream solutions into…Power BI."

**Reality:**

- README Line 114: "Power BI assets are documentation-led in this repository; the `.pbix` and `.pbit` binaries are intentionally not stored here"
- `Deploy-Solution.ps1` generates Dataverse table stubs and seed JSON, not actual connections
- `RCD-EvidenceAggregator` and `RCD-FreshnessMonitor` flows are documented but not created by scripts
- Dataverse writes are described but not invoked (no Dataverse API calls in scripts)

**Files to inspect/change:**

- `solutions/12-regulatory-compliance-dashboard/README.md` (Lines 8, 35–36, 112–116)
- `solutions/12-regulatory-compliance-dashboard/docs/architecture.md` (Lines 5–7, 58–76)
- `solutions/12-regulatory-compliance-dashboard/scripts/Deploy-Solution.ps1` (Lines 8–9 help text)

**Validation command:**

Check for actual Dataverse CRUD operations:

```powershell
grep -r "New-DataverseRecord|Update-DataverseTable|Invoke-DataverseAPI" solutions/12*/scripts/
```

---

## Category 5: Service Health Polling & DORA Monitoring

### Partially Accurate but Clarification Needed: Solution 13 Service Health Claims

**Claim (Architecture.md Line 54):** "Microsoft Graph service communications…retrieves Microsoft 365 service-health records."

**Reality:**

- `Monitor-Compliance.ps1` includes comment: "The repository implementation uses a local stub for the Microsoft Graph call so the script remains testable"
- Line 65: "Service Health Poller" is described as polling but implementation is stub-only
- No actual endpoint call in v0.1.0
- README Line 100: "DRM is primarily a monitoring and evidence solution"
- Limits section (Lines 100–104): "Control 2.7 remains monitor-only until tenant geo settings…are connected"; "Control 4.11 remains monitor-only until a Microsoft Sentinel…is provisioned outside this solution"

**Files to inspect/change:**

- `solutions/13-dora-resilience-monitor/README.md` (Lines 100–104)
- `solutions/13-dora-resilience-monitor/scripts/Monitor-Compliance.ps1` (Lines 1–39 help text should clarify stub nature)
- `solutions/13-dora-resilience-monitor/docs/architecture.md` (Lines 54–65 Service Health Poller section)

**Validation command:**

Verify no live Graph health calls:

```powershell
grep -r "ServiceHealth.Read|healthOverviews|Invoke-MgGraphRequest" solutions/13*/scripts/
```

---

## Category 6: Shared Module Stub Semantics Not Clarified

### Missing Disclaimer: Shared Module Functions as Stubs

**Files to inspect/change:**

1. **`GraphAuth.psm1`**
   - Function: `New-CopilotGovGraphContext`
   - Current: Returns metadata object only
   - Issue: Help text absent; implies Graph connection created
   - Fix: Add help with `.DESCRIPTION` clarifying this is a context stub

2. **`EvidenceExport.psm1`**
   - Lines 247–331: `Export-SolutionEvidencePackage`
   - Issue: Refers to artifact paths but doesn't validate actual data collection
   - Validation: `Test-CopilotGovEvidencePackage` (lines 121–244) only validates schema/hash, not data freshness

3. **`IntegrationConfig.psm1`**
   - Status scores (lines 9–15) map control status to numbers, but source solutions don't actually execute controls
   - Issue: Scores imply validated implementation state, but upstream scripts provide no real control evidence

4. **`DataverseHelpers.psm1`**
   - `New-DataverseTableContract`: Creates contract only, no table creation or API call
   - Issue: Name implies operational table, but it's metadata only

5. **`PurviewHelpers.psm1`**
   - `New-PurviewAssessmentRecord`: Creates record structure only
   - Issue: Implies assessment occurred; no actual Purview scan

---

## Category 7: Existing Tests — What They Validate & Gaps

### Tests DO Validate

- ✓ File structure and presence (all solutions)
- ✓ Configuration JSON valid and contains expected fields
- ✓ PowerShell syntax errors
- ✓ SHA-256 hashing functions (`EvidenceExport.psm1`)
- ✓ Evidence schema compliance (`validate-evidence.ps1`)

### Tests DO NOT Validate

- ✗ Live API connectivity or actual data collection
- ✗ Graph scanning actually occurs (vs. stub)
- ✗ Dataverse operations execute
- ✗ Power Automate flows deployment
- ✗ Service health polling executes
- ✗ Data freshness or quality

**Test files:**

- `solutions/01-copilot-readiness-scanner/tests/01-copilot-readiness-scanner.Tests.ps1`
- `solutions/12-regulatory-compliance-dashboard/tests/12-regulatory-compliance-dashboard.Tests.ps1`
- `solutions/13-dora-resilience-monitor/tests/13-dora-resilience-monitor.Tests.ps1`
- `scripts/validate-evidence.ps1` (repository-wide evidence validation)

---

## Category 8: Recommended Validation Commands

### 1. Semantic Audit — Claims vs. Reality

Find all `Monitor-Compliance.ps1` actual data sources:

```powershell
Get-ChildItem -Path solutions/*/scripts/Monitor-Compliance.ps1 -Recurse |
  ForEach-Object {
    Write-Host "=== $_ ==="
    Select-String -Path $_ -Pattern 'Invoke-Graph|Get-Mg|Invoke-RestMethod.*graph'
  }
```

**Expected:** Only stub/placeholder patterns (`New-CopilotGovGraphContext`, mock data returns).

### 2. Dataverse Write Validation

Search for actual Dataverse operations:

```powershell
Get-ChildItem -Path solutions/*/scripts/*.ps1 -Recurse |
  Select-String -Pattern 'New-CrmRecord|Update-CrmRecord|Set-Dataverse|Invoke-DataverseAPI|DataverseClient'
```

**Expected:** Results should reference documentation only, not live operations.

### 3. Power Automate Deployment Validation

Check for flow deployment code:

```powershell
Get-ChildItem -Path solutions/*/scripts/*.ps1 -Recurse |
  Select-String -Pattern 'New-AdminFlow|New-PowerAutomateFlow|Publish-Solution|pac flow create'
```

**Expected:** Zero results (all flows are documentation-first).

### 4. Purview/Compliance Scanning Validation

Search for Purview API calls:

```powershell
Get-ChildItem -Path solutions/*/scripts/*.ps1 -Recurse |
  Select-String -Pattern 'Purview|Compliance|DLP|Get-Label|Invoke-Purview'
```

**Expected:** Only `PurviewHelpers` module references, no actual API calls.

### 5. License Assignment Validation

Search for license assignment code:

```powershell
Get-ChildItem -Path solutions/*/scripts/*.ps1 -Recurse |
  Select-String -Pattern 'Set-MgUserLicense|Assign-License|Update-.*License'
```

**Expected:** Zero results for solution 11 (orchestration only, no actual assignment).

### 6. Service Health Polling Validation

Search for Graph health endpoint calls:

```powershell
Get-ChildItem -Path solutions/*/scripts/*.ps1 -Recurse |
  Select-String -Pattern 'healthOverviews|serviceHealth|health.*endpoint'
```

**Expected:** Architecture documentation only, no live calls in v0.1.0.

---

## Category 9: Smoke Check / Runtime Enforcement Gaps

### Current Validation Depth

- ✓ Syntax checking
- ✓ JSON schema validation
- ✓ Hash integrity verification
- ✓ File structure

### Missing Validation

- ✗ "Freshness check" tests — validates that evidence was actually collected vs. hardcoded/stub
- ✗ "Implementation verification" — confirms stub functions aren't called as if they're live
- ✗ "Data quality audit" — ensures monitoring output reflects real collection, not test data
- ✗ "Dependency binding" — confirms Dataverse, Power Automate, Power BI are actually connected

### Recommended Test Extensions

**File 1: Create `scripts/validate-implementation-depth.ps1`**

```powershell
# New validation to detect oversold features
# Check: All domain scan functions return non-placeholder data
# Check: No hardcoded test scores appear in regulated tier
# Check: Service health polling actually queries Graph
# Check: Dataverse writes are executed, not stubbed
# Check: Evidence artifacts contain real data, not template examples
```

**File 2: Extend all solution tests to include "liveness check"**

```powershell
# In each solution's .Tests.ps1:
It 'monitor-compliance provides real data, not stubbed scores' {
  # Run Monitor-Compliance in test mode
  # Validate output contains non-test tenant data
  # For baseline tier, allows mock; regulated tier must validate real collection
}

It 'export-evidence produces real artifact, not template' {
  # Run Export-Evidence
  # Parse artifact JSON
  # Validate metadata.exportedAt is recent
  # Validate artifacts array is non-empty and references real files
}
```

**File 3: Create smoke check for service dependencies**

```powershell
# Validate Dataverse connectivity when tier=regulated
# Validate Power BI dataset refresh schedule is configured
# Validate Power Automate flows are published (not just documented)
```

---

## Category 10: Implementation Map & Action Items

### Priority 1: README Claim Accuracy (High Risk)

| File | Issue | Action | Severity |
|------|-------|--------|----------|
| `solutions/01-copilot-readiness-scanner/README.md` | Line 11 overstates "Graph API-based scanning" | Clarify: "Provides structure for Graph scanning; current version uses test data" | HIGH |
| `solutions/04-finra-supervision-workflow/README.md` | Line 7 uses "routing" as if live (but actually docs-first) | Already accurate (says "documentation-first") | OK |
| `solutions/11-risk-tiered-rollout/README.md` | Line 9 implies license assignment occurs | Clarify: "Stages manifest for license assignment; requires manual execution" | HIGH |
| `solutions/12-regulatory-compliance-dashboard/README.md` | Line 8 implies "aggregates evidence" into Power BI | Clarify: "Documents aggregation pattern; Power BI assets are documentation-first" | HIGH |
| `solutions/13-dora-resilience-monitor/README.md` | Line 20 says "Captures workload health snapshots through Graph" | Clarify: "Designed for service health polling; v0.1.0 uses stub data" | MEDIUM | <!-- fsi-lang:allow="captures snapshots through graph" reason="audit row quotes overstated phrasing for recommended correction" -->

### Priority 2: Architecture Documentation Accuracy

| File | Section | Issue | Action |
|------|---------|-------|--------|
| `solutions/01-*/docs/architecture.md` | Lines 68–71 Data Flow | Claims "call Microsoft Graph…Purview-aligned services" | Revise to: "Script structure supports Graph/Purview calls; current version uses sample data" |
| `solutions/12-*/docs/architecture.md` | Lines 20–77 Power Automate Flows | Describes RCD-EvidenceAggregator/Monitor as if deployed | Confirm already documents as "described here…not deployed automatically" |
| `solutions/13-*/docs/architecture.md` | Lines 54–65 Service Health Poller | Implies polling occurs | Add: "v0.1.0 includes polling structure; Graph integration not yet wired" |

### Priority 3: Shared Module Help Text

| File | Function | Action |
|------|----------|--------|
| `scripts/common/GraphAuth.psm1` | `New-CopilotGovGraphContext` | Add comment: "Returns context structure; actual authentication deferred to caller implementation" |
| `scripts/common/DataverseHelpers.psm1` | `New-DataverseTableContract` | Add comment: "Defines table schema; does not create tables or execute Dataverse operations" |
| `scripts/common/PurviewHelpers.psm1` | `New-PurviewAssessmentRecord` | Add comment: "Creates record structure for assessment; does not invoke Purview scan" |
| `scripts/common/IntegrationConfig.psm1` | All functions | Add preamble: "Shared configuration for FSI solutions; supports stub implementations in repository state" |

### Priority 4: Test Expansion

| File | New Test | Purpose |
|------|----------|---------|
| `solutions/01-*/tests/*.Tests.ps1` | "Monitoring output is non-placeholder" | Verify domain scan results are not hardcoded test scores in regulated tier |
| `solutions/12-*/tests/*.Tests.ps1` | "Dataverse connectivity validated" | For regulated tier, confirm actual Dataverse operations (not just manifest) |
| `solutions/13-*/tests/*.Tests.ps1` | "Service health polling exercises Graph stub" | Verify polling function is called; results are testable even if Graph not live |
| `scripts/validate-evidence.ps1` | "Evidence artifacts are fresh, not template" | Check `metadata.exportedAt` is within 24h of current time |

### Priority 5: Documentation Clarifications

| File | Clarification Needed |
|------|---------------------|
| `docs/README.md` (root) | Add "Implementation Depth" section clarifying which solutions are live vs. stubs |
| `DEPLOYMENT-GUIDE.md` | Add "Connectivity Readiness" section listing which solutions require Graph/Dataverse/Power BI binding |
| `docs/architecture.md` (root) | Diagram showing which solutions actually deploy vs. which are documentation-first |

---

## Summary Table: Overstated Semantics by Solution

| Solution | False/Overstated Claim | Current State | Recommended Language |
|----------|------------------------|---------------|----------------------|
| 01 | "Performs Graph API-based scanning" | Stub with test data | "Provides scanning framework; current version uses sample data for testing" | <!-- fsi-lang:allow="performs graph api scanning" reason="audit row quotes overstated phrasing for recommended correction" -->
| 04 | "Routes flagged communications" | Documentation-first flows | ACCURATE (already labeled doc-first) |
| 11 | "Sequences Copilot license assignment" | Manifest generator | "Prepares wave manifests; requires manual license assignment" | <!-- fsi-lang:allow="sequences license assignment" reason="audit row quotes overstated phrasing for recommended correction" -->
| 12 | "Aggregates evidence into Power BI" | Dataverse schema + doc-first flows | "Documents aggregation pattern; Power BI bindings are customer-deployed" | <!-- fsi-lang:allow="aggregates evidence into power bi" reason="audit row quotes overstated phrasing for recommended correction" -->
| 13 | "Monitors M365 service health" | Stub with test data | "Provides monitoring structure; v0.1.0 includes Graph integration points" |

---

## Validation Commands Summary

To run all recommended validations:

```powershell
# 1. Syntax check (existing)
Invoke-Pester solutions/*/tests -Show All

# 2. Evidence validation (existing)
.\scripts\validate-evidence.ps1 -ConfigurationTier regulated

# 3. NEW: Check for live API calls
Get-ChildItem -Path solutions/*/scripts/*.ps1 -Recurse |
  Select-String -Pattern 'Invoke-GraphRequest|Get-Mg\w+|New-AdminFlow|Set-DataverseRecord' |
  ForEach-Object { Write-Host "POSSIBLE LIVE CALL: $_" }

# 4. NEW: Verify hardcoded test scores in Monitor output
Get-Content solutions/*/scripts/Monitor-Compliance.ps1 |
  Select-String -Pattern 'BaseScore [0-9]{2}|Score = [0-9]{2}' |
  ForEach-Object { Write-Host "STUB DATA: $_" }

# 5. NEW: Check evidence package freshness
Get-ChildItem -Path solutions/*/artifacts/*-evidence.json |
  ForEach-Object {
    $json = Get-Content $_ | ConvertFrom-Json
    $age = New-TimeSpan -Start $json.metadata.exportedAt -End (Get-Date)
    if ($age.TotalHours -gt 24) { Write-Host "STALE: $_ ($($age.TotalHours)h old)" }
  }
```

---

*END OF AUDIT*
