# DLP Policy Governance for Copilot

> **Status:** Documentation-first scaffold | **Version:** v0.2.1 | **Priority:** P1 | **Track:** B

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

DLP Policy Governance for Copilot deploys a read-only governance pattern for Microsoft Purview Data Loss Prevention policy review scoped to the Microsoft 365 Copilot and Copilot Chat policy location. It documents baseline expectations for supported Copilot DLP capabilities, compares those expectations to a stored baseline, routes approved exceptions through a Power Automate approval flow, and exports evidence for compliance review. It also lets teams track separate complementary workload DLP baselines where tenant policy design uses Exchange, SharePoint, OneDrive, Teams, devices, or endpoint locations outside the Copilot policy location.

This solution supports compliance with GLBA 501(b), SEC Regulation S-P, DORA Article 9 ICT security expectations, GDPR, FINRA Rule 4511, and SOX 302/404 by helping security and compliance teams monitor how Copilot-related DLP controls are scoped, tuned, and approved over time.

> **Microsoft 365 Copilot and Copilot Chat policy location:** Microsoft Purview DLP supports **Microsoft 365 Copilot and Copilot Chat** as a dedicated policy location. The location supports sensitive-information-type prompt blocking (preview), external web-search grounding restrictions for sensitive prompts (preview), and sensitivity-label protection for supported files and emails used in Copilot response summarization (generally available). Selecting this location disables all other locations for that policy.

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../docs/reference/control-coverage-honesty.md)):
> 3 control(s) are **evidence-export-ready** in scaffold form: 2.1, 3.10, 3.12.

- 2.1 - DLP coverage for Copilot workloads and sensitive content paths
- 3.10 - Policy monitoring and drift review
- 3.12 - Evidence collection and exception attestation

## What the solution does

