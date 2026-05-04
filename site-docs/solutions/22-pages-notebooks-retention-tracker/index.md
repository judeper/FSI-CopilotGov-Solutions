# Pages and Notebooks Retention Tracker

> **Status:** Documentation-first scaffold | **Version:** v0.1.1 | **Priority:** P1 | **Track:** D

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

The Pages and Notebooks Retention Tracker (PNRT) is a documentation-first solution that helps organizations inventory Microsoft Copilot Pages, OneNote sections grouped by Notebook metadata, and embedded Loop components; track retention-policy coverage; and document Purview audit-log and version-history evidence. The repository implementation generates representative sample inventories and internal sample lineage logs so delivery teams can validate the evidence shape before wiring documented SharePoint Embedded, Microsoft Graph DriveItem/export, and Purview data sources. PNRT helps meet retention and supervisory recordkeeping expectations under SEC Rule 17a-4 (where applicable to broker-dealer required records), FINRA Rule 4511(a), and Sarbanes-Oxley §§302/404 (where applicable to ICFR).

## What This Solution Monitors

- Copilot Pages retention-policy and limited retention-label evidence, Purview audit logs, and version history
- OneNote section and folder retention-policy coverage, grouped by Notebook metadata, from SharePoint or OneDrive locations
- Loop component provenance — origin workspace, container, and parent Page or Notebook reference
- Coverage gaps where Pages, OneNote sections, or Loop components fall outside any retention label or policy

## Features

| Capability | Description |
|------------|-------------|
| Pages inventory pattern | Documents the structure for cataloging Copilot Pages with retention-policy coverage, limited retention-label evidence, source container references, and version-history context; current version uses sample data |
| Notebook retention check | Records OneNote section and folder retention coverage with Notebook metadata used only for grouping and reporting |
| Loop component lineage | Documents parent container, originating workspace, and creation context for Loop components embedded in Pages or chats |
| Internal sample lineage log | Keeps the `branching-event-log` artifact name for compatibility, but rows use repository-only sample lineage taxonomy alongside documented Purview audit/version-history context |
| Tier-aware deployment | Applies baseline, recommended, or regulated retention and audit settings |
| Evidence packaging | Exports JSON artifacts with SHA-256 companion files for the four PNRT evidence outputs |
| Documentation-first scripts | Provides representative sample data so format and schema can be validated without tenant connectivity |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not call live Microsoft Graph, SharePoint Embedded, Loop admin, or Purview endpoints (scripts emit representative sample data)
- ❌ Does not assign or modify Microsoft Purview retention labels or policies
- ❌ Does not place legal holds, eDiscovery holds, or preservation locks on Pages or Notebooks
- ❌ Does not export the underlying Page, Notebook, or Loop content (only metadata and lineage)
- ❌ Does not satisfy SEC Rule 17a-4 in isolation; Rule 17a-4 applies to specific broker-dealer required records and additional WORM-storage and supervisory controls are required
- ❌ Does not satisfy FINRA Rule 4511(a) on its own; books-and-records retention requires coordinated controls across storage, supervision, and access
- ❌ Does not deploy Power Automate flows or Dataverse tables (referenced as documentation-first patterns)

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) for the required admin roles, PowerShell modules, and Microsoft 365 prerequisites before deploying this solution.

## Architecture

The solution combines PowerShell scripts for deployment, monitoring, and evidence export with tier-specific configuration files and documentation-first guidance. See [docs/architecture.md](architecture.md) for the component overview, data flow, and integration points.

## Deployment

1. Review [docs/prerequisites.md](prerequisites.md) for Microsoft 365, Purview, and PowerShell requirements.
2. Select the governance tier and review `config/<tier-name>.json` together with `config/default-config.json`.
3. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf` to validate the manifest.
4. Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier>` to capture the initial sample inventory and lineage snapshot.
5. Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier>` to produce the JSON evidence package and matching `.sha256` files.

## Configuration Tiers

| Tier | Pages Retention (days) | OneNote Section Retention (days) | Audit / Internal Lineage Sample | Loop Provenance |
|------|------------------------|----------------------------------|--------------------------------|-----------------|
| baseline | 365 | 365 | Purview audit summary plus sample-only lineage | optional |
| recommended | 2555 (7 years) | 2555 (7 years) | Purview audit and version-history evidence plus sample-only lineage | required |
| regulated | 2555 (7 years, immutable storage expectations for in-scope records) | 2555 (7 years, immutable storage expectations for in-scope records) | Purview audit/version-history evidence plus preservation-lock expectations for in-scope records | required + signed lineage |

Retention values are recommended starting points and should be adjusted to match the customer's recordkeeping policy and the specific records subject to SEC Rule 17a-4 or FINRA Rule 4511(a).

## Evidence Export

The solution exports the following evidence artifacts:

- `pages-retention-inventory`: Copilot Pages catalog with retention-policy coverage, limited retention-label evidence, and version-history context
- `notebook-retention-log`: OneNote section and folder retention-policy coverage grouped by Notebook metadata
- `loop-component-lineage`: Loop component provenance and parent-container references
- `branching-event-log`: Repository-only internal sample lineage rows plus documented Purview audit/version-history context; not Microsoft 365 branch or fork events

Each JSON artifact is paired with a `.sha256` companion file.

## Related Controls

| Control | Role | Notes |
|---------|------|-------|
| 3.14 | Primary | Records retention for Copilot artifacts; PNRT inventories Pages and OneNote sections against retention policies and supported labels |
| 3.2 | Primary | Sensitivity and lifecycle governance for collaborative artifacts produced by Copilot |
| 3.3 | Supporting | Microsoft Purview retention policy alignment for Copilot-generated content |
| 3.11 | Supporting | eDiscovery and legal-hold readiness for Pages, Notebooks, and Loop components |
| 2.11 | Supporting | Audit and supervisory traceability for documented Purview events and internal sample lineage |

> **Playbooks:** Control implementation playbooks are maintained in the FSI-CopilotGov framework repository under `docs/playbooks/control-implementations/`.

## Regulatory Alignment

PNRT helps meet SEC Rule 17a-4 (where applicable to broker-dealer required records) by documenting retention-policy coverage, limited retention-label evidence, Purview audit-log availability, version-history context, and OneNote section/folder coverage for Copilot Pages and Notebook content that may contain communications or records subject to the rule. It supports compliance with FINRA Rule 4511(a) by documenting books-and-records retention coverage for collaborative Copilot artifacts and surfacing coverage gaps for supervisory review. It also aids in Sarbanes-Oxley §§302/404 (where applicable to ICFR) artifact preservation when Pages, Notebooks, or Loop components participate in financial reporting workflows. Use of this solution does not on its own satisfy any of these regulations; organizations should verify retention configuration with legal, compliance, and records-management teams.

## Roadmap

- v0.2.0 — Add documented SharePoint Embedded container discovery, Microsoft Graph DriveItem/export, Purview audit/retention, and Loop/Cloud Policy admin insertion points for live Page, Notebook, and component evidence.
- v0.3.0 — Add Microsoft Purview retention-policy lookup integration for supported label and policy verification paths.
- v0.4.0 — Add preservation-lock readiness and WORM storage evidence patterns aligned to SEC Rule 17a-4(f) expectations for in-scope records.
