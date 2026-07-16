# Oversharing Risk Assessment and Remediation

> **Status:** Documentation-first scaffold | **Version:** v0.2.5 | **Priority:** P0 | **Track:** A | **Last Verified:** 2026-07-16

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

> **Lab validation:** Accepted `PASS` on 2026-07-16 against pinned contract commit `488d8f63a1c3ba6c01e5ce7b37f7f68bcd644158` (`accepted: true`, `controlImplementation: implemented`, 8/8 steps PASS, cleanup `not-required`, no tenant mutation). Restricted Content Discovery was authenticated with `observedAvailability: false` (control not exposed). Result SHA-256: `19240ff458f97fa3b78c299c86a9b27bba57cf506fcf75fe18f578fbeb750bda`; package SHA-256: `51700b6478e4e6787d70de9016835c5fee0a3408e6599e11735c91ac7d83b197`. Evidence is retained outside Git.

## Overview

This solution provides a framework for oversharing detection across SharePoint, Teams, and OneDrive content that Microsoft 365 Copilot can surface during grounded responses. It extends the output of solution 01-copilot-readiness-scanner, applies financial-services risk tiering to exposed content patterns, and prepares structured remediation actions for site owners, security operations, and compliance reviewers.

The design focuses on the highest-risk FSI exposure scenarios: customer PII, trading data, legal and compliance documents, and other regulated records that have been shared too broadly. Findings are classified as HIGH, MEDIUM, or LOW so institutions can prioritize remediation waves before expanding Copilot access.

## Features

- Documents bulk site and workspace scanning patterns across SharePoint sites, OneDrive accounts, and Teams-connected sites
- FSI-specific risk scoring that weights sharing scope, guest access, and regulated data indicators
- Remediation queue generation for high-priority permissions cleanup and owner follow-up
- Site owner notification support through documentation-first Power Automate patterns
- Guest access governance checks for external sharing, anyone links, and broad internal exposure
- Restricted SharePoint Search legacy transition guidance (retiring, with new enablement blocked starting 2026-07-31) plus Restricted Content Discovery planning as the go-forward per-site discoverability control for SharePoint
- Restricted Content Discovery operating notes covering no permission changes, SharePoint-only scope (not OneDrive), SharePoint Administrator default ownership with optional delegated site-admin management, Microsoft Purview audit visibility, and possible AI entry-point suppression on restricted sites
- Evidence export packages for oversharing-findings, remediation-queue, and site-owner-attestations

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state in its repository form.

- ❌ Default/sample mode does not connect to Microsoft Graph or SharePoint APIs (representative data only)
- ❌ Optional read-only Microsoft Graph mode must be explicitly enabled and falls back to sample data if authentication fails
- ❌ Does not remediate oversharing automatically (remediation queue is documented, not executed)
- ❌ Does not execute tenant writes, permission changes, or automated remediations
- ❌ Does not deploy Power Automate flows (flow designs are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

> **Data classification:** See [Data Classification Matrix](../../docs/reference/data-classification.md) for residency, retention, and data-class metadata.

## Architecture

See [docs/architecture.md](docs/architecture.md) for the component diagram, workload data flow, remediation modes, and Power Automate integration pattern.

## Prerequisites

- Review [docs/prerequisites.md](docs/prerequisites.md) and confirm the required admin roles, PowerShell modules, and API access are in place.
- Verify that solution [01-copilot-readiness-scanner](../01-copilot-readiness-scanner/) has already produced baseline output that can be used to prioritize high-risk workloads.
- Confirm SharePoint Advanced Management feature entitlement is available through the required base license and one documented entitlement path (Microsoft 365 Copilot, standalone SharePoint Advanced Management Plan 1, or Microsoft 365 E7 where available), and confirm Microsoft Purview Data Security Posture Management (DSPM) prerequisites for the target scenarios.

## Quick Start

1. Review [docs/prerequisites.md](docs/prerequisites.md) and confirm the required admin roles, PowerShell modules, and API access are in place.
2. Verify that solution [01-copilot-readiness-scanner](../01-copilot-readiness-scanner/) has already produced baseline output that can be used to prioritize high-risk workloads.
3. Check that SharePoint Advanced Management entitlement, Restricted Content Discovery prerequisites, and Microsoft Purview DSPM prerequisites are available for the target tenant scenarios.
4. Select the appropriate governance tier from `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
5. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -TenantId <tenant-guid> -ScanMode DetectOnly` to validate configuration and create the deployment manifest.
6. Run `scripts\Monitor-Compliance.ps1` in detect-only mode to generate the initial oversharing findings set.
7. Review the remediation queue, plan waves by risk tier, then enable owner notifications after stakeholder sign-off.
8. Run `scripts\Export-Evidence.ps1` to package evidence artifacts and SHA-256 companion files.

## Deployment

Deploy this solution in detect-only mode first so stakeholders can review oversharing findings and approve remediation sequencing before any enforcement changes are considered. After the deployment manifest is created with `Deploy-Solution.ps1`, run `Monitor-Compliance.ps1` to capture the first finding set, review the remediation queue with site owners and compliance teams, then run `Export-Evidence.ps1` to archive the approved baseline.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Loads configuration, checks upstream readiness output, validates deployment prerequisites, and writes a deployment manifest |
| `scripts\Monitor-Compliance.ps1` | Produces workload findings for SharePoint, OneDrive, and Teams and assigns HIGH, MEDIUM, or LOW risk |
| `scripts\Export-Evidence.ps1` | Packages findings, remediation queue data, owner attestations, and checksum files aligned to the evidence schema |
| `config\default-config.json` | Shared defaults for controls, risk thresholds, workloads, notifications, and evidence output |
| `config\baseline.json` | Minimum viable rollout posture focused on SharePoint and detect-only scanning |
| `config\recommended.json` | Production-oriented posture with multi-workload coverage and owner notifications |
| `config\regulated.json` | Examination-ready posture with extended evidence retention and attestation requirements |
| `lab\02-oversharing-risk-assessment.lab.json` | Read-only lab validation contract for US commercial-cloud preflight, evidence expectations, and accepted PASS/BLOCKED/NOT-APPLICABLE dispositions |
| `docs\*.md` | Architecture, deployment, prerequisites, evidence, and troubleshooting guidance |
| `tests\02-oversharing-risk-assessment.Tests.ps1` | Pester validation for structure, content expectations, and script syntax |

## Dependency on 01-copilot-readiness-scanner

Solution 02 depends on the baseline inventory and readiness outputs from solution 01-copilot-readiness-scanner. The deployment workflow checks for upstream evidence so oversharing scans can be prioritized against workloads that already show Copilot readiness, broad collaboration patterns, or unresolved data hygiene concerns.

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../docs/reference/control-coverage-honesty.md)):
> 6 control(s) are **evidence-export-ready** in scaffold form: 1.2, 1.3, 1.4, 1.6, 2.12, 2.5.
> 1 control(s) is/are **documentation-only** (listed in metadata but not yet exercised by scripts/tests in this scaffold): 3.10.

