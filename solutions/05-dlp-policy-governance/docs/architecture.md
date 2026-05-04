# Architecture

## Purpose

DLP Policy Governance for Copilot provides a read-only architecture for baseline capture, drift monitoring, exception approval, and evidence export. The design supports compliance with privacy and operational resiliency requirements by documenting how Microsoft 365 Copilot and Copilot Chat policy-location settings and separate complementary workload DLP baselines are reviewed over time.

## Components

| Component | Type | Responsibility |
|-----------|------|----------------|
| `Deploy-Solution.ps1` | PowerShell | Creates the baseline snapshot template, deployment manifest, and connection stubs for Graph and Exchange Online |
| `Monitor-Compliance.ps1` | PowerShell | Compares the stored baseline to the current tier definition, reviews Copilot policy-location and complementary workload records, and writes drift findings |
| `Export-Evidence.ps1` | PowerShell | Packages evidence artifacts, writes SHA-256 companions, and creates the evidence manifest |
| Exception Approval Flow | Power Automate | Routes policy exception requests, records approvals, and feeds attestation data into evidence exports |
| Microsoft Purview DLP and Security and Compliance PowerShell | Service interface | Supplies DLP policy metadata for the Microsoft 365 Copilot and Copilot Chat policy location and for separate complementary workload DLP policies |
| Microsoft Graph | Service interface | Supplies policy and label metadata used to validate Copilot-related DLP expectations |

## Data flow

```text
Purview DLP policy metadata
  |-- Microsoft 365 Copilot and Copilot Chat policy location
  |-- Complementary workload DLP locations in separate policies
        |
        v
Deploy-Solution.ps1 -> dlp-policy-baseline.json
        |
        v
Monitor-Compliance.ps1 -> policy-drift-findings.json
        |
        v
Power Automate exception approval flow -> exception-attestations.json
        |
        v
Export-Evidence.ps1 -> 05-dlp-policy-governance-evidence.json + .sha256 files
```

## Processing sequence

1. `Deploy-Solution.ps1` loads the selected tier configuration and creates a structured DLP policy baseline template.
2. Security and compliance operators replace or enrich the template with live Purview output when tenant connectivity is available.
3. `Monitor-Compliance.ps1` compares the stored baseline to the current tier expectations for Copilot policy-location capabilities, separate complementary workload records, policy mode alignment, and exception-handling settings.
4. Drift findings are written to `policy-drift-findings.json` for review and escalation.
5. The Power Automate exception flow routes approved deviations to the required approver and records attestation details.
6. `Export-Evidence.ps1` assembles the baseline, drift findings, and exception attestations into an evidence package aligned to `data\evidence-schema.json`.

## Dataverse naming pattern

If Dataverse is used for durable storage, table names should follow the shared contract:

- `fsi_cg_dpg_baseline`
- `fsi_cg_dpg_finding`
- `fsi_cg_dpg_evidence`

## Security and operational notes

- PowerShell collection is read-only and does not create or modify DLP policies.
- The Power Automate flow is documentation-first in this repository and must be connected to tenant-specific identities before production use.
- Tier-specific controls determine whether exceptions are optional, required, or subject to senior compliance approval.
- Evidence retention, notification behavior, and drift thresholds are controlled through the tier configuration files.
