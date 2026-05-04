# Pages and Notebooks Retention Tracker

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P1 | **Track:** D

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

The Pages and Notebooks Retention Tracker (PNRT) is a documentation-first solution that helps organizations inventory Microsoft Copilot Pages, OneNote Notebooks, and embedded Loop components, track retention-policy assignment, and record branching and mutability lineage events. The repository implementation generates representative sample inventories and lineage logs so delivery teams can validate the evidence shape before wiring live Microsoft Graph, Loop, and Purview data sources. PNRT helps meet retention and supervisory recordkeeping expectations under SEC Rule 17a-4 (where applicable to broker-dealer required records), FINRA Rule 4511(a), and Sarbanes-Oxley §§302/404 (where applicable to ICFR).

## What This Solution Monitors

- Copilot Pages retention-label assignment, branching events, and mutability state changes
- OneNote Notebook retention-policy coverage and inheritance from SharePoint or OneDrive sites
- Loop component provenance — origin workspace, container, and parent Page or Notebook reference
- Coverage gaps where Pages, Notebooks, or Loop components fall outside any retention label or policy

## Features

| Capability | Description |
|------------|-------------|
| Pages inventory pattern | Documents the structure for cataloging Copilot Pages with retention label, mutability state, and branching lineage; current version uses sample data |
| Notebook retention check | Records OneNote Notebook retention-label assignment and policy inheritance from the parent site or library |
| Loop component lineage | Captures parent container, originating workspace, and creation context for Loop components embedded in Pages or chats |
| Branching event log | Records Page branching, fork, and mutability transitions to aid in supervisory record reconstruction |
| Tier-aware deployment | Applies baseline, recommended, or regulated retention and audit settings |
| Evidence packaging | Exports JSON artifacts with SHA-256 companion files for the four PNRT evidence outputs |
| Documentation-first scripts | Provides representative sample data so format and schema can be validated without tenant connectivity |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not call Microsoft Graph, Loop, or Purview APIs (scripts emit representative sample data)
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

| Tier | Pages Retention (days) | Notebook Retention (days) | Branching Audit | Loop Provenance |
|------|------------------------|---------------------------|-----------------|-----------------|
| baseline | 365 | 365 | summary | optional |
| recommended | 2555 (7 years) | 2555 (7 years) | full | required |
| regulated | 2555 (7 years, immutable) | 2555 (7 years, immutable) | full + preservation lock | required + signed lineage |

Retention values are recommended starting points and should be adjusted to match the customer's recordkeeping policy and the specific records subject to SEC Rule 17a-4 or FINRA Rule 4511(a).

## Evidence Export

The solution exports the following evidence artifacts:

- `pages-retention-inventory`: Copilot Pages catalog with retention-label assignment and mutability state
- `notebook-retention-log`: OneNote Notebook retention-policy assignment and inheritance lineage
- `loop-component-lineage`: Loop component provenance and parent-container references
- `branching-event-log`: Page branching, fork, and mutability transition events

Each JSON artifact is paired with a `.sha256` companion file.

## Related Controls

| Control | Role | Notes |
|---------|------|-------|
| 3.14 | Primary | Records retention for Copilot artifacts; PNRT inventories Pages and Notebooks against retention labels |
| 3.2 | Primary | Sensitivity and lifecycle governance for collaborative artifacts produced by Copilot |
| 3.3 | Supporting | Microsoft Purview retention policy alignment for Copilot-generated content |
| 3.11 | Supporting | eDiscovery and legal-hold readiness for Pages, Notebooks, and Loop components |
| 2.11 | Supporting | Audit and supervisory traceability for Copilot artifact lifecycle events |

> **Playbooks:** Control implementation playbooks are maintained in the FSI-CopilotGov framework repository under `docs/playbooks/control-implementations/`.

## Regulatory Alignment

PNRT helps meet SEC Rule 17a-4 (where applicable to broker-dealer required records) by recording retention-policy assignment, mutability state, and lineage for Copilot Pages and OneNote Notebooks that may contain communications or records subject to the rule. It supports compliance with FINRA Rule 4511(a) by documenting books-and-records retention coverage for collaborative Copilot artifacts and surfacing coverage gaps for supervisory review. It also aids in Sarbanes-Oxley §§302/404 (where applicable to ICFR) artifact preservation when Pages, Notebooks, or Loop components participate in financial reporting workflows. Use of this solution does not on its own satisfy any of these regulations; organizations should verify retention configuration with legal, compliance, and records-management teams.

## Roadmap

- v0.2.0 — Add Microsoft Graph and Loop API insertion points for live Page, Notebook, and component enumeration.
- v0.3.0 — Add Microsoft Purview retention-policy lookup integration for label inheritance verification.
- v0.4.0 — Add preservation-lock and immutability evidence pattern aligned to SEC Rule 17a-4(f) WORM expectations for in-scope records.
