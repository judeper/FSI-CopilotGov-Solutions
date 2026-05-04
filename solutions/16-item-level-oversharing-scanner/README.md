# Item-Level Oversharing Scanner

> **Status:** Documentation-first scaffold | **Version:** v0.1.1 | **Priority:** P1 | **Track:** A

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

This solution extends solution [02-oversharing-risk-assessment](../02-oversharing-risk-assessment/) by moving from site-level oversharing detection to individual item-level permission scanning. While solution 02 identifies sites and workspaces with broad sharing patterns, solution 16 drills into document libraries and enumerates file and folder permissions that expose regulated content to Microsoft 365 Copilot grounding paths.

Item-level scanning matters for Copilot readiness because Copilot surfaces content based on the effective permissions of the prompting user. A site may have appropriate top-level sharing settings, but individual files or folders within that site can still carry overshared permissions through anyone links, organization-wide edit links, external guest grants, or broad security group membership. These item-level exposures are invisible to site-level scans and represent a significant undetected risk surface in regulated financial services environments.

The solution implements a 3-script pipeline:

1. **Scan** (`Get-ItemLevelPermissions.ps1`) — Documents a pattern for connecting via PnP PowerShell to enumerate document libraries and retrieve per-item permission entries. Flags items shared via anyone links, organization-wide edit links, external/guest users, or broad groups such as "Everyone" or "Everyone except external users."

2. **Score** (`Export-OversharedItems.ps1`) — Reads the scan output and applies FSI risk scoring. Items are classified as HIGH, MEDIUM, or LOW based on sharing type, sensitivity label, and content-type risk weighting from `config/risk-thresholds.json`.

3. **Remediate** (`Invoke-BulkRemediation.ps1`) — Processes the scored report and documents remediation actions such as removing sharing links, removing external user permissions, or downgrading organization links from Edit to View. HIGH-risk items always require approval before action. MEDIUM and LOW items follow the policy defined in `config/remediation-policy.json`, which defaults to approval-gate mode.

Risk thresholds are configurable through `config/risk-thresholds.json`, which defines base risk scores for each sharing type and content-type weighting multipliers for FSI-sensitive categories such as customer PII, trading data, legal documents, and regulatory filings.

By default, all remediation tiers use approval-gate mode. Auto-remediation is intentionally disabled because FSI content typically requires legal, compliance, and records-management review before permissions are changed.

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to SharePoint or Microsoft Graph APIs (scripts use representative sample data)
- ❌ Does not remediate oversharing automatically by default (approval-gate mode is the default for all risk tiers)
- ❌ Does not replace solution 02 site-level scanning (item-level scanning is a complementary deep-dive capability)
- ❌ Does not scan content body or attachments (permission enumeration only, not content inspection)
- ❌ Does not deploy Power Automate flows (approval routing is documented, not exported)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not modify sensitivity labels (label information is read-only for risk scoring)

> **Data classification:** See [Data Classification Matrix](../../docs/reference/data-classification.md) for residency, retention, and data-class metadata.

## Architecture

See [docs/architecture.md](docs/architecture.md) for the 3-script pipeline diagram, data flow, and remediation policy design.

## Prerequisites

- Review [docs/prerequisites.md](docs/prerequisites.md) and confirm the required admin roles, PowerShell modules, and API permissions are in place.
- Verify that solution [02-oversharing-risk-assessment](../02-oversharing-risk-assessment/) has completed a site-level assessment and identified high-risk sites for item-level deep-dive.
- Confirm PnP PowerShell connectivity to the target SharePoint tenant.

## Quick Start

1. Review [docs/prerequisites.md](docs/prerequisites.md) and confirm the required admin roles, PowerShell modules, and API access are in place.
2. Verify that solution [02-oversharing-risk-assessment](../02-oversharing-risk-assessment/) has identified sites requiring item-level scanning.
3. Select the appropriate governance tier from `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
4. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -TenantId <tenant-guid>` to validate configuration and create the deployment manifest.
5. Run `scripts\Get-ItemLevelPermissions.ps1 -SiteUrls @("https://tenant.sharepoint.com/sites/example") -TenantUrl "https://tenant-admin.sharepoint.com" -OutputPath .\artifacts\scan` to enumerate item-level permissions.
6. Run `scripts\Export-OversharedItems.ps1 -InputPath .\artifacts\scan\item-permissions.csv -OutputPath .\artifacts\scored` to apply FSI risk scoring.
7. Run `scripts\Invoke-BulkRemediation.ps1 -InputPath .\artifacts\scored\risk-scored-report.csv -OutputPath .\artifacts\remediation -TenantUrl "https://tenant-admin.sharepoint.com"` to generate remediation actions (approval-gate by default).
8. Run `scripts\Export-Evidence.ps1` to package evidence artifacts and SHA-256 companion files.

