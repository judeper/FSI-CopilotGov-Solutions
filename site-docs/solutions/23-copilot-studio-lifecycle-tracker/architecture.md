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
- Admin center navigation: Microsoft 365 admin center **> Agents > All Agents > Registry**
- Status: Documented integration target; current repository version uses a local stub

### Power Platform REST API/SDK metadata

- Purpose: Retrieve environment and resource metadata for Copilot Studio agents when supported endpoints and RBAC assignments are configured
- Status: Documented integration target; current repository version uses a local stub

### Microsoft Purview Audit (optional)

- Purpose: Optional enrichment with Copilot Studio audit-log signals where Purview is licensed and configured
- Status: Documented; not implemented in v0.1.4

## Dataverse Tables

The solution reserves the following Dataverse table names for structured persistence:

- `fsi_cg_copilot_studio_lifecycle_inventory`
- `fsi_cg_copilot_studio_lifecycle_approval`
- `fsi_cg_copilot_studio_lifecycle_version`
- `fsi_cg_copilot_studio_lifecycle_deprecation`

## Application Lifecycle Management (ALM)

Copilot Studio agents and their supporting Dataverse components are packaged and moved
between environments using Power Platform solutions. This solution documents the ALM
pattern; it does not export, import, or publish agents in the customer tenant.

- **Solutions and export/import:** Agents are added to a Power Platform solution and exported
  from the development environment, then imported into test and production environments. See
  [Export and import agents using solutions](https://learn.microsoft.com/microsoft-copilot-studio/authoring-solutions-import-export)
  and [Establish an application lifecycle management strategy](https://learn.microsoft.com/microsoft-copilot-studio/guidance/alm).
- **Managed vs. unmanaged:** Development uses unmanaged solutions; downstream environments
  receive managed solutions so components are not customized directly. See
  [Create and manage solutions in Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/authoring-solutions-overview).
- **Environment variables and connection references:** The `fsi_ev_*` environment variables
  and `fsi_cr_*` connection references in the deployment manifest are the recommended pattern
  for parameterizing per-environment values so that no secrets or environment-specific
  identifiers are stored in the solution. See
  [Variables overview](https://learn.microsoft.com/microsoft-copilot-studio/authoring-variables-about#environment-variables).
- **Pipelines:** Power Platform solution pipelines can automate deployment of the solution
  across environments as part of a supported CI/CD approach.
- **Publishing requirement:** A Copilot Studio agent must be published in the target
  environment before changes become available to users. Microsoft also documents that agents
  must be republished after administrators update environment variables, except for secret-type
  environment variables. See [Publish and deploy your agent](https://learn.microsoft.com/microsoft-copilot-studio/publication-fundamentals-publish-channels)
  and [Variables overview](https://learn.microsoft.com/microsoft-copilot-studio/authoring-variables-about#environment-variables).

## Security Considerations

- Use least-privilege Microsoft Agent 365, Power Platform, Entra ID, and Purview permissions for the monitoring identity.
- Store client secrets or certificates in an approved secret-management platform rather than in repository files.
- Restrict access to publishing approval and deprecation evidence because change records may contain reviewer identities and sensitive operational details.
- Treat the regulated `evidenceImmutability` block as an external storage requirement. The scaffold does not provision WORM storage or prove evidence immutability.
