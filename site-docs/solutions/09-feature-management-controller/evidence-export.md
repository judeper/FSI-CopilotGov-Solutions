# Evidence Export

## Evidence Objectives

FMC evidence packages are intended to show how Copilot features are inventoried, approved, monitored, and remediated over time. The exported package supports operational review, supervisory review, and downstream dashboard ingestion.

## Evidence Outputs

| Evidence artifact | Description | Typical fields | Source systems | Controls |
|-------------------|-------------|----------------|----------------|----------|
| `feature-state-baseline` | Approved baseline of Copilot feature state at the time of deployment or review. | `featureId`, `displayName`, `sourceSystem`, `expectedEnabled`, `expectedRing`, `approvalReference`, `capturedAt` | Microsoft 365 Admin Center, Graph rollout policies, Teams admin center, Power Platform Admin API | 2.6, 4.1, 4.2, 4.3 |
| `rollout-ring-history` | History of feature promotion, restriction, rollback, or exception approval. | `changeId`, `featureId`, `sourceRing`, `targetRing`, `requestedBy`, `approvedBy`, `changedAt`, `changeTicket` | Deployment summary, Power Automate flow metadata, change records | 4.3, 4.12 |
| `drift-findings` | Deviations between approved baseline and observed state, including severity and remediation status. | `findingId`, `featureId`, `driftType`, `severity`, `baselineValue`, `observedValue`, `detectedAt`, `remediationStatus` | Compliance monitor output, Dataverse findings table | 4.4, 4.12, 4.13 |

## Package Contract

- JSON package aligned to `..\..\data\evidence-schema.json`
- Companion `.sha256` file for every export
- Control status entries for `2.6`, `4.1`, `4.2`, `4.3`, `4.4`, `4.12`, and `4.13`
- Summary section that records overall status, record count, finding count, and exceptions

## Export Process

Run:

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\FMC
```

The script:

1. loads the shared evidence export module
2. builds a solution summary for FMC
3. records control implementation status with supporting notes
4. emits artifact metadata for the three evidence outputs
5. writes the package and SHA-256 hash file

## Operational Guidance

- Export evidence after baseline refresh, approved ring promotion, or scheduled monitoring cycles.
- Preserve the evidence package for the retention period defined by the selected tier.
- Review any `partial` control statuses before presenting the package as a final supervisory record.

## Interpretation Notes

- A `partial` status for control `4.4` indicates drift detection logic exists, but meaningful enforcement depends on an approved tenant baseline.
- A `partial` status for control `4.13` indicates connector and plugin risks are identified in the registry, but deeper lifecycle governance may require solution 10 or additional operational workflow.
- Evidence export supports compliance with SEC Reg FD and FINRA 3110 but does not replace supervisory review or change approval documentation.
