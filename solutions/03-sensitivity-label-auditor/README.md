# Sensitivity Label Coverage Auditor

> **Status:** Documentation-first scaffold | **Version:** v0.2.4 | **Priority:** P1 | **Track:** A | **Last Verified:** 2026-10-15

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Sensitivity Label Coverage Auditor provides a documentation-first model for measuring Microsoft Purview sensitivity label coverage across SharePoint, OneDrive, and Exchange. Label presence indicates classification, not necessarily encryption or access restriction: labels can be configured without protection settings. Unlabeled content a user can already access may be eligible for Microsoft 365 Copilot use, subject to applicable permissions, encryption, DLP, and experience-specific controls; label absence alone does not establish exposure. The sample scripts calculate workload-level coverage percentages and generate a remediation manifest that helps records, compliance, and data owners plan corrective action. The solution supports compliance with FINRA 4511, SEC 17a-4, GDPR, and GLBA 501(b) by producing repeatable evidence of classification coverage and highlighting where regulated content remains unlabeled.

## Features

- Calculates label coverage percentage by workload for SharePoint, OneDrive, and Exchange.
- Detects unlabeled content containers and records where Copilot exposure risk remains elevated.
- Checks alignment with the FSI label taxonomy from Public through Restricted.
- Models auto-labeling policy gaps against the currently documented ceiling of 500,000 automatically labeled files per tenant per day, not a guaranteed processing rate.
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
- Licensing is confirmed for each sensitivity-labeling capability and benefiting user. Client- and service-side automatic labeling require eligible E5/P2-tier entitlements; verify the exact current SKU and base-license requirements in the Microsoft Purview service description.
- Microsoft Graph permissions distinguish delegated user label enumeration (`InformationProtectionPolicy.Read`) from application enumeration (`InformationProtectionPolicy.Read.All`). The organization route `/security/informationProtection/sensitivityLabels` requires application permissions; label definition enumeration remains beta, which Microsoft does not support in production applications.
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
- **SEC 17a-3:** helps meet books-and-records inventory expectations by documenting classification coverage for supervised repositories and mailboxes.
- **SEC 17a-4:** supports compliance with retention and audit preparation by producing exportable coverage reports and remediation manifests for supervised repositories.
- **SEC Reg S-P:** supports privacy safeguard review by highlighting customer-information stores that remain unlabeled or insufficiently classified.
- **GDPR:** supports data protection by identifying personal data stores that remain unlabeled or insufficiently classified.
- **GLBA 501(b):** supports safeguarding obligations by tracking whether customer financial information is placed under the correct sensitivity controls.
- **SOX 302/404:** helps meet management attestation and internal-control evidence needs by preserving repeatable classification coverage outputs for financial reporting repositories.
- **FFIEC IT Handbook:** supports information security governance review by mapping label coverage evidence to data classification and access control expectations.

## Evidence Export

Evidence exports align to `..\..\data\evidence-schema.json` and include the following outputs:

- `label-coverage-report`
- `label-gap-findings`
- `remediation-manifest`

Each exported JSON file receives a companion `.sha256` file, and the package summary records status, counts, controls, and artifact paths.

## Power Automate Note

Power Automate is documentation-first in this version. The solution documents two flows, `LabelGapAlert` and `RemediationManifestApproval`, but does not automatically deploy them. Teams should use the documented design to implement tenant-approved flows that match local notification, approval, and change-management processes.

## Microsoft Learn Sources

- [driveItem: assignSensitivityLabel](https://learn.microsoft.com/graph/api/driveitem-assignsensitivitylabel?view=graph-rest-1.0) — protected and metered SharePoint and OneDrive API status, files-at-rest scope, permissions, asynchronous operation behavior, and Global-service availability.
- [Automatically apply a sensitivity label to Microsoft 365 data](https://learn.microsoft.com/purview/apply-sensitivity-label-automatically) — the currently documented 500,000-files-per-tenant daily ceiling, service-side workload scope, eligible licensing, and configurable replacement of lower-priority manually applied labels.
- [Enable sensitivity labels for files in SharePoint and OneDrive](https://learn.microsoft.com/purview/sensitivity-labels-sharepoint-onedrive-files) — supported file-processing boundaries and a conflicting 100,000-files-per-day statement in the PDF guidance.
- [driveItem: extractSensitivityLabels](https://learn.microsoft.com/graph/api/driveitem-extractsensitivitylabels?view=graph-rest-1.0) — v1.0 extraction, `Files.Read.All`, supported-file limits, metadata refresh behavior, and errors.
- [sensitivityLabel resource type](https://learn.microsoft.com/graph/api/resources/security-sensitivitylabel?view=graph-rest-beta) — beta status and list/get methods for sensitivity label definitions.
- [List sensitivityLabels](https://learn.microsoft.com/graph/api/security-informationprotection-list-sensitivitylabels?view=graph-rest-beta) — user versus organization routes and delegated/application permissions.
- [Microsoft Graph permissions reference](https://learn.microsoft.com/graph/permissions-reference) — delegated `InformationProtectionPolicy.Read` and application `InformationProtectionPolicy.Read.All` permission semantics.
- [Migrate parent sensitivity labels to label groups](https://learn.microsoft.com/purview/migrate-sensitivity-label-scheme) — label-group migration, documented automatic-migration cases, tenant rollout availability, and the irreversible migration warning.
- [Microsoft Purview service description](https://learn.microsoft.com/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-purview-service-description) — feature-specific eligible plans, base-license considerations, and benefiting-user licensing requirements.
- [Learn about sensitivity labels](https://learn.microsoft.com/purview/sensitivity-labels) and [Microsoft 365 Copilot considerations](https://learn.microsoft.com/purview/ai-m365-copilot-considerations) — classification without protection settings and conditional enforcement of encryption and DLP.
- [Microsoft Graph metered APIs and services](https://learn.microsoft.com/graph/metered-api-list) — label assignment remains documented as metered; the Teams API billing change does not extend to this action.

## Known Limitations

- The dedicated Microsoft Purview auto-labeling article currently documents a maximum of 500,000 automatically labeled files per tenant per day. The linked SharePoint/OneDrive PDF guidance still states 100,000 files per day. Confirm the applicable service limit before sizing remediation waves; neither figure is a throughput guarantee or the quota for the separate Graph assignment action.
- The `assignSensitivityLabel` API is a protected and metered SharePoint and OneDrive Microsoft Graph API for files at rest; approved bulk application scenarios require protected API validation beyond permission consent, metered API enablement (charges may apply), least-privileged `Files.ReadWrite.All` or `Sites.ReadWrite.All`, long-running operation handling, and use in the Global service, which Microsoft Learn lists as the documented available cloud for this API.
- Exchange coverage can lag if required message-level label metadata is not consistently exposed through the chosen collection method.
- Failed, unsupported, or indeterminate label extraction must not be treated as confirmed label absence. The Graph extraction action can refresh item metadata even though its least-privileged permission is `Files.Read.All`; it is not a zero-service-state-change guarantee.
- This version focuses on monitoring, evidence production, and remediation planning; it does not claim automatic enforcement across every workload.
- Microsoft is replacing parent labels with label groups. Migration is irreversible; automatic migration applies only in documented cases, and other tenants should migrate when the Microsoft Purview portal banner is available. The solution's taxonomy snapshot should be updated to record label group membership after migration.
- Service-side auto-labeling policies can be configured to override existing lower-priority manually applied labels on files. Remediation manifests should account for this capability.
