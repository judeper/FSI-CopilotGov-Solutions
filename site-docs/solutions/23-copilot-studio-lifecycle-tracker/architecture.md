# Copilot Studio Agent Lifecycle Tracker Architecture

## Solution Overview

The Copilot Studio Agent Lifecycle Tracker (CSLT) provides a documentation-first pattern for governing Microsoft Copilot Studio agent lifecycle evidence in regulated US financial-services environments. It records agent inventory, publishing approval, version/change records, and deprecation evidence, and aligns the local evidence pattern with Microsoft Agent 365 centralized registry and lifecycle-governance context where licensed. These records support FFIEC IT Handbook (Operations Booklet), FINRA Rule 3110 (supervisory systems and WSPs), OCC Bulletin 2023-17 (Third-Party Risk Management), and Sarbanes-Oxley §§302/404 change-control documentation where applicable to ICFR.

## Component Diagram

```text
+---------------------------------------------------------------+
| Microsoft Agent 365 registry + Power Platform metadata APIs   |
| (target integrations; current version uses local stub)        |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Monitor-Compliance.ps1                                        |
| - Agent Inventory Collector                                   |
| - Publishing Approval Recorder                                |
| - Lifecycle Review Evaluator                                  |
| - Deprecation Tracker                                         |
+------------------------------+--------------------------------+
                               |
             +-----------------+------------------+
             |                                    |
             v                                    v
+------------+-------------+        +-------------+-------------+
| Approval Log Store       |        | Version & Deprecation     |
| Reviewer identity, tier  |        | History Store             |
| approval requirements    |        | Publish, change, sunset   |
+------------+-------------+        +-------------+-------------+
             |                                    |
             +-----------------+------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Export-Evidence.ps1                                           |
| - agent-lifecycle-inventory                                   |
| - publishing-approval-log                                     |
| - version-history                                             |
| - deprecation-evidence                                        |
| - JSON + SHA-256 packaging                                    |
+---------------------------------------------------------------+
```

## Data Flow

1. Microsoft Agent 365 provides centralized agent registry and lifecycle-governance context where licensed; Power Platform API or SDK surfaces can provide environment and resource metadata when a live implementation is wired and supported source fields are mapped.
2. `scripts/Monitor-Compliance.ps1` currently consumes a local stub or operator-supplied sample payload, normalizes agent records, and applies tier-specific approval and review requirements.
3. The publishing approval recorder enforces, for the selected tier, whether approval is required and whether dual-approver evidence must be present.
4. The lifecycle review evaluator flags agents whose last review timestamp is older than the configured cadence.
5. `scripts/Export-Evidence.ps1` collects records into separate JSON artifacts and packages them with the shared evidence export module.

## Components

### Agent Inventory Collector

The Agent Inventory Collector is intended to reconcile Microsoft Agent 365 registry context where licensed with Power Platform environment and resource metadata across configured environments. The current repository version uses a local stub with representative sample data. Customers must configure supported API or SDK authentication, endpoint binding, and RBAC role assignments before live inventory collection.

### Publishing Approval Recorder

The Publishing Approval Recorder captures reviewer identity, change summary, approval timestamp, and tier-specific approver counts. It supports compliance with FINRA Rule 3110 supervisory expectations by preserving the supervisory record associated with each agent change.

### Lifecycle Review Evaluator

The Lifecycle Review Evaluator compares the most recent review timestamp for each agent against the tier-configured review cadence and surfaces overdue findings for follow-up. It aids in meeting FFIEC IT Handbook (Operations Booklet) expectations for periodic review of operational software.

### Deprecation Tracker

The Deprecation Tracker records deprecation notices, customer notification dates, sunset dates, and final disposition for retired agents. It contributes records-retention evidence aligned to firm policy and to Sarbanes-Oxley §§302/404 change-control documentation where Copilot Studio agents touch financial reporting workflows.

### Evidence Packager

The Evidence Packager creates `agent-lifecycle-inventory`, `publishing-approval-log`, `version-history`, and `deprecation-evidence` artifacts as JSON files with SHA-256 companion files.

## Integration Points

### Microsoft Agent 365 registry

- Purpose: Use Microsoft control-plane context for centralized agent registry, lifecycle management, access control, and compliance where licensed
- Status: Documented integration target; current repository version uses a local stub

### Power Platform REST API/SDK metadata

- Purpose: Retrieve environment and resource metadata for Copilot Studio agents when supported endpoints and RBAC assignments are configured
- Status: Documented integration target; current repository version uses a local stub

### Microsoft Purview Audit (optional)

- Purpose: Optional enrichment with Copilot Studio audit-log signals where Purview is licensed and configured
- Status: Documented; not implemented in v0.1.1

## Dataverse Tables

The solution reserves the following Dataverse table names for structured persistence:

- `fsi_cg_copilot_studio_lifecycle_inventory`
- `fsi_cg_copilot_studio_lifecycle_approval`
- `fsi_cg_copilot_studio_lifecycle_version`
- `fsi_cg_copilot_studio_lifecycle_deprecation`

## Security Considerations

- Use least-privilege Microsoft Agent 365, Power Platform, Entra ID, and Purview permissions for the monitoring identity.
- Store client secrets or certificates in an approved secret-management platform rather than in repository files.
- Restrict access to publishing approval and deprecation evidence because change records may contain reviewer identities and sensitive operational details.
- Preserve evidence immutability for regulated deployments using the immutable storage settings defined in `config/regulated.json`.