| Control | Status Focus | How this solution supports the control |
|---------|--------------|----------------------------------------|
| 1.2 | Primary | Documents patterns for detecting overshared SharePoint, Teams, and OneDrive content and prepares governed remediation actions |
| 1.3 | Primary | Documents Restricted SharePoint Search as legacy transition guidance only (retiring with new enablement blocked from 2026-07-31) and positions Restricted Content Discovery as the go-forward per-site discoverability control without permission changes |
| 1.4 | Primary | Supports semantic index governance by identifying high-risk sites that should be limited or re-scoped |
| 1.6 | Supporting | Supplements permission model audits with workload-level anomaly counts and remediation recommendations |
| 2.5 | Primary | Promotes data minimization by reducing broadly accessible content in Copilot grounding paths |
| 2.12 | Primary | Surfaces guest access and external sharing exposure for governance review and cleanup |

## Regulatory Alignment

This solution supports compliance with GLBA 501(b), SEC Reg S-P, FINRA 4511, and the FFIEC IT Handbook by documenting repeatable detection, triage, remediation, and evidence export patterns for overshared collaboration content. It is designed to help regulated institutions demonstrate governance intent, control monitoring, and examiner-ready recordkeeping without making absolute compliance claims.

The solution also supports SOX 302/404 internal control documentation by providing evidence of data exposure assessment and remediation tracking.

## Evidence Export

Evidence packages align to `..\..\data\evidence-schema.json` and include:

- `oversharing-findings`
- `remediation-queue`
- `site-owner-attestations`
- `sensitivity-label-coverage`

Each JSON artifact is written with a companion `.sha256` file so control evidence can be verified during audit preparation, internal assurance reviews, and regulator response exercises.

## Power Automate Note

Power Automate assets are documentation-first in this version. The repository documents the expected `SiteOwnerNotification` and `RemediationApproval` flows, but tenant-specific connectors, approvals, and routing rules must be created in the customer Power Automate environment.

## Known Limitations

- The monitoring script uses implementation stubs and sample workload logic until tenant-specific API calls and throttling controls are connected.
- Teams findings are inferred from Teams-connected SharePoint locations and channel exposure patterns; they are not a replacement for a full Teams governance review.
- Restricted SharePoint Search is documented as legacy transition guidance only; for existing tenants it remains temporary, limited to up to 100 allowed sites, is not a security boundary, and does not change permissions.
- Restricted Content Discovery planning in this scaffold is SharePoint-only (not OneDrive), requires Copilot plus SharePoint Advanced Management prerequisites, and may suppress AI entry points on restricted SharePoint sites.
- Auto-remediation is intentionally not the default mode because high-risk FSI content often requires legal, compliance, and records-management review before permissions change.
