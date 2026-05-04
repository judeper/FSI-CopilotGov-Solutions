# Sensitivity Label Coverage Auditor

> **Status:** Documentation-first scaffold | **Version:** v0.2.1 | **Priority:** P1 | **Track:** A

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Sensitivity Label Coverage Auditor measures how much in-scope content is actually protected by Microsoft Purview sensitivity labels across SharePoint, OneDrive, and Exchange. It identifies the unlabeled gap that can still be surfaced to Microsoft 365 Copilot, calculates workload-level coverage percentages, and generates a remediation manifest that helps records, compliance, and data owners plan corrective action. The solution supports compliance with FINRA 4511, SEC 17a-4, GDPR, and GLBA 501(b) by producing repeatable evidence of classification coverage and highlighting where regulated content remains unlabeled.

## Features

- Calculates label coverage percentage by workload for SharePoint, OneDrive, and Exchange.
- Detects unlabeled content containers and records where Copilot exposure risk remains elevated.
- Checks alignment with the FSI label taxonomy from Public through Restricted.
- Analyzes auto-labeling policy gaps, including the daily 100,000 file processing cap.
- Generates a remediation manifest that ranks unlabeled sites, drives, and mailboxes for action.
- Documents Power Automate alerting patterns for label gap notifications and remediation approvals.

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft Purview APIs (scripts use representative sample data)
- ❌ Does not scan sensitivity label taxonomy live
- ❌ Does not deploy Power Automate flows (flow designs are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

> **Data classification:** See [Data Classification Matrix](../../docs/reference/data-classification.md) for residency, retention, and data-class metadata.

## Architecture Reference

See `docs\architecture.md` for the component diagram, Graph data flow, workload coverage model, gap prioritization formula, and Power Automate flow design.

## Prerequisites

- Sensitivity label taxonomy is finalized in Microsoft Purview.
- Microsoft 365 E5/A5/G5, Microsoft Purview Suite, or Microsoft 365 Information Protection and Governance licensing is confirmed for the target tenant where sensitivity labeling features are used.
- Microsoft Graph permissions distinguish delegated label enumeration (`InformationProtectionPolicy.Read`) from application label enumeration (`InformationProtectionPolicy.Read.All`), and tenant plans note that organization label definition enumeration currently uses Microsoft Graph beta.
- SharePoint and OneDrive label extraction uses approved `Files.Read.All`; any approved bulk assignment scenario also needs protected API validation plus `Files.ReadWrite.All` or `Sites.ReadWrite.All`.
- `01-copilot-readiness-scanner` baseline outputs are complete.
- `02-oversharing-risk-assessment` initial findings are available for cross-reference.
- See `docs\prerequisites.md` for detailed requirements.

## Quick Start

### Prerequisites Check

- [ ] All prerequisites above are confirmed.

### Initial Execution

1. Review `docs\prerequisites.md` and `docs\deployment-guide.md`.
2. Confirm the label taxonomy matches the FSI tier model before starting the audit.
3. Update `config\default-config.json` and the selected tier file with workload scope, thresholds, and priority sites.
4. Register the deployment:

   ```powershell
   .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId "<tenant-id>"
   ```

5. Run the first coverage scan:

   ```powershell
   .\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId "<tenant-id>"
   ```

6. Export evidence:

   ```powershell
   .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -TenantId "<tenant-id>"
   ```

## Deployment

Deployment starts by confirming the prerequisite label taxonomy and upstream readiness outputs, then registering the solution configuration with `Deploy-Solution.ps1`. After registration, run `Monitor-Compliance.ps1` to capture the initial workload coverage baseline, review the remediation manifest with records and compliance owners, and use `Export-Evidence.ps1` to publish the evidence package for audit support.

## Solution Components

| Path | Purpose |
|------|---------|
| `README.md` | Operational overview, dependencies, controls, evidence expectations, and limitations |
| `config\default-config.json` | Shared solution metadata, workload defaults, taxonomy definitions, and coverage thresholds |
| `config\baseline.json` | Minimum viable governance settings for an initial SharePoint-focused rollout |
| `config\recommended.json` | Production-oriented workload coverage and alerting defaults |
| `config\regulated.json` | Examiner-ready settings with seven-year retention and immutable evidence assumptions |
| `scripts\Deploy-Solution.ps1` | Deployment registration stub that validates prerequisites and snapshots the active taxonomy |
| `scripts\Monitor-Compliance.ps1` | Coverage monitoring stub that calculates label metrics and generates gap findings |
| `scripts\Export-Evidence.ps1` | Evidence packaging stub that writes JSON artifacts and SHA-256 companion files |
| `docs\architecture.md` | Detailed component architecture, data flow, prioritization model, and integrations |
| `docs\deployment-guide.md` | Step-by-step deployment, initial scan, remediation planning, and rollback guidance |
| `docs\evidence-export.md` | Evidence artifact definitions, control mapping, and retention guidance |
| `docs\prerequisites.md` | Licensing, role, module, permission, and upstream dependency requirements |
| `docs\troubleshooting.md` | Common errors, root causes, and operational tips for large-tenant scans |
| `tests\03-sensitivity-label-auditor.Tests.ps1` | Pester validation for structure, configuration, controls, and script parsing |

## Dependencies

This solution depends on upstream data from the following solutions and they must run first:

1. `01-copilot-readiness-scanner` to establish tenant readiness, workload scope, and rollout posture.
2. `02-oversharing-risk-assessment` to identify high-risk containers that should be prioritized when unlabeled content is found.

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../docs/reference/control-coverage-honesty.md)):
> 4 control(s) are **evidence-export-ready** in scaffold form: 1.5, 2.2, 3.11, 3.12.

