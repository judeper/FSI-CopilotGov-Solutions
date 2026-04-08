# Architecture

## Solution Overview

Copilot Pages and Notebooks Compliance Gap Monitor uses a gap-monitor pattern rather than a remediation pattern. The goal is to identify where Copilot Pages, Loop-backed content, and notebook experiences do not yet provide the books-and-records, retention, Microsoft Purview eDiscovery, or audit coverage that regulated firms need, then document the manual and administrative controls used to reduce risk until native platform support improves.

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
| - Pages retention coverage checks                              |
| - Notebook storage and Microsoft Purview eDiscovery checks                       |
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

1. Gap Discovery scans the tenant inventory and known product boundaries to identify where Pages, Loop, and notebook records may not be fully covered.
2. Classification maps each gap to the relevant regulatory requirement and control objective.
3. Compensating Control Register documents the manual or administrative control used while the platform gap remains open.
4. Preservation Exception Register records formal exception rationale, approvals, and review deadlines.
5. Evidence is exported as JSON artifacts for compliance review, audit support, and examiner discussions.

## Components

### Gap Discovery Engine
The Gap Discovery Engine inventories Copilot Pages, Loop-based content, and SharePoint-backed notebooks to determine where retention, Microsoft Purview eDiscovery, or sharing controls may not be fully covered. It is documentation-led and uses stub checks until deeper API coverage is available.

### Gap Classifier
The Gap Classifier maps each discovered issue to the relevant regulatory requirement. Primary classifications include retention, Microsoft Purview eDiscovery, security and sharing, and books-and-records preservation.

### Compensating Control Registry
The registry documents the control used to manage each open gap, such as manual exports, restricted sharing settings, enhanced audit logging, or quarterly supervisory reviews.

### Preservation Exception Register
The register creates a formal record for scenarios where a gap remains open and regulated record preservation relies on manual or procedural controls. This is especially important for SEC 17a-4 and FINRA 4511 documentation.

### Platform Update Tracker
The Platform Update Tracker monitors Microsoft Message Center and release notes for updates that may close documented gaps. Each update is reviewed before a gap is marked closed.

### Evidence Packager
The Evidence Packager writes the gap register outputs and then calls the shared `Export-SolutionEvidencePackage` function to create the evidence package and SHA-256 integrity hash.

### Power Automate Flow
The Power Automate flow is documentation-first. It routes review reminders, exception approvals, and quarterly reassessment tasks, but it does not claim to remediate retention or Microsoft Purview eDiscovery settings automatically.

## Integration Points

- Microsoft Graph for retention policy inventory, site inventory, and supporting metadata collection
- `06-audit-trail-manager` for baseline audit evidence and supporting review history
- Microsoft Message Center for monitoring platform changes that may close open gaps
- Dataverse for storing baseline entries, findings, and exported evidence references
- Power Automate for recurring review orchestration and approval routing

## Known Platform Limitations as of 2025

> **Implementation note:** `Get-PngmConfiguration` is defined in the shared module `scripts/PngmShared.psm1` and imported by all three scripts (`Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, `Export-Evidence.ps1`). The module includes file-existence validation for both the default and tier-specific configuration files.

- Copilot Pages retention policy application may lag behind traditional Exchange or Teams retention boundaries.
- Loop workspaces can have limited Microsoft Purview eDiscovery search scope in some tenant configurations.
- Notebooks in Teams are SharePoint-backed and retention is typically covered, but each tenant should verify storage paths, discovery coverage, and review evidence.
- Some gap closures depend on future Microsoft platform updates and must be validated before changing the register status.

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
