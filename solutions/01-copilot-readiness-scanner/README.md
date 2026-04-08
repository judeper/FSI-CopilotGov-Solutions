# Copilot Readiness Assessment Scanner

> **Status:** Documentation-first scaffold | **Version:** v0.3.0 | **Priority:** P0 | **Track:** A

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

The Copilot Readiness Assessment Scanner documents a six-domain Microsoft 365 readiness assessment pattern - licensing, Entra identity, Defender security, Purview compliance, Power Platform governance, and Copilot configuration - and emits representative sample scores for financial services environments. It extends Microsoft Automated Readiness Assessment patterns with regulatory weighting that reflects FINRA 3110 supervision, SEC records retention readiness, GLBA safeguard expectations, OCC model governance oversight, and FFIEC control maturity reviews while leaving live tenant connectors as explicit implementation steps.

## Features

- Provides a scanning framework across six governance domains with representative sample data; ready for Microsoft Graph API integration when deployed to a tenant.
- Uses a PowerShell scoring engine to translate technical findings into tier-aware readiness scores and control-level status outputs.
- Supports `baseline`, `recommended`, and `regulated` governance tiers with different monitoring cadence, evidence retention, and alert thresholds.
- Exports evidence packages aligned to the shared schema, including companion SHA-256 files for downstream audit handling.
- Produces Power BI-ready JSON artifacts that can be used to populate executive scorecards and remediation dashboards.
- References the redesigned Microsoft 365 Admin Center Copilot overview page (January 2026), which centralizes security configuration, readiness recommendations, and governance settings as supplemental readiness inputs.
- Tracks FSI-relevant controls 1.1, 1.5, 1.6, 1.7, and 1.9 in a format suitable for control owners, security teams, and exam preparation leads.

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft Graph APIs (scripts use representative sample data with hardcoded readiness scores)
- ❌ Does not scan Purview, SharePoint, or Exchange configurations live
- ❌ Does not deploy Power Automate flows (flow designs are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Architecture

The solution uses tiered configuration, PowerShell collection scripts, shared helper modules, and JSON evidence outputs that feed a Power BI reporting layer. See [docs/architecture.md](./docs/architecture.md) for the detailed component model, data flow, scoring logic, and shared module integration points.

## Quick Start

1. Review [docs/prerequisites.md](./docs/prerequisites.md) and confirm workload permissions, licenses, and PowerShell modules.
2. Select the target governance tier from `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
3. Update solution settings in `config\default-config.json` and the selected tier file to reflect the target tenant and operating model.
4. Run `scripts\Deploy-Solution.ps1` to validate prerequisites, confirm Graph connectivity placeholders, and write a deployment manifest.
5. Run `scripts\Monitor-Compliance.ps1` to generate a simulated readiness baseline across the six scanning domains and review the sample-data warning in the output.
6. Run `scripts\Export-Evidence.ps1` to generate the evidence package, companion hashes, and Power BI-ready artifacts.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts/CRS-Common.psm1` | Shared utility functions (configuration loading, module import, hashtable merge) used by all three scripts |
| `scripts/Deploy-Solution.ps1` | Validates local prerequisites, merges tier configuration, creates deployment manifests, and records deployment activity |
| `scripts/Monitor-Compliance.ps1` | Runs sample domain-level readiness checks, labels the output as simulated, and exports scored monitoring output for dashboard ingestion |
| `scripts/Export-Evidence.ps1` | Builds evidence artifacts and a schema-aligned package with SHA-256 companion files |
| `config/default-config.json` | Shared solution metadata, scan domain list, scoring weights, and reporting defaults |
| `config/baseline.json` | Minimum governance configuration for initial Copilot rollout assessments |
| `config/recommended.json` | Strong production posture with expanded scope and Power BI reporting enabled |
| `config/regulated.json` | High-supervision posture with long retention, broader scanning scope, and examiner-ready evidence settings |
| `docs/architecture.md` | Detailed architecture, data flow, scoring model, and shared module integration guidance |
| `docs/deployment-guide.md` | Step-by-step deployment procedure for tenant onboarding and baseline execution |
| `docs/evidence-export.md` | Evidence package contents, naming conventions, and hashing requirements |
| `docs/prerequisites.md` | Roles, workload permissions, modules, and connectivity requirements |
| `docs/troubleshooting.md` | Common deployment and monitoring issues with diagnostic steps |
| `tests/01-copilot-readiness-scanner.Tests.ps1` | Pester checks for structure, configuration, documentation, changelog, and script syntax |

## Deployment

Deploy the solution from this folder after confirming the correct governance tier and tenant access model. `Deploy-Solution.ps1` writes a manifest and deployment log entry, `Monitor-Compliance.ps1` captures a simulated readiness baseline that must be replaced by live tenant queries for production use, and `Export-Evidence.ps1` creates the evidence package used for governance review and audit support.

## Prerequisites

- Microsoft 365 licensing that supports the workloads being scanned, including Copilot licensing for the target cohort.
- Microsoft Entra and workload roles that permit read access across licensing, identity, security, compliance, SharePoint, Teams, and Power Platform governance surfaces.
- PowerShell 7.x with the required modules listed in [docs/prerequisites.md](./docs/prerequisites.md).
- Access to shared repository modules under `..\..\scripts\common\` and the shared evidence schema under `..\..\data\`.

## Related Controls

| Control | Title | Playbooks |
|---------|-------|-----------|
| 1.1 | Copilot Readiness Assessment and Data Hygiene | [Portal Walkthrough](../../docs/playbooks/control-implementations/1.1/portal-walkthrough.md) / [PowerShell Setup](../../docs/playbooks/control-implementations/1.1/powershell-setup.md) / [Verification and Testing](../../docs/playbooks/control-implementations/1.1/verification-testing.md) / [Troubleshooting](../../docs/playbooks/control-implementations/1.1/troubleshooting.md) |
| 1.5 | Sensitivity Label Taxonomy Review for Copilot | [Portal Walkthrough](../../docs/playbooks/control-implementations/1.5/portal-walkthrough.md) / [PowerShell Setup](../../docs/playbooks/control-implementations/1.5/powershell-setup.md) / [Verification and Testing](../../docs/playbooks/control-implementations/1.5/verification-testing.md) / [Troubleshooting](../../docs/playbooks/control-implementations/1.5/troubleshooting.md) |
| 1.6 | Permission Model Audit (SharePoint, OneDrive, Exchange, Teams, Graph) | [Portal Walkthrough](../../docs/playbooks/control-implementations/1.6/portal-walkthrough.md) / [PowerShell Setup](../../docs/playbooks/control-implementations/1.6/powershell-setup.md) / [Verification and Testing](../../docs/playbooks/control-implementations/1.6/verification-testing.md) / [Troubleshooting](../../docs/playbooks/control-implementations/1.6/troubleshooting.md) |
| 1.7 | SharePoint Advanced Management Readiness for Copilot | [Portal Walkthrough](../../docs/playbooks/control-implementations/1.7/portal-walkthrough.md) / [PowerShell Setup](../../docs/playbooks/control-implementations/1.7/powershell-setup.md) / [Verification and Testing](../../docs/playbooks/control-implementations/1.7/verification-testing.md) / [Troubleshooting](../../docs/playbooks/control-implementations/1.7/troubleshooting.md) |
| 1.9 | License Planning and Copilot Assignment Strategy | [Portal Walkthrough](../../docs/playbooks/control-implementations/1.9/portal-walkthrough.md) / [PowerShell Setup](../../docs/playbooks/control-implementations/1.9/powershell-setup.md) / [Verification and Testing](../../docs/playbooks/control-implementations/1.9/verification-testing.md) / [Troubleshooting](../../docs/playbooks/control-implementations/1.9/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with FINRA 3110, SEC Reg S-P, GLBA 501(b), OCC 2011-12, and the FFIEC IT Handbook by highlighting readiness gaps in supervision, data exposure, retention posture, privileged access, and governance documentation. The readiness model is designed to provide risk-weighted operational evidence rather than making an absolute compliance determination.

This solution also supports compliance with SOX 302/404 internal control requirements and the Interagency Guidance on AI (2023) by providing documented readiness evidence across governance domains.

## Evidence Export

The solution exports the following evidence types: `readiness-scorecard`, `data-hygiene-findings`, and `remediation-plan`. Each artifact receives a companion `.sha256` file, and the package file aligns to `../../data/evidence-schema.json`; see [docs/evidence-export.md](./docs/evidence-export.md) for invocation details and naming conventions.

## Known Limitations

- The repository monitor currently emits representative sample scores and findings; live Microsoft 365, Purview, SharePoint, and Power Platform API calls still require tenant-specific authentication wiring and approved service principal registration.
- Sensitivity label taxonomy quality cannot be fully validated from metadata alone and still requires compliance owner review.
- Very large tenants may require batching, API throttling controls, and staged site sampling to complete scans within operational windows.
- Power BI visuals depend on a customer-managed dataset refresh process and are not published automatically by the current script set.
- Immutable evidence storage and long-term retention controls depend on the target storage platform selected by the customer.
- Microsoft 365 Copilot licensing now includes a free Copilot Chat tier (web-grounded, included with E3/E5/Business plans), a paid Microsoft 365 Copilot tier ($30/user/month for Graph-grounded capabilities), and consumption-based Copilot agent credits. The licensing readiness domain should account for these tiers when assessing control 1.9.
- The Copilot configuration scanning domain should be updated to reference the Copilot Control System, which provides centralized Copilot feature management, agent governance, and connector oversight in the Microsoft 365 admin center.