## Deployment

Deploy this solution after solution 02 has completed site-level scanning and identified high-risk sites that warrant item-level investigation. Start with the scan script in a constrained scope (a few sites) to validate permissions enumeration and risk scoring before expanding to broader coverage.

After the deployment manifest is created with `Deploy-Solution.ps1`, run the 3-script pipeline (scan → score → remediate), review findings with site owners and compliance teams, then run `Export-Evidence.ps1` to archive the approved baseline.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Get-ItemLevelPermissions.ps1` | Enumerates document libraries and retrieves per-item permission entries using PnP PowerShell |
| `scripts\Export-OversharedItems.ps1` | Applies FSI risk scoring and content-type weighting to produce a risk-scored report |
| `scripts\Invoke-BulkRemediation.ps1` | Processes the scored report and applies approval-gated remediation actions |
| `scripts\Deploy-Solution.ps1` | Loads configuration, validates prerequisites and upstream dependency, and writes a deployment manifest |
| `scripts\Monitor-Compliance.ps1` | Orchestrates the scan → score workflow for scheduled monitoring |
| `scripts\Export-Evidence.ps1` | Packages findings, scored reports, and remediation actions into schema-aligned evidence with SHA-256 checksums |
| `config\default-config.json` | Shared defaults for controls, risk thresholds, and evidence output |
| `config\risk-thresholds.json` | Content-type weights and base risk scores for FSI risk classification |
| `config\remediation-policy.json` | Remediation mode per risk tier (approval-gate by default) |
| `config\baseline.json` | Minimum viable rollout posture |
| `config\recommended.json` | Production-oriented posture with broader scanning scope |
| `config\regulated.json` | Examination-ready posture with extended evidence retention |
| `docs\*.md` | Architecture, deployment, prerequisites, evidence, and troubleshooting guidance |
| `tests\16-item-level-oversharing-scanner.Tests.ps1` | Pester validation for structure, content expectations, and script syntax |

## Dependency on 02-oversharing-risk-assessment

Solution 16 depends on the site-level oversharing assessment from solution 02 to identify which sites warrant item-level investigation. The deployment workflow checks for upstream evidence so item-level scans can be targeted at sites already flagged for broad sharing, guest access, or regulated content exposure.

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../docs/reference/control-coverage-honesty.md)):
> 5 control(s) are **evidence-export-ready** in scaffold form: 1.2, 1.3, 1.4, 1.6, 2.5.
> 1 control(s) is/are **documentation-only** (listed in metadata but not yet exercised by scripts/tests in this scaffold): 1.14.

| Control | Status Focus | How this solution supports the control |
|---------|--------------|----------------------------------------|
| 1.2 | Primary | Detects item-level oversharing within SharePoint document libraries and prepares governed remediation actions |
| 1.3 | Primary | Supports temporary Restricted SharePoint Search or Restricted Content Discovery planning by identifying sites and items needing permission cleanup; RSS is site-scoped, short-term, and does not change permissions |
| 1.4 | Primary | Supports semantic index governance by surfacing items with permissions that exceed intended Copilot grounding scope |
| 1.6 | Supporting | Supplements site-level permission audits with granular item-level anomaly detection |
| 2.5 | Primary | Promotes data minimization by identifying and remediating item-level permissions that are broader than necessary |

## Regulatory Alignment

This solution supports compliance with GLBA 501(b), SEC Reg S-P, FINRA Rule 4511, SOX 302/404, and the FFIEC IT Handbook by documenting repeatable detection, risk scoring, remediation, and evidence export patterns for item-level oversharing in collaboration content. It is designed to help regulated institutions demonstrate governance intent, granular control monitoring, and examiner-ready recordkeeping without making absolute compliance claims.

## Evidence Export

Evidence packages align to `..\..\data\evidence-schema.json` and include:

- `item-oversharing-findings` — Raw item-level permission scan results
- `risk-scored-report` — FSI risk-scored and weighted report with tier classifications
- `remediation-actions` — Remediation actions taken or pending approval

Each JSON artifact is written with a companion `.sha256` file so control evidence can be verified during audit preparation, internal assurance reviews, and regulator response exercises.

## Known Limitations

- The scanning scripts use implementation stubs and sample data until tenant-specific PnP connections are configured.
- Item-level scanning can be resource-intensive for large document libraries; use site scoping and throttling controls.
- Sensitivity label information depends on tenant labeling configuration and may not be available for all items.
- Auto-remediation is intentionally not the default mode because high-risk FSI content often requires legal, compliance, and records-management review before permissions change.
- Teams-connected document libraries are scanned through their underlying SharePoint site; direct Teams API integration is not included.
