# SharePoint Permissions Drift Detection

> **Status:** Documentation-first scaffold | **Version:** v0.1.4 | **Priority:** P1 | **Track:** A

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

SharePoint permissions drift occurs when the effective access rights on sites, libraries, lists, and items change over time — diverging from an approved baseline. In regulated financial services environments, this drift creates material risk because **Microsoft 365 Copilot surfaces whatever SharePoint exposes**. When permissions silently expand, Copilot's retrieval-augmented generation may surface confidential trading records, customer PII, or legal-privileged documents to users who should not have access.

This solution provides a documentation-first framework for detecting, reporting, and optionally reverting permissions drift across SharePoint Online. The included scripts use representative sample data until tenant binding is added. It implements a four-script workflow:

1. **Baseline capture** (`New-PermissionsBaseline.ps1`) — produces representative baseline snapshots as the approved reference pattern.
2. **Drift scan** (`Invoke-DriftScan.ps1`) — returns representative permission-entry drift scoped to the baseline and classifies samples by risk tier.
3. **Drift reversion** (`Invoke-DriftReversion.ps1`) — logs reversion intent or queues pending approvals per risk tier.
4. **Evidence export** (`Export-DriftEvidence.ps1`) — packages drift findings, reversion logs, and baseline snapshots for regulatory examination response.

By default, the solution operates in **approval-gate mode**: representative drift generates pending-approval records and can send notifications when Graph mail is configured. Approval responses and timeout escalation require an external workflow. Auto-reversion settings in `config/auto-revert-policy.json` record scaffold reversion intent rather than changing live permissions.

This solution complements [Solution 02 — Oversharing Risk Assessment](../02-oversharing-risk-assessment/index.md) (site-level oversharing detection) and Solution 16 (item-level permissions analysis) by documenting a **temporal dimension** — how permissions can be reviewed over time rather than only at a single point-in-time snapshot.

## Features

- **Representative baseline snapshots** for site sharing settings, unique permission entries, sharing links, and external user scenarios
- **Scaffold drift scan output** for permission-entry changes until tenant-bound comparison is added
- **Risk-tiered classification** (HIGH / MEDIUM / LOW) of representative permission changes
- **Approval-gate records** with configurable approvers; responses and timeout handling require an external workflow
- **Optional auto-reversion intent logging** enabled per risk tier for remediation runbook design
- **Alert notifications** via Microsoft Graph API using a configured sender mailbox or delegated `/me/sendMail`
- **Evidence packaging** with SHA-256 integrity verification for regulatory examinations
- **Multi-tier configuration** (baseline, recommended, regulated) for progressive deployment

## Scope Boundaries

This solution **does not**:

- ❌ Connect to live Microsoft 365 or SharePoint Online tenants (scripts use representative sample data)
- ❌ Execute actual permission changes in production environments
- ❌ Replace Microsoft Purview or SharePoint Advanced Management licensing requirements
- ❌ Provide real-time continuous monitoring (operates on a scheduled scan cadence)
- ❌ Cover Exchange Online, Teams channel, or Viva Engage permissions
- ❌ Perform content inspection or data classification (complements Solution 03 for sensitivity labels)
- ❌ Replace a compliance program or legal review — it supports compliance efforts
- ❌ Replace legal or compliance counsel review of permission policies

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Architecture

See [docs/architecture.md](architecture.md) for the component diagram and data flow.

## Prerequisites

See [docs/prerequisites.md](prerequisites.md) for platform, licensing, roles, and module requirements.

## Quick Start