- Compares baseline records for the Microsoft 365 Copilot and Copilot Chat policy location and its supported conditions and actions
- Tracks separate complementary workload DLP baseline records when tenant policy design requires Exchange, SharePoint, OneDrive, Teams, devices, or endpoint locations
- Checks policy modes such as Audit and Block for expected sensitivity label handling on supported files and emails
- Documents prompt-text controls for sensitive information types, including preview status for prompt blocking and external web-search grounding restrictions
- Documents a Power Automate approval flow for policy exceptions and attestation evidence
- Exports evidence artifacts that align to `data\evidence-schema.json`

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft Purview DLP APIs (scripts compare local configuration baselines)
- ❌ Does not create or modify DLP policies (policy templates are provided for manual deployment)
- ❌ Does not deploy Power Automate flows (exception workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not configure Adaptive Protection policies (Insider Risk Management integration with DLP is documented as a complementary capability)
- ❌ Does not evaluate the contents of files uploaded directly into Copilot prompts; Microsoft Purview DLP for Copilot evaluates the prompt text itself for this scenario
- ❌ Does not combine the Microsoft 365 Copilot and Copilot Chat policy location with Exchange, SharePoint, OneDrive, Teams, or endpoint DLP locations in the same policy

> **Data classification:** See [Data Classification Matrix](../../docs/reference/data-classification.md) for residency, retention, and data-class metadata.

## Prerequisites

- Dependency `03-sensitivity-label-auditor` is complete and the latest label inventory has been reviewed
- Microsoft 365 E5 or E5 Compliance licensing is available for Purview DLP and Copilot data protection features
- Power Automate Premium is available if the exception approval flow is deployed
- Policy editors use one of the current Microsoft Learn roles for Copilot DLP policy create/edit, such as Entra AI Admin, Purview Data Security AI Admin, Purview Compliance Administrator, Purview Compliance Data Administrator, Purview Information Protection Admin, Purview Security Administrator, or Entra Global Admin
- Security Reader-style access is treated as read-only review only and is not sufficient for Copilot DLP policy create/edit
- PowerShell 7, `ExchangeOnlineManagement`, and `Microsoft.Graph` are available for read-only data collection

See [docs/prerequisites.md](docs/prerequisites.md) for details.

## DLP policy scope

This solution separates two DLP governance layers:

1. **Microsoft 365 Copilot and Copilot Chat policy location** records for supported Copilot conditions and actions. Selecting this policy location disables all other locations for the same DLP policy.
2. **Complementary workload DLP policy** records for Exchange, SharePoint, OneDrive, Teams, devices, or endpoint locations when tenant policy design uses those controls outside the Copilot policy location.

The Copilot policy-location baseline tracks:

- Sensitive information types in prompt text, including preview prompt-blocking behavior
- Sensitive information types in prompt text that restrict external web search as a grounding source during preview
- Sensitivity labels on supported files and emails used in Copilot response summarization
- Scope definitions for included and excluded user groups
- Exception handling requirements by governance tier
- Evidence retention and notification settings needed for review

## Power Automate exception flow

The repository uses a documentation-first pattern for Power Automate assets. The exception approval flow is described in the architecture and deployment guides and is intended to:

1. Receive a request when a policy owner needs a temporary DLP exception for a Copilot policy-location or complementary workload DLP baseline record.
2. Validate the request against the stored baseline and current drift findings.
3. Route the request to the required approver based on tier:
   - Baseline: service owner review when used
   - Recommended: Purview Compliance Administrator or delegated policy-owner approval
   - Regulated: senior compliance sign-off and CCO approval for policy changes
4. Record the approved exception with attestor, approval date, justification, and expiry date.
5. Feed approved records into the `exception-attestations` evidence artifact.

## Solution components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Creates the DLP baseline template, deployment manifest, and connection stubs |
| `scripts\Monitor-Compliance.ps1` | Compares baseline content to tier expectations and writes drift findings |
| `scripts\Export-Evidence.ps1` | Packages evidence artifacts and writes SHA-256 companions |
| `config\default-config.json` | Shared defaults for the Copilot policy location, supported capability identifiers, complementary workload locations, policy modes, and dataverse names |
| `config\baseline.json` | Audit-only baseline tier settings |
| `config\recommended.json` | Daily monitoring and high-sensitivity block settings |
| `config\regulated.json` | Regulated tier settings with strict attestation and approval requirements |
| `docs\*.md` | Architecture, deployment, evidence, prerequisites, and troubleshooting guidance |
| `tests\05-dlp-policy-governance.Tests.ps1` | Pester checks for required files and PowerShell syntax |

## Deployment

1. Confirm that solution `03-sensitivity-label-auditor` has produced a current label inventory.
2. Connect to Security and Compliance PowerShell and Microsoft Graph with read permissions.
3. Run `Deploy-Solution.ps1` to create the baseline template and deployment manifest.
4. Configure the Power Automate exception approval flow using the documented design.
5. Schedule `Monitor-Compliance.ps1` based on the selected tier.
6. Run `Export-Evidence.ps1` for the required reporting period and archive the resulting evidence package.

See [docs/deployment-guide.md](docs/deployment-guide.md) for detailed steps.

## Evidence Export

This solution exports the following evidence outputs:

- `dlp-policy-baseline` - JSON snapshot of Microsoft 365 Copilot and Copilot Chat policy-location expectations plus separate complementary workload DLP baselines when applicable
- `policy-drift-findings` - array of detected policy-location, capability, mode, or exception-handling drift
- `exception-attestations` - array of approved exceptions with attestor, date, and justification

Each exported file receives a `.sha256` companion and is referenced from the solution evidence package.

See [docs/evidence-export.md](docs/evidence-export.md) for package details.

## Regulatory Alignment

| Regulation or control driver | How the solution supports compliance with the requirement | Evidence output |
|------------------------------|-----------------------------------------------------------|-----------------|
| GLBA 501(b) | Helps teams monitor DLP handling for NPI that may appear in Copilot prompt text or in supported labeled files and emails used for response summarization. | `dlp-policy-baseline`, `policy-drift-findings` |
| SEC Regulation S-P | Helps document whether privacy-related policy modes and scoping remain aligned to approved standards. | `policy-drift-findings`, `exception-attestations` |
| DORA Article 9 | Helps operations teams review ICT security governance, policy changes, and exception approvals for Copilot policy-location and complementary workload DLP baselines. | `dlp-policy-baseline`, `policy-drift-findings`, `exception-attestations` |
| GDPR | Helps monitor whether personal data handling controls remain in approved DLP modes and scope definitions. | `policy-drift-findings`, `exception-attestations` |
| FINRA Rule 4511 | Helps preserve records of DLP policy configurations, exceptions, and attestations for Copilot-related communications. | `dlp-policy-baseline`, `exception-attestations` |
| SOX 302/404 | Helps document internal controls over DLP governance and policy change approvals for Copilot policy-location and complementary workload DLP baselines. | `dlp-policy-baseline`, `policy-drift-findings`, `exception-attestations` |
| Control 2.1 | Helps review Copilot DLP coverage across supported policy-location capabilities and separately tracked workload DLP baselines. | `dlp-policy-baseline`, `policy-drift-findings` |
| Control 3.10 | Tracks drift against an approved baseline and supports scheduled review. | `policy-drift-findings` |
| Control 3.12 | Records and packages exception approvals and audit evidence. | `exception-attestations` |

## Known limitations

- Some tenants expose Purview DLP metadata in read-only form only after Exchange Online and Security and Compliance sessions are connected.
- The Microsoft 365 Copilot and Copilot Chat policy location disables other DLP locations for the same policy, so workload DLP policies should be represented separately.
- DLP for Copilot does not evaluate the contents of files uploaded directly into prompts; it evaluates the typed prompt text for this scenario.
- Sensitivity-label protection for files and emails is limited to supported files in SharePoint Online or OneDrive for Business and emails sent on or after January 1, 2025; calendar invites are not supported.
- The Power Automate approval flow is documentation-led in this repository and still requires tenant-specific connection setup.
- Drift results are only as current as the latest baseline and policy snapshot available to the monitoring process.
