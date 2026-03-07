# DLP Policy Governance for Copilot

> Status: implemented | Version: v0.2.0 | Priority: P1 | Track: B

## Overview

DLP Policy Governance for Copilot deploys a read-only governance pattern for Microsoft 365 Copilot data loss prevention policy review. It snapshots Purview DLP policy settings that target Copilot prompts, Copilot responses, and grounded content access patterns, compares those settings to a stored baseline, routes approved exceptions through a Power Automate approval flow, and exports evidence for compliance review.

This solution supports compliance with GLBA 501(b), SEC Reg S-P, DORA Article 9 ICT security expectations, and GDPR by helping security and compliance teams monitor how Copilot-related DLP controls are scoped, tuned, and approved over time.

## Primary controls

- 2.1 - DLP coverage for Copilot workloads and sensitive content paths
- 3.10 - Policy monitoring and drift review
- 3.12 - Evidence collection and exception attestation

## What the solution does

- Captures a baseline snapshot of Copilot-scoped DLP policy expectations by workload and label condition
- Monitors drift between the stored baseline and the current governance tier definition
- Checks policy modes such as Audit and Block for expected sensitivity label handling
- Validates workload coverage for Teams, SharePoint, OneDrive, and Exchange
- Documents a Power Automate approval flow for policy exceptions and attestation evidence
- Exports evidence artifacts that align to `data\evidence-schema.json`

## Prerequisites

- Dependency `03-sensitivity-label-auditor` is complete and the latest label inventory has been reviewed
- Microsoft 365 E5 or E5 Compliance licensing is available for Purview DLP and Copilot data protection features
- Power Automate Premium is available if the exception approval flow is deployed
- Operators have Compliance Administrator, Security Reader, or DLP Compliance Management permissions
- PowerShell 7, `ExchangeOnlineManagement`, and `Microsoft.Graph` are available for read-only data collection

See [docs\prerequisites.md](docs\prerequisites.md) for details.

## DLP policy scope

This solution focuses on DLP policies that support Copilot governance across the following workloads:

- Teams chat and channel prompts or responses that may expose sensitive data
- SharePoint grounded content sources used by Copilot
- OneDrive grounded content sources used by Copilot
- Exchange content paths that may surface in Copilot-assisted workflows

The baseline and monitoring logic track:

- Sensitivity label conditions, including NPI and PII labels used for GLBA and privacy use cases
- Policy action modes such as Audit and Block
- Scope definitions for included and excluded user groups
- Exception handling requirements by governance tier
- Evidence retention and notification settings needed for review

## Power Automate exception flow

The repository uses a documentation-first pattern for Power Automate assets. The exception approval flow is described in the architecture and deployment guides and is intended to:

1. Receive a request when a policy owner needs a temporary DLP exception for a Copilot workload.
2. Validate the request against the stored baseline and current drift findings.
3. Route the request to the required approver based on tier:
   - Baseline: service owner review when used
   - Recommended: Compliance Administrator approval
   - Regulated: senior compliance sign-off and CCO approval for policy changes
4. Record the approved exception with attestor, approval date, justification, and expiry date.
5. Feed approved records into the `exception-attestations` evidence artifact.

## Solution components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Creates the DLP baseline template, deployment manifest, and connection stubs |
| `scripts\Monitor-Compliance.ps1` | Compares baseline content to tier expectations and writes drift findings |
| `scripts\Export-Evidence.ps1` | Packages evidence artifacts and writes SHA-256 companions |
| `config\default-config.json` | Shared defaults, workload scope, policy mode defaults, and dataverse names |
| `config\baseline.json` | Audit-only baseline tier settings |
| `config\recommended.json` | Daily monitoring and high-sensitivity block settings |
| `config\regulated.json` | Regulated tier settings with strict attestation and approval requirements |
| `docs\*.md` | Architecture, deployment, evidence, prerequisites, and troubleshooting guidance |
| `tests\05-dlp-policy-governance.Tests.ps1` | Pester checks for required files and PowerShell syntax |

## Deployment overview

1. Confirm that solution `03-sensitivity-label-auditor` has produced a current label inventory.
2. Connect to Security and Compliance PowerShell and Microsoft Graph with read permissions.
3. Run `Deploy-Solution.ps1` to create the baseline template and deployment manifest.
4. Configure the Power Automate exception approval flow using the documented design.
5. Schedule `Monitor-Compliance.ps1` based on the selected tier.
6. Run `Export-Evidence.ps1` for the required reporting period and archive the resulting evidence package.

See [docs\deployment-guide.md](docs\deployment-guide.md) for detailed steps.

## Evidence collection

This solution exports the following evidence outputs:

- `dlp-policy-baseline` - JSON snapshot of Copilot-scoped DLP policy expectations and baseline metadata
- `policy-drift-findings` - array of detected workload, mode, or exception-handling drift
- `exception-attestations` - array of approved exceptions with attestor, date, and justification

Each exported file receives a `.sha256` companion and is referenced from the solution evidence package.

See [docs\evidence-export.md](docs\evidence-export.md) for package details.

## Regulatory alignment

| Regulation or control driver | How the solution supports compliance with the requirement | Evidence output |
|------------------------------|-----------------------------------------------------------|-----------------|
| GLBA 501(b) | Helps teams monitor DLP handling for NPI that may appear in Copilot prompts, responses, or grounded content access. | `dlp-policy-baseline`, `policy-drift-findings` |
| SEC Reg S-P | Helps document whether privacy-related policy modes and scoping remain aligned to approved standards. | `policy-drift-findings`, `exception-attestations` |
| DORA Article 9 | Helps operations teams review ICT security governance, policy changes, and exception approvals for Copilot-connected workloads. | `dlp-policy-baseline`, `policy-drift-findings`, `exception-attestations` |
| GDPR | Helps monitor whether personal data handling controls remain in approved DLP modes and scope definitions. | `policy-drift-findings`, `exception-attestations` |
| Control 2.1 | Validates Copilot DLP coverage across in-scope workloads and sensitivity conditions. | `dlp-policy-baseline`, `policy-drift-findings` |
| Control 3.10 | Tracks drift against an approved baseline and supports scheduled review. | `policy-drift-findings` |
| Control 3.12 | Records and packages exception approvals and audit evidence. | `exception-attestations` |

## Known limitations

- Some tenants expose Purview DLP metadata in read-only form only after Exchange Online and Security and Compliance sessions are connected.
- Copilot-specific workload coverage can depend on Microsoft 365 E5 or E5 Compliance plus the required Copilot licensing.
- The Power Automate approval flow is documentation-led in this repository and still requires tenant-specific connection setup.
- Drift results are only as current as the latest baseline and policy snapshot available to the monitoring process.