| Control | Status | How this solution supports the control |
|---------|--------|----------------------------------------|
| 1.5 | Partial | Measures how well the deployed label taxonomy is applied across workloads and captures taxonomy snapshots for review, while the taxonomy approval step remains manual. |
| 2.2 | Monitor-only | Reports where Copilot-facing content is labeled versus unlabeled and highlights drift in content classification coverage. |
| 3.11 | Partial | Produces records that support classification review for books-and-records sensitive repositories, including regulated SharePoint sites and mailboxes. |
| 3.12 | Monitor-only | Automates evidence collection and packaging, while formal attestation and sign-off remain manual governance activities. |

## Regulatory Alignment

- **FINRA 4511:** supports compliance with records supervision by showing whether regulated repositories are classified and by preserving evidence of label coverage review.
- **SEC 17a-4:** supports compliance with retention and audit preparation by producing exportable coverage reports and remediation manifests for supervised repositories.
- **GDPR:** supports data protection by identifying personal data stores that remain unlabeled or insufficiently classified.
- **GLBA 501(b):** supports safeguarding obligations by tracking whether customer financial information is placed under the correct sensitivity controls.

## Evidence Export

Evidence exports align to `..\..\data\evidence-schema.json` and include the following outputs:

- `label-coverage-report`
- `label-gap-findings`
- `remediation-manifest`

Each exported JSON file receives a companion `.sha256` file, and the package summary records status, counts, controls, and artifact paths.

## Power Automate Note

Power Automate is documentation-first in this version. The solution documents two flows, `LabelGapAlert` and `RemediationManifestApproval`, but does not automatically deploy them. Teams should use the documented design to implement tenant-approved flows that match local notification, approval, and change-management processes.

## Known Limitations

- Microsoft Purview auto-labeling policies can process a maximum of 100,000 files per day per tenant, so large FSI tenants usually need staged remediation waves or supplementary automation.
- The `assignSensitivityLabel` API is a protected SharePoint and OneDrive Microsoft Graph API for files at rest; approved bulk application scenarios require protected API validation beyond permission consent, least-privileged `Files.ReadWrite.All` or `Sites.ReadWrite.All`, long-running operation handling, and use in the Global service, which Microsoft Learn lists as the documented available cloud for this API.
- Exchange coverage can lag if required message-level label metadata is not consistently exposed through the chosen collection method.
- This version focuses on monitoring, evidence production, and remediation planning; it does not claim automatic enforcement across every workload.
- Microsoft is replacing parent labels with label groups. Migration is irreversible; automatic migration applies only in documented cases, and other tenants should migrate when the Microsoft Purview portal banner is available. The solution's taxonomy snapshot should be updated to record label group membership after migration.
- Service-side auto-labeling can now override existing lower-priority labels on files (previously only emails). Remediation manifests should account for this capability.
