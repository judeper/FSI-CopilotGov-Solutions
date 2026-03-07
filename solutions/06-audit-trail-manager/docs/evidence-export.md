# Evidence Export

## Overview

`Export-Evidence.ps1` produces a regulator-ready JSON package aligned to `data\evidence-schema.json`. The script also writes SHA-256 companion files for each JSON artifact.

## Artifact: audit-log-completeness.json

This artifact records:

- UAL enabled check status.
- Required audit level and selected tier.
- Copilot event types captured: `CopilotInteraction` and `AIInteraction`.
- Supporting event types captured for operational context, such as `SharePointFileAccess`.
- Sample counts by event type.
- Validation window and notes on possible UAL latency.

## Artifact: retention-policy-state.json

This artifact records:

- Active retention policies expected for the selected tier.
- Retention labels and label coverage expectations.
- Retention periods by regulation.
- WORM documentation and immutable storage attestation flags for regulated deployments.
- Policy gap notes for any configured value below the regulatory minimum.

## Artifact: ediscovery-readiness-package.json

This artifact records:

- Case count.
- Hold count.
- Custodian count.
- Preservation status.
- Case template and scope.
- Readiness notes for legal hold ownership and production support.

## Package structure

A complete export contains:

- `06-audit-trail-manager-evidence.json`
- `06-audit-trail-manager-evidence.json.sha256`
- `audit-log-completeness.json`
- `audit-log-completeness.json.sha256`
- `retention-policy-state.json`
- `retention-policy-state.json.sha256`
- `ediscovery-readiness-package.json`
- `ediscovery-readiness-package.json.sha256`

## Control mapping

| Control | Evidence note |
|---------|---------------|
| 3.1 | `audit-log-completeness.json` captures required UAL event scope and validation notes |
| 3.2 | `retention-policy-state.json` compares configured days to regulatory minimums |
| 3.3 | `ediscovery-readiness-package.json` records case, hold, custodian, and preservation expectations |
| 3.11 | Retention labels and policy coverage are documented in the retention state artifact |
| 3.12 | Notification mode and exception-handling notes are included in the evidence package summary |
