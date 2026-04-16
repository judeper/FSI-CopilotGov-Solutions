# Copilot Interaction Audit Trail Manager

> **Status:** Documentation-first scaffold | **Version:** v0.2.0 | **Priority:** P0 | **Track:** B

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Copilot Interaction Audit Trail Manager supports compliance with books-and-records, audit trail, and supervisory evidence requirements by documenting how to validate Microsoft 365 Copilot audit capture, configure retention coverage, verify Microsoft Purview eDiscovery readiness, and assemble regulator-ready evidence. The solution is documentation-first for Power Automate and Power BI and uses PowerShell to generate deployment manifests, monitor posture, and export structured evidence.

## Solution profile

| Attribute | Value |
|-----------|-------|
| Solution type | PowerShell, Power Automate, Power BI |
| Evidence outputs | audit-log-completeness, retention-policy-state, ediscovery-readiness-package |
| Primary controls | 3.1, 3.2, 3.3, 3.11, 3.12 |
| Regulations | SEC 17a-3, SEC 17a-4, FINRA 4511, CFTC 1.31, SOX 404 |
| Dependencies | None |

## What this solution does

- Supports validation of Microsoft 365 Unified Audit Log configuration by checking tier-specific audit level expectations and confirming that CopilotInteraction and AIInteraction events are included in validation scope.
- Documents Purview retention policy and retention label requirements for Copilot interaction artifacts.
- Validates Microsoft Purview eDiscovery readiness against tier requirements including preservation status, hold counts, case coverage, and custodian scope.
- Packages JSON evidence with SHA-256 companion files for examination support.
- Defines Power BI dashboard metrics for audit completeness, retention coverage, and Microsoft Purview eDiscovery readiness (requires customer implementation in their tenant).
- Defines Power Automate exception alert expectations for retention and evidence gaps (requires customer implementation in their tenant).

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft 365 Unified Audit Log APIs (scripts validate configuration expectations against tier requirements)
- ❌ Does not verify actual audit event capture (UAL event validation requires manual verification through the compliance portal)
- ❌ Does not deploy Power Automate flows (alert workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Regulatory context

- SEC 17a-3 and SEC 17a-4 require firms to preserve books and records for defined periods and to maintain non-rewriteable, non-erasable retention where applicable.
- FINRA 4511 requires preservation of required records for at least three years in a format that can be produced promptly.
- CFTC 1.31 requires preservation, searchability, and production readiness for regulated records, commonly five years for books-and-records use cases.
- SOX 404 places emphasis on reliable audit trails, control evidence, and traceable operation of supervisory controls.

This solution supports compliance with those obligations by organizing audit validation, retention configuration, Microsoft Purview eDiscovery readiness checks, and evidence export into repeatable PowerShell-driven activities.

## Prerequisites

- Microsoft 365 E5 or E5 Compliance licensing for Purview features used by audit, retention, and Microsoft Purview eDiscovery operations.
- Power BI Pro for dashboard publication and refresh management.
- Roles: Compliance Administrator, eDiscovery Manager, Audit Log Reader, and Global Reader.
- PowerShell modules: ExchangeOnlineManagement and Microsoft.Graph.
- Graph application permissions or delegated permissions approved for AuditLog.Read.All and RecordsManagement.Read.All.
- Unified Audit Log enabled in the tenant.

See [docs/prerequisites.md](./docs/prerequisites.md) for the detailed prerequisite matrix.

## Deployment

Deploy this solution in stages: validate Unified Audit Log coverage, generate the retention manifest, confirm Microsoft Purview eDiscovery readiness, then publish the first evidence package. The detailed configuration and operating activities are organized in the following subsections so teams can execute the rollout in a controlled order.

## Audit configuration steps

1. Confirm that Microsoft 365 Unified Audit Log is enabled in the tenant.
2. Manually verify that CopilotInteraction and AIInteraction events appear in the Unified Audit Log through the Microsoft Purview compliance portal or PowerShell.
3. Confirm the expected audit level for the selected tier:
   - baseline: Standard
   - recommended: Advanced
   - regulated: Advanced
4. Record sample event counts for the target validation window and retain the results in `audit-log-completeness.json`.
5. Re-run the validation after major Microsoft 365 audit configuration changes.

## Retention policy setup

1. Use `scripts\Deploy-Solution.ps1` to generate `retention-policy-manifest.json`.
2. Apply the manifest through Microsoft Purview Data Lifecycle Management or the operational `Set-RetentionPolicy` process used by your tenant.
3. Assign retention labels to Copilot interaction artifacts, transcripts, shared files, and related investigation records where firm policy requires label coverage.
4. Document the final retention schedule by regulation:
   - SEC 17a-4 minimum reference: 2190 days
   - FINRA 4511 minimum reference: 1095 days
   - CFTC 1.31 minimum reference: 1825 days
   - SOX 404 supervisory evidence reference: 2555 days
5. For regulated deployments, document WORM-capable storage or equivalent immutable storage attestations separately.

## Microsoft Purview eDiscovery readiness

- Confirm that at least one Microsoft Purview eDiscovery case template exists for the selected tier.
- Validate preservation status, hold counts, and custodian coverage before evidence export.
- Ensure legal hold owners, escalation contacts, and export responsibilities are documented.
- Use `scripts\Monitor-Compliance.ps1` to record readiness status before examination support exports.
- Use `scripts\Export-Evidence.ps1` to package the readiness snapshot.

## Power BI monitoring dashboard

The Power BI dashboard is documentation-first in this repository. The expected dashboard pages are:

- Audit completeness: event coverage, sample count trend, UAL validation age, and Copilot event type availability.
- Retention coverage: configured retention by regulation, label coverage status, and policy gap alerts.
- Microsoft Purview eDiscovery readiness: case counts, hold counts, custodian coverage, preservation status, and evidence package age.

Recommended measures include audit completeness percentage, retention minimum variance, open exception count, and days since last evidence export.

## Power Automate retention exception alerts

The Power Automate flow is documentation-first in this repository. The expected flow behavior is:

- Trigger on compliance status updates or evidence export findings.
- Alert when required event types are missing from the validation scope.
- Alert when configured retention days are below regulatory minimums.
- Alert when Microsoft Purview eDiscovery hold readiness is incomplete for the selected tier.
- Route notifications to the compliance operations owner and solution mailbox.

## Related Controls

| Control | Focus | How this solution supports the control |
|---------|-------|----------------------------------------|
| 3.1 | Audit trail completeness | Validates Unified Audit Log readiness and confirms Copilot interaction event coverage. |
| 3.2 | Data retention policies for Copilot interactions | Documents retention schedules, labels, and tier-specific policy expectations. |
| 3.3 | Microsoft Purview eDiscovery for Copilot-generated content | Tracks case readiness, hold coverage, and custodian scope before evidence export. |
| 3.11 | Record keeping and books-and-records compliance | Organizes retention manifests and readiness outputs that support recordkeeping reviews. |
| 3.12 | Evidence collection and audit attestation | Packages JSON artifacts and SHA-256 companion files for downstream audit handling. |

## Evidence Export

`Export-Evidence.ps1` creates the following artifact set:

- `audit-log-completeness.json`
- `retention-policy-state.json`
- `ediscovery-readiness-package.json`
- `06-audit-trail-manager-evidence.json`
- SHA-256 companion files for every exported JSON file

The evidence package supports compliance with recordkeeping examinations by preserving configuration state, control notes, and artifact integrity hashes.

## Regulatory Alignment

| Regulation | Retention expectation | Solution support | Notes |
|------------|-----------------------|------------------|-------|
| SEC 17a-3 | Preserve required records and supporting supervisory evidence | Audit evidence package and retention manifest | Use exported evidence to support books-and-records reviews |
| SEC 17a-4 | 3-6 year preservation, plus non-rewriteable and non-erasable retention where applicable | Retention manifest, WORM documentation note, immutable storage attestation tracking | WORM enforcement requires a third-party archive or Azure Immutable Storage design outside this repository |
| FINRA 4511 | 3-year minimum retention and prompt production | Baseline retention schedule and evidence package | Baseline tier aligns to the minimum 1095-day schedule |
| CFTC 1.31 | 5-year preservation and prompt production readiness | Recommended tier retention schedule and Microsoft Purview eDiscovery readiness checks | Recommended tier aligns to 1825-day retention |
| SOX 404 | Reliable audit trail and control evidence | Audit completeness monitoring and exported control notes | Regulated tier extends evidence retention to support supervisory review |

## Known limitations

- Unified Audit Log events may take up to 24 hours to appear after workload activity.
- Copilot interaction detail depends on the Microsoft 365 audit level available in the tenant.
- WORM retention under SEC 17a-4 requires a third-party archive, Azure Immutable Storage, or another approved immutable storage pattern outside this repository.
- The repository provides documentation-first definitions for Power BI and Power Automate; deployment teams must implement tenant-specific assets.
- Evidence exports describe expected control state and support compliance with validation workflows, but they do not replace legal or regulatory review.
- The SEC's 2022 amendment to Rule 17a-4 now permits an audit-trail alternative to WORM storage, provided firms maintain detailed audit logs that prevent alteration or deletion. Organizations should evaluate both WORM and audit-trail options when planning immutable evidence storage.

## Additional documentation

- [Architecture](./docs/architecture.md)
- [Deployment Guide](./docs/deployment-guide.md)
- [Evidence Export](./docs/evidence-export.md)
- [Prerequisites](./docs/prerequisites.md)
- [Troubleshooting](./docs/troubleshooting.md)
