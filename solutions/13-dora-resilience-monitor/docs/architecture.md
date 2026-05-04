# DORA Operational Resilience Monitor Architecture

## Solution Overview

The DORA Operational Resilience Monitor (DRM) provides a repeatable monitoring and evidence pattern for Microsoft 365 Copilot dependencies in financial-services environments. It focuses on a service-health polling pattern, DORA-aligned incident classification, resilience-test tracking, and packaging outputs that can be reviewed by operations, compliance, internal audit, or examiners.

## Component Diagram

```text
+---------------------------------------------------------------+
| Microsoft Graph Service Communications API                    |
| /admin/serviceAnnouncement/healthOverviews (live target)      |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Monitor-Compliance.ps1                                        |
| - Service Health Poller                                       |
| - Incident Classifier                                         |
| - Resilience Test Status Check                                |
+------------------------------+--------------------------------+
                               |
             +-----------------+------------------+
             |                                    |
             v                                    v
+------------+-------------+        +-------------+-------------+
| Incident Register Store  |        | Resilience Test Tracker   |
| fsi_cg_dora_resilience_  |        | Scheduled exercise state  |
| monitor_finding          |        | RTO/RPO targets and gaps  |
+------------+-------------+        +-------------+-------------+
             |                                    |
             +-----------------+------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Export-Evidence.ps1                                           |
| - service-health-log                                          |
| - incident-register                                           |
| - resilience-test-results                                     |
| - JSON + SHA-256 packaging                                    |
+------------------------------+--------------------------------+
                               |
             +-----------------+------------------+
             |                                    |
             v                                    v
+------------+-------------+        +-------------+-------------+
| 12-regulatory-compliance-|        | Optional Power Automate   |
| dashboard feed           |        | flow for alerts and tasks |
+--------------------------+        +---------------------------+
```

## Data Flow

1. Microsoft Graph service communications can expose workload health details through `/admin/serviceAnnouncement/healthOverviews` when a live implementation is wired.
2. `scripts/Monitor-Compliance.ps1` currently consumes a local stub or operator-supplied sample payload, normalizes workload names, and records service-health snapshots that mirror the target contract.
3. The incident classifier maps workload degradation or outage conditions to a DORA-oriented severity outcome: major, significant, or minor.
4. The resilience test tracker evaluates whether annual operational-resilience exercises are current and whether RTO or RPO expectations have been documented.
5. `scripts/Export-Evidence.ps1` collects monitoring records, incident findings, and test results into separate JSON artifacts and then packages them with the shared evidence export module.
6. Control-state and evidence package metadata can be consumed by 12-regulatory-compliance-dashboard for enterprise reporting and evidence freshness rollup.

## Components

### Service Health Poller

The Service Health Poller queries the Microsoft Graph service communications surface for workload status across Exchange Online, SharePoint Online, Microsoft Teams, Microsoft Graph, Microsoft 365 Apps, and Microsoft Copilot. The current repository implementation is a documentation-first stub with a clear insertion point for the authenticated Graph call so the script remains testable in offline delivery environments.

> **Note:** The Service Health Poller described here provides the framework for Microsoft Graph service communications integration. The current repository version uses a local stub with representative sample data. Customer must configure Graph API authentication and endpoint binding for live service health polling.

### Incident Classifier

The Incident Classifier maps health events to DORA ICT incident severity bands:

- Major: critical service downtime longer than the major threshold or widespread user impact
- Significant: meaningful degradation, partial unavailability, or sustained customer impact below the major threshold
- Minor: short-lived or low-impact service issues that still warrant local operational logging

Classification output is intended to support compliance with DORA Art. 17 incident-management expectations and downstream root-cause analysis under control 4.9.

### Resilience Test Tracker

The Resilience Test Tracker records annual exercise due dates, reminders, RTO and RPO targets, and observed outcomes. It is designed to support compliance with control 4.10 by preserving structured evidence of recovery exercises for Copilot-dependent services.

### Evidence Packager

The Evidence Packager creates `service-health-log`, `incident-register`, and `resilience-test-results` artifacts as JSON files. Each artifact is paired with a SHA-256 hash file, and the shared `Export-SolutionEvidencePackage` function produces the overall evidence package aligned to `data/evidence-schema.json`.

### Power Automate Flow

The Power Automate Flow is documentation-first in v0.1.1. The solution describes a scheduled flow that can read monitoring output, route service alerts, create follow-up tasks, and notify resilience stakeholders, but the flow is not deployed automatically by the scripts in this repository.

## Integration Points

### Microsoft Graph

- Endpoint: `https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/healthOverviews`
- Purpose: Retrieve Microsoft 365 service-health records relevant to Copilot dependencies
- Minimum permission focus: `ServiceHealth.Read.All`

### Microsoft Sentinel Workspace

- Purpose: Optional enrichment of Copilot incident context and correlation with security or operational alerts
- Expected workspace data: customer-defined Sentinel ingestion for Copilot Studio/Purview audit events. Microsoft Learn documents these events in Purview and availability through the Office 365 Management API; this scaffold does not create a default Sentinel table.
- Customer-defined examples: custom table `CopilotActivity_CL` and analytics rules such as `DORACopilotOutage` and `CopilotResilienceFailure`, only when the tenant implementation defines and deploys them.
- Example KQL starting point, only after tenant-specific ingestion populates `CopilotActivity_CL`:

```kusto
CopilotActivity_CL
| where TimeGenerated > ago(24h)
| summarize Events = count() by UserId_s, OperationName_s
```

### 12-regulatory-compliance-dashboard

- Dependency: solution 12-regulatory-compliance-dashboard
- Purpose: Consume control-state, monitoring cadence, and evidence freshness metadata for portfolio reporting
- Integration pattern: JSON evidence artifacts and control summaries exported by `scripts/Export-Evidence.ps1`

## Dataverse Tables

The solution reserves the following Dataverse table names for structured persistence:

- `fsi_cg_dora_resilience_monitor_baseline`
- `fsi_cg_dora_resilience_monitor_finding`
- `fsi_cg_dora_resilience_monitor_evidence`

Related connection references and environment variables follow the shared contract pattern, for example:

- Connection references: `fsi_cr_dora_resilience_monitor_graph`, `fsi_cr_dora_resilience_monitor_dataverse`, `fsi_cr_dora_resilience_monitor_sentinel`
- Environment variables: `fsi_ev_dora_resilience_monitor_tenant_id`, `fsi_ev_dora_resilience_monitor_client_id`, `fsi_ev_dora_resilience_monitor_notification_channel`

## Security Considerations

- Use least-privilege Microsoft Graph permissions and assign only operational roles needed for service-health reads.
- Store client secrets or certificates in an approved secret-management platform rather than in repository files.
- Preserve evidence immutability for regulated deployments by using the immutable storage settings defined in `config/regulated.json`.
- Restrict access to incident-register and resilience-test evidence because outage narratives may contain sensitive operational details.
- Review cross-region monitoring outputs with data-residency governance teams before treating them as complete control 2.7 evidence.

## DORA Art. 17 Alignment Notes

DRM is designed to support compliance with DORA Art. 17 by documenting ICT incident detection, severity classification, reporting timestamps, and resilience-test readiness for Copilot-dependent services. The solution does not submit regulatory notices automatically; instead, it organizes the technical evidence needed for internal review, escalation, and external reporting workflows. Regulated-tier settings increase polling cadence, require richer incident metadata, and highlight missing resilience-test evidence so operations teams can close reporting gaps before an examination or supervisory review.