1. **Verify upstream output** — Confirm Solution 02 (Oversharing Risk Assessment) has been deployed or reviewed.
2. **Review prerequisites** — Validate licensing and administrative roles per [prerequisites](prerequisites.md).
3. **Select configuration tier** — Choose `baseline`, `recommended`, or `regulated` per your institution's risk posture.
4. **Deploy the solution** — Run `Deploy-Solution.ps1` to validate configuration and prerequisites.
5. **Generate representative baseline** — Run `New-PermissionsBaseline.ps1` to produce a scaffold baseline snapshot.
6. **Run scaffold drift scan** — Run `Invoke-DriftScan.ps1` to produce representative drift scoped to the baseline.
7. **Review drift report** — Evaluate findings and configure reversion policy in `auto-revert-policy.json`.
8. **Export evidence** — Run `Export-DriftEvidence.ps1` to package findings for compliance review.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts/New-PermissionsBaseline.ps1` | Produces representative approved permissions baseline snapshots |
| `scripts/Invoke-DriftScan.ps1` | Returns and classifies representative permissions drift |
| `scripts/Invoke-DriftReversion.ps1` | Logs reversion intent or queues approval for drifted permissions |
| `scripts/Export-DriftEvidence.ps1` | Packages drift evidence for regulatory examination |
| `scripts/Deploy-Solution.ps1` | Validates configuration and prerequisites |
| `scripts/Monitor-Compliance.ps1` | Orchestrates baseline check and drift scan |
| `scripts/Export-Evidence.ps1` | Standard evidence export using shared modules |
| `config/default-config.json` | Solution metadata and shared defaults |
| `config/baseline-config.json` | Baseline capture scope and retention settings |
| `config/auto-revert-policy.json` | Reversion mode, approval gate, and escalation settings |
| `config/baseline.json` | Baseline tier overrides |
| `config/recommended.json` | Recommended tier overrides |
| `config/regulated.json` | Regulated tier overrides |

## Dependency on Solution 02

This solution references the site inventory and oversharing risk classification pattern from [Solution 02 — Oversharing Risk Assessment](../02-oversharing-risk-assessment/index.md). The deployment script checks whether the Solution 02 folder is present; tenant-bound risk score elevation from Solution 02 output is a future integration step.

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../reference/control-coverage-honesty.md)):
> 4 control(s) are **evidence-export-ready** in scaffold form: 1.2, 1.4, 1.6, 2.5.

| Control ID | Focus Area | How This Solution Supports |
|------------|-----------|---------------------------|
| 1.2 | SharePoint site-level sharing | Documents the site-sharing drift pattern; scaffold evidence uses representative sample output |
| 1.4 | Guest and external access | Documents external-access drift scenarios with sample findings until live comparison is added |
| 1.6 | Permission scope validation | Tracks representative unique permission entry changes on lists and libraries |
| 2.5 | Oversharing remediation | Supports approval-gate and reversion-intent runbook design for unauthorized permission expansions |

## Regulatory Alignment

| Framework | Relevance |
|-----------|-----------|
| **GLBA § 501(b)** | Supports compliance with safeguard requirements by detecting unauthorized access expansions |
| **SEC Regulation S-P** | Helps meet customer information protection by monitoring permission changes |
| **FINRA Rule 4511** | Supports record-keeping requirements through baseline and drift audit trails |
| **SOX §§ 302, 404** | Helps meet internal control requirements by detecting and documenting access changes |
| **FFIEC IT Examination Handbook** | Provides a framework for access control monitoring aligned with examination expectations |

## Deployment

See [docs/deployment-guide.md](deployment-guide.md) for the step-by-step deployment sequence.

## Evidence Export

See [docs/evidence-export.md](evidence-export.md) for evidence types, schema alignment, and retention guidance.

Evidence artifacts produced by this solution:

- **drift-report** — Detailed drift findings with before/after permission state and risk classification
- **baseline-snapshot** — Point-in-time permissions baseline used as the comparison reference
- **reversion-log** — Record of scaffold reversion intent or approval-gated actions

## Power Automate Note

This solution documents Power Automate flow patterns for approval-gate workflows and drift alert notifications. Exported Power Automate runtime artifacts are not committed to this repository. See [docs/deployment-guide.md](deployment-guide.md) for flow construction guidance.

## Known Limitations

- All scripts return representative sample data; tenant binding requires `PnP.PowerShell` and `Microsoft.Graph` module configuration with appropriate credentials.
- Auto-reversion logic documents the reversion pattern but does not execute live permission changes.
- Approval responses and timeout escalation require an external workflow to process `pending-approvals.json`.
- Approval-gate email notifications require Microsoft Graph `Mail.Send` permission and a licensed sender mailbox.
- Baseline comparison operates at the unique permission entry level; sharing links, external users, and inherited-vs-unique analysis are documented as tenant-binding design targets.
- Risk scoring uses fixed scaffold factors for permission level and principal type; Solution 02 and classifier-based score elevation are future integration steps.
