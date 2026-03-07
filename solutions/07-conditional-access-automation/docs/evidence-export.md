# Evidence Export

## Overview

`Export-Evidence.ps1` produces the Conditional Access evidence set for Copilot access governance. All evidence artifacts are written as JSON and paired with SHA-256 companion files so the package can be validated after collection.

## Evidence package contents

The export produces the following files in the selected output path:

- `ca-policy-state.json`
- `ca-policy-state.json.sha256`
- `drift-alert-summary.json`
- `drift-alert-summary.json.sha256`
- `access-exception-register.json`
- `access-exception-register.json.sha256`
- `07-conditional-access-automation-evidence.json`
- `07-conditional-access-automation-evidence.json.sha256`

The shared evidence package aligns to `data\evidence-schema.json` and includes:

- `metadata`
- `summary`
- `controls`
- `artifacts`

## Artifact details

| Artifact | Purpose | Key fields |
|----------|---------|------------|
| `ca-policy-state.json` | Snapshot of Conditional Access policies targeting Copilot applications | `targetedAppIds`, `policies`, `grantControls`, `conditions`, `configurationTier` |
| `drift-alert-summary.json` | Policy changes detected since the approved baseline | `driftDetected`, `changeCount`, `changes`, `severity`, `changeDescription` |
| `access-exception-register.json` | Approved exceptions to the Copilot Conditional Access baseline | `exceptions`, `approver`, `approvalDate`, `businessJustification`, `expiryDate` |

## Control mapping and regulatory notes

The evidence package includes the following control entries:

- `2.3` for access control posture and Copilot-targeting Conditional Access enforcement.
- `2.6` for change oversight, exception governance, and policy drift monitoring.
- `2.9` for compliant-device expectations in tiers that require device controls.

Regulatory notes should state that the evidence supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9. Avoid absolute compliance claims.

## Retention guidance

Retention expectations are tier-specific:

- `baseline`: 30 days
- `recommended`: 90 days
- `regulated`: 365 days or longer if the operating standard requires it

## Example export command

```powershell
pwsh -File .\solutions\07-conditional-access-automation\scripts\Export-Evidence.ps1 `
    -ConfigurationTier regulated `
    -OutputPath .\solutions\07-conditional-access-automation\artifacts\regulated `
    -BaselinePath .\solutions\07-conditional-access-automation\artifacts\regulated\current-policy-baseline.json `
    -ExceptionRegisterPath .\solutions\07-conditional-access-automation\artifacts\regulated\access-exception-register.json `
    -PeriodStart 2026-03-01 `
    -PeriodEnd 2026-03-31
```

## Validation notes

- Validate each `.sha256` companion before transmitting evidence.
- Confirm that app IDs in `ca-policy-state.json` match the approved Copilot targets.
- Investigate all medium or high severity drift findings before closing the review period.
- Review exceptions for expiry and supervisory approval before packaging evidence.
