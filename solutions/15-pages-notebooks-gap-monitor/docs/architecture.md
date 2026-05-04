# Architecture

## Solution Overview

Copilot Pages and Notebooks Compliance Gap Monitor uses a gap-monitor pattern rather than a remediation pattern. The goal is to identify documented platform limitations and tenant validation items for Copilot Pages, Copilot Notebooks, Loop content, and SharePoint Embedded containers, then document the manual and administrative controls used to reduce residual risk. The pattern recognizes that Microsoft Purview retention policies and eDiscovery are supported for Pages, Notebooks, and Loop, while tracking limitations such as review-set full-text search, legal-hold container scoping, retention-label behavior, and Information Barriers for SharePoint Embedded.

The solution supports compliance with SEC 17a-4, FINRA 4511, and SOX 404 by creating an auditable chain from gap discovery to exception review and evidence export. It does not directly change tenant retention policies or Microsoft Purview eDiscovery settings.

## ASCII Component Diagram

+---------------------------------------------------------------+
| Microsoft 365 tenant                                          |
| Copilot Pages | Loop workspaces | Teams notebooks | SharePoint|
+-------------------------------+-------------------------------+
                                |
                                v
+---------------------------------------------------------------+
| Gap Discovery Engine                                           |
| - Pages retention policy validation checks                    |
| - Notebook storage and eDiscovery limitation checks             |
| - Sharing and access review prompts                            |
+-------------------------------+-------------------------------+
                                |
                                v
+---------------------------------------------------------------+
| Gap Classifier                                                 |
| - Retention mapping                                            |
| - Microsoft Purview eDiscovery mapping                                           |
| - Audit and books-and-records mapping                          |
+-------------------+----------------------+---------------------+
                    |                      |
                    v                      v
+-------------------------+      +--------------------------------+
| Compensating Control    |      | Preservation Exception         |
| Registry                |      | Register                       |
| - Manual export         |      | - SEC 17a-4 exceptions         |
| - Access restriction    |      | - FINRA 4511 rationale         |
| - Enhanced logging      |      | - Approval and expiry review   |
+------------+------------+      +----------------+---------------+
             \                              /
              \                            /
               v                          v
+---------------------------------------------------------------+
| Evidence Packager                                              |
| - gap-findings                                                 |
| - compensating-control-log                                     |
| - preservation-exception-register                              |
+-------------------------------+-------------------------------+
                                |
                                v
+---------------------------------------------------------------+
| Compliance review workflow                                     |
| Power Automate flow, legal review, quarterly reassessment      |
+---------------------------------------------------------------+

## Data Flow

1. Gap Discovery reviews current Microsoft guidance and tenant inventory assumptions to identify documented limitations and validation items for Pages, Loop, and notebook records.
2. Classification maps each item to the relevant regulatory requirement and control objective.
3. Compensating Control Register documents the manual or administrative control used while a documented limitation or tenant validation item remains open.
4. Preservation Exception Register records formal exception rationale, approvals, and review deadlines.
5. Evidence is exported as JSON artifacts for compliance review, audit support, and examiner discussions.

## Components

### Gap Discovery Engine
The Gap Discovery Engine inventories Copilot Pages, Copilot Notebooks, Loop content, and SharePoint-backed or SharePoint Embedded storage patterns to determine which documented limitations and tenant validation items apply. It is documentation-led and uses stub checks until deeper API coverage is available.

### Gap Classifier
The Gap Classifier maps each discovered item to the relevant regulatory requirement. Primary classifications include retention, Microsoft Purview eDiscovery, security and sharing, and books-and-records preservation.

### Compensating Control Registry
The registry documents the control used to manage each open limitation or validation item, such as manual exports, restricted sharing settings, enhanced audit logging, or quarterly supervisory reviews.

### Preservation Exception Register
The register creates a formal record for scenarios where a documented limitation remains open and regulated record preservation relies on manual or procedural controls. This is especially important for SEC 17a-4 and FINRA 4511 documentation.

### Platform Update Tracker
The Platform Update Tracker monitors Microsoft Message Center and release notes for updates that may change documented limitations. Each update is reviewed before an item is marked closed.

### Evidence Packager
The Evidence Packager writes the gap register outputs and then calls the shared `Export-SolutionEvidencePackage` function to create the evidence package and SHA-256 integrity hash.

### Power Automate Flow
The Power Automate flow is documentation-first. It routes review reminders, exception approvals, and quarterly reassessment tasks, but it does not claim to remediate retention or Microsoft Purview eDiscovery settings automatically.

## Integration Points

- Microsoft Graph for site, SharePoint Embedded container, and sensitivity-label metadata collection; Microsoft Purview administrative tooling for retention policy inventory
- `06-audit-trail-manager` for baseline audit evidence and supporting review history
- Microsoft Message Center for monitoring platform changes that may change open limitations
- Dataverse for storing baseline entries, findings, and exported evidence references
- Power Automate for recurring review orchestration and approval routing

## Current Platform Support and Limitations

> **Implementation note:** `Get-PngmConfiguration` is defined in the shared module `scripts/PngmShared.psm1` and imported by all three scripts (`Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, `Export-Evidence.ps1`). The module includes file-existence validation for both the default and tier-specific configuration files.

- Copilot Pages create `.page` files and Copilot Notebooks create `.pod` files in user-owned SharePoint Embedded containers that can also be used by Loop My workspace.
- Purview retention policies configured for all SharePoint sites are enforced for Copilot Pages, Copilot Notebooks, and `.loop` files; regulated tenants should still validate policy scope and evidence before relying on the sample register.
- Purview eDiscovery supports search/collection, review, and export for Pages, Notebooks, and Loop, but full-text search within `.page` and `.loop` files in review sets is not available.
- Legal hold is supported, but the SharePoint Embedded container must be added per user; users placed on Litigation Hold do not automatically include Copilot Pages, Copilot Notebooks, or Loop My workspace containers.
- Retention labels have limited manual support, and Information Barriers are not supported for content stored in SharePoint Embedded containers.

## Dataverse and Configuration Artifacts

### Dataverse tables
- `fsi_cg_pages_notebooks_gap_monitor_baseline`
- `fsi_cg_pages_notebooks_gap_monitor_finding`
- `fsi_cg_pages_notebooks_gap_monitor_evidence`

### Connection references
- `fsi_cr_pages_notebooks_gap_monitor_graph`
- `fsi_cr_pages_notebooks_gap_monitor_dataverse`
- `fsi_cr_pages_notebooks_gap_monitor_messagecenter`

### Environment variables
- `fsi_ev_pages_notebooks_gap_monitor_gap_review_frequency_days`
- `fsi_ev_pages_notebooks_gap_monitor_platform_update_check_frequency_days`
- `fsi_ev_pages_notebooks_gap_monitor_exception_review_owner`
