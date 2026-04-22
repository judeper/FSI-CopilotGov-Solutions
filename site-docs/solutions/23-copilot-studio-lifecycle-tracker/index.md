# Copilot Studio Agent Lifecycle Tracker

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P1 | **Track:** C

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft Copilot Studio or Power Platform services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

The Copilot Studio Agent Lifecycle Tracker (CSLT) provides a documentation-first governance pattern for Microsoft Copilot Studio agents in regulated US financial-services environments. It records the full lifecycle of custom agents — authoring, testing, publishing approval, version history, and deprecation — and packages the evidence needed for supervisory review. CSLT is distinct from Solution 19 (Copilot Tuning), which addresses model fine-tuning rather than agent lifecycle governance. CSLT helps meet FFIEC IT Handbook (Operations Booklet) change-management expectations, FINRA Rule 3110 supervisory-systems and written supervisory procedure (WSP) expectations, OCC Bulletin 2023-17 third-party risk-management considerations for AI tooling built on platform services, and Sarbanes-Oxley §§302/404 change-control documentation where Copilot Studio agents touch financial reporting workflows.

## What This Solution Monitors

- Copilot Studio agent inventory across development, test, and production environments, including ownership and business sponsor metadata
- Authoring and testing activity prior to publishing, including required reviewer sign-off captured in the publishing approval log
- Publishing events, version history, and rollback history for each agent
- Deprecation notices, sunset dates, and end-of-life evidence for retired agents
- Lifecycle review cadence and overdue review findings used by supervisory and audit stakeholders

## Features

| Capability | Description |
|------------|-------------|
| Agent inventory pattern | Documents the structure for collecting Copilot Studio agent metadata across environments using a local stub payload until Power Platform admin API integration is added |
| Publishing approval log | Records reviewer identity, approval timestamp, change summary, and tier-specific approval requirements |
| Version history tracking | Captures version numbers, publish timestamps, change notes, and rollback events for each agent |
| Deprecation evidence | Records deprecation notice issuance, customer notification dates, sunset dates, and final disposition |
| Lifecycle review cadence | Flags agents that are overdue for periodic review based on the tier-configured cadence |
| Tier-aware deployment | Applies baseline, recommended, or regulated approval rigor, retention, and review cadence settings |
| Documentation-first automation | Describes the supervisory review workflow without forcing deployment-time changes to the customer Power Platform tenant |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not call the Power Platform admin API or Copilot Studio management endpoints (scripts use a local stub with representative sample data)
- ❌ Does not enforce publishing approval gates inside Copilot Studio (the approval workflow is documented and recorded, not automated)
- ❌ Does not deploy or modify Copilot Studio agents, topics, or knowledge sources
- ❌ Does not deploy Power Automate flows, Dataverse tables, or environment policies in the customer tenant
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not cover Copilot Studio model fine-tuning lifecycle — see Solution 19 (Copilot Tuning) for that scope

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) for the required admin roles, PowerShell modules, and Microsoft 365 prerequisites before deploying this solution.

## Architecture

The solution uses PowerShell scripts for deployment, monitoring, and evidence export; configuration files for tier-specific policy; and documentation-first guidance for the publishing-approval and deprecation workflows. See [docs/architecture.md](architecture.md) for the component diagram, data flow, and integration points.

## Deployment

1. Review [docs/prerequisites.md](prerequisites.md) and confirm Power Platform, Entra ID, and PowerShell requirements.
2. Select the governance tier that matches the target operating model and review `config/<tier-name>.json` together with `config/default-config.json`.
3. Run `scripts\Deploy-Solution.ps1` with `-WhatIf` first to validate the manifest and tier-specific settings.
4. Run `scripts\Monitor-Compliance.ps1` to capture an initial agent inventory and lifecycle review snapshot from the local stub or an operator-supplied sample payload.
5. Run `scripts\Export-Evidence.ps1` to generate the evidence package and verify that each JSON file has a matching `.sha256` companion.

## Configuration Tiers

| Setting | Baseline | Recommended | Regulated |
|---------|----------|-------------|-----------|
| Publishing approval required | false | true (single approver) | true (dual approver) |
| Versioning retention (days) | 365 | 1095 | 2555 |
| Deprecation notice window (days) | 30 | 60 | 90 |
| Lifecycle review cadence (days) | 180 | 90 | 30 |
| Inventory polling interval (hours) | 24 | 8 | 1 |
| Evidence retention (days) | 365 | 1095 | 2555 |
| Dual approver required | false | false | true |

See `config/baseline.json`, `config/recommended.json`, and `config/regulated.json` for full tier stubs.

## Evidence Export

The solution exports the following evidence outputs:

- `agent-lifecycle-inventory`: Copilot Studio agent inventory with environment, owner, current version, and last review timestamps
- `publishing-approval-log`: publishing events with approver identity, change summary, and approval timestamps
- `version-history`: per-agent version records with publish timestamps, change notes, and rollback entries
- `deprecation-evidence`: deprecation notices, customer notification dates, sunset dates, and final disposition records

Each artifact is a JSON file paired with a `.sha256` companion file produced by the shared evidence export module.

## Related Controls

| Control | Role | How CSLT Helps |
|---------|------|----------------|
| 4.14 | Primary | Captures the agent lifecycle, change-management, and deprecation evidence required for supervisory review |
| 4.13 | Primary | Records publishing approval, reviewer identity, and version history aligned to change-management expectations |
| 1.10 | Supporting | Provides agent inventory metadata that informs broader Copilot Studio governance posture |
| 1.16 | Supporting | Records ownership and business sponsor information that supports agent accountability and risk classification |
| 4.5 | Supporting | Surfaces lifecycle review cadence findings that contribute to ongoing assurance activities |
| 4.12 | Supporting | Preserves change-control evidence aligned to platform-level supervision and audit expectations |

> **Playbooks:** Control implementation playbooks (portal walkthroughs, PowerShell setup, verification and testing, troubleshooting) are maintained in the FSI-CopilotGov framework repository under `docs/playbooks/control-implementations/`.

## Regulatory Alignment

CSLT helps meet FFIEC IT Handbook (Operations Booklet) expectations for change management, software inventory, and operations documentation by recording the full lifecycle of Copilot Studio agents. It supports compliance with FINRA Rule 3110 (supervisory systems and written supervisory procedures) by preserving reviewer identity, approval timestamps, and supervisory follow-up evidence for agent changes. It aids in meeting OCC Bulletin 2023-17 (Third-Party Risk Management) considerations where Copilot Studio agents are built on Microsoft platform services and require ongoing oversight. Where Copilot Studio agents touch processes in scope for Sarbanes-Oxley §§302/404 internal control over financial reporting, CSLT contributes change-control documentation that supports the broader ICFR evidence set. Organizations should verify that the configured tier, approval workflow, and retention values match their specific obligations.

## Roadmap

| Version | Planned Content |
|---------|-----------------|
| v0.2.0 | Live Power Platform admin API integration pattern for agent inventory collection |
| v0.3.0 | Optional Microsoft Sentinel enrichment for Copilot Studio audit-log signals |
| v0.4.0 | Documented Power Automate flow pattern for approver routing and reminders |
