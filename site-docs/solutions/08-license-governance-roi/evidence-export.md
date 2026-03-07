# Evidence Export

## Evidence Package Overview

`Export-Evidence.ps1` produces a JSON evidence package aligned to `..\..\data\evidence-schema.json` and a companion `.sha256` file. The package references three supporting artifacts that document utilization, ROI signals, and reallocation actions for the selected tier.

## Artifact Schemas

### license-utilization-report

| Field | Type | Description |
|-------|------|-------------|
| `reportingPeriodStart` | string | Start date for the monitoring period. |
| `reportingPeriodEnd` | string | End date for the monitoring period. |
| `skuName` | string | Licensed SKU under review, typically Copilot for Microsoft 365. |
| `totalAssignedSeats` | integer | Number of seats assigned during the period. |
| `activeSeats` | integer | Seats with activity inside the configured inactivity threshold. |
| `inactiveSeats` | integer | Seats with no activity inside the configured threshold. |
| `utilizationPct` | number | Active seats divided by assigned seats. |
| `reallocationTriggerUtilizationPct` | number | Threshold that triggers a review or reallocation recommendation. |
| `businessUnitSummary` | array | Per-business-unit utilization summary used for management reporting. |
| `dataSources` | array | Data inputs used for the report, such as Microsoft Graph and Viva Insights. |

### roi-scorecard

| Field | Type | Description |
|-------|------|-------------|
| `reportingPeriodDays` | integer | Number of days represented in the scorecard. |
| `vivaInsightsEnabled` | boolean | Indicates whether Viva Insights signals were included. |
| `roiSignalCoveragePct` | number | Percentage of scoped users or business units with ROI evidence. |
| `estimatedHoursSaved` | number | Estimated productivity benefit from supported Copilot scenarios. |
| `estimatedCostAvoidanceUsd` | number | Estimated value signal used for management discussion, not formal accounting. |
| `businessUnitScorecard` | array | Per-business-unit ROI summary. |
| `assumptions` | array | Declared assumptions for how value signals were calculated. |

### reallocation-recommendations

| Field | Type | Description |
|-------|------|-------------|
| `userPrincipalName` | string | Copilot seat owner being reviewed. |
| `department` | string | Business unit or cost center. |
| `riskTier` | string | Risk-tier input supplied by solution `11-risk-tiered-rollout` or local exception logic. |
| `lastActivityDate` | string | Last observed Copilot activity date. |
| `utilizationPct` | number | User-level or cohort-level utilization metric used for review. |
| `recommendedAction` | string | Proposed action such as `Reallocate after manager approval`. |
| `annualizedRecoverableCostUsd` | number | Estimated annual spend that could be recovered if the seat is removed. |
| `managerApprovalRequired` | boolean | Indicates whether a manager or control owner must approve the action. |
| `reviewDueDate` | string | Date by which the recommendation should be reviewed. |

## Export Command Examples

Baseline tier:

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier baseline -OutputPath '.\artifacts\evidence\baseline'
```

Recommended tier:

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath '.\artifacts\evidence\recommended'
```

Regulated tier with SOX-oriented packaging:

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath '.\artifacts\evidence\regulated'
```

## Evidence Package Fields

| Field | Description |
|-------|-------------|
| `metadata.solution` | Solution slug `08-license-governance-roi`. |
| `metadata.solutionCode` | Abbreviated solution code `LGR`. |
| `metadata.exportVersion` | Shared evidence schema version from `IntegrationConfig.psm1`. |
| `metadata.exportedAt` | UTC timestamp for the package export. |
| `metadata.tier` | Selected governance tier. |
| `summary.overallStatus` | Overall status based on control coverage and ROI data availability. |
| `summary.recordCount` | Number of seat records or summarized records covered by the export. |
| `summary.findingCount` | Number of inactive-seat or reallocation findings identified in the export. |
| `summary.exceptionCount` | Number of recommendations that require explicit approval or exception handling. |
| `controls[]` | Control-by-control status entries and reviewer notes. |
| `artifacts[]` | Generated artifact names, types, paths, hashes, and descriptions. |

## SHA-256 Verification

The evidence package integrity check uses the companion `.sha256` file written by `EvidenceExport.psm1`.

### Validate with the shared module

```powershell
Import-Module '..\..\scripts\common\EvidenceExport.psm1' -Force
Test-EvidencePackageHash -Path '.\artifacts\evidence\recommended\08-license-governance-roi-evidence.json'
```

### Validate manually

```powershell
$expected = (Get-Content '.\artifacts\evidence\recommended\08-license-governance-roi-evidence.json.sha256').Split(' ')[0]
$actual = (Get-FileHash '.\artifacts\evidence\recommended\08-license-governance-roi-evidence.json' -Algorithm SHA256).Hash.ToLowerInvariant()
$expected -eq $actual
```

If the hashes do not match, discard the package, regenerate the export, and document the reason in the delivery log before sharing the evidence externally.
