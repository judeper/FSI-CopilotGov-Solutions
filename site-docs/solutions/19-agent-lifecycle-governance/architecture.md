# Architecture

Agent Lifecycle and Deployment Governance uses a documentation-first architecture built around agent discovery, approval, sharing policy auditing, monitoring, and evidence generation for Copilot agent lifecycle scenarios. The design assumes that Power Automate flows and Dataverse tables are documented and approved before workflow automation is enabled in production.

## End-to-End Flow

```text
+--------------------+    +--------------------+    +--------------------+    +--------------------+
| Agent Discovery    | -> | Risk Classifier    | -> | Approval Router    | -> | Dataverse Registry |
| M365 Admin Center  |    | published/IT/user  |    | security/CISO/biz  |    | baseline/finding   |
| Copilot Studio     |    | /blocked           |    | owner attestation  |    |                    |
+--------------------+    +--------------------+    +--------------------+    +--------------------+
                                                                                         |
                                                                                         v
                                                                               +--------------------+
                                                                               | Sharing Policy     |
                                                                               | Audit              |
                                                                               +--------------------+
                                                                                         |
                                                                                         v
                                                                               +--------------------+
                                                                               | Monitoring         |
                                                                               | daily/weekly check |
                                                                               +--------------------+
                                                                                         |
                                                                                         v
                                                                               +--------------------+
                                                                               | Evidence Export    |
                                                                               | JSON + SHA-256     |
                                                                               +--------------------+
```

## Core Components

| Component | Technology | Responsibility |
|-----------|------------|----------------|
| Agent Discovery | M365 Admin Center, Copilot Studio Admin | Enumerates Microsoft-published agents, IT-developed agents, and user-created Copilot Studio agents visible in the tenant agent catalog. |
| Risk Classifier | `Deploy-Solution.ps1` and config JSON | Applies Microsoft-published, IT-developed, user-created, or blocked treatment based on publisher type, sharing scope, data access patterns, and supervisory requirements. |
| Approval Router | Power Automate flow `ALG-ApprovalRouter` | Routes agent deployment requests through security review, business owner attestation, and CISO sign-off before recording approval or denial. |
| Sharing Policy Auditor | Power Automate flow `ALG-SharingPolicyAudit` and `Monitor-Compliance.ps1` | Audits org-wide sharing restrictions in Copilot Studio, verifies external sharing settings, and documents catalog visibility controls. |
| Dataverse Registry | Dataverse tables | Stores approved agent baseline records, findings for unapproved or risky agents, and evidence-ready sharing policy audit records. |
| Monitoring | `Monitor-Compliance.ps1` and `ALG-SharingPolicyAudit` | Detects new agents, pending approval SLA breaches, sharing policy drift, and unapproved agent distribution. |
| Evidence Export | `Export-Evidence.ps1` | Packages evidence outputs for audit, supervisory review, and DORA ICT documentation support. |

## Agent Risk Classification Model

The solution classifies agents into four risk categories based on publisher type and deployment context:

| Risk category | Description | Examples |
|---------------|-------------|----------|
| `microsoftPublished` | Agents published by Microsoft and available through the M365 Admin Center agent catalog. These agents operate within documented Microsoft service boundaries. | Microsoft 365 Copilot built-in agents, Microsoft Viva agents |
| `itDeveloped` | Agents developed by the organization's IT or engineering teams using Copilot Studio or custom development frameworks. These agents are subject to internal development governance. | Custom helpdesk agent, internal compliance assistant, IT service management agent |
| `userCreated` | Agents created by business users in Copilot Studio without formal IT oversight. These agents may access organizational data and require supervisory review before org-wide sharing. | Department-specific assistants, team productivity agents, individual workflow agents |
| `blocked` | Agents prohibited in regulated Copilot contexts due to data handling, supervisory, or compliance concerns. | Unapproved third-party agents, agents with unrestricted external data access |

## Sharing Policy Enforcement Model

The solution documents and audits three sharing policy dimensions:

| Policy dimension | Description | Audit scope |
|-----------------|-------------|-------------|
| Org-wide sharing restriction | Controls whether Copilot Studio agents can be shared with the entire organization without admin approval. | Verifies that admin-managed sharing restrictions are enabled and that user-created agents require approval before org-wide distribution. |
| External sharing policy | Controls whether agents can be shared with external users or guest accounts. | Documents external sharing settings and flags agents with external sharing enabled in regulated environments. |
| Catalog visibility | Controls which agents appear in the M365 Admin Center agent catalog and which require explicit deployment approval. | Audits catalog visibility settings and documents which agent categories are visible by default versus requiring admin action. |

## Power Automate Flow Design

The solution documents three primary flows:

| Flow | Trigger | Purpose |
|------|---------|---------|
| `ALG-AgentRegistry` | Daily recurrence | Inventories agents visible in the M365 Admin Center and Copilot Studio admin catalog, classifies risk, and refreshes Dataverse baseline or finding records. |
| `ALG-ApprovalRouter` | Triggered by new agent request or new agent finding | Assigns approval tasks, captures security review outcomes, records business owner attestation, and obtains CISO sign-off for sensitive agent deployments. |
| `ALG-SharingPolicyAudit` | Weekly recurrence | Audits org-wide sharing restrictions, external sharing policies, and catalog visibility settings, then prepares monitoring summaries. |

These flows should remain documentation-first until connection references, reviewer mailboxes, and environment IDs are approved for the target tenant.

## Dataverse Design

The solution uses the required naming convention `fsi_cg_{solution}_{purpose}` and defines the following tables:

| Table | Purpose | Example columns |
|-------|---------|-----------------|
| `fsi_cg_alg_baseline` | Approved agent baseline for the environment. | `agentId`, `displayName`, `publisherType`, `riskCategory`, `approvalStatus`, `sharingScope`, `deploymentRing`, `lastReviewedOn` |
| `fsi_cg_alg_finding` | Unapproved, risky, or blocked agents requiring operational follow-up. | `agentId`, `findingType`, `riskCategory`, `owner`, `openedOn`, `dueOn`, `remediationStatus` |
| `fsi_cg_alg_evidence` | Sharing policy audit records, approval checkpoints, and export metadata. | `artifactType`, `agentId`, `attestedBy`, `attestedOn`, `retentionDays`, `exportPath` |

## Discovery and Classification Logic

1. `ALG-AgentRegistry` or `Deploy-Solution.ps1` connects to the M365 Admin Center for agent catalog enumeration.
2. Copilot Studio admin inventory supplements discovery for user-created agents that may not appear in the centralized admin catalog.
3. The risk classifier uses the configured risk categories:
   - `microsoftPublished` for Microsoft-published agents operating within documented service boundaries
   - `itDeveloped` for organization-developed agents subject to internal development governance
   - `userCreated` for business-user-created agents that require supervisory review before broader distribution
   - `blocked` for agents prohibited in regulated Copilot contexts
4. Approval requirements are derived from the selected governance tier and written into the approval register.

## Integration with Solutions 09 and 10

Solution `09-feature-management-controller` is a dependency because approval alone is not sufficient for production enablement. After ALG records an approval decision, feature management should determine whether the agent is enabled in pilot, business, or regulated rollout rings.

Solution `10-connector-plugin-governance` is a dependency because agents may consume connectors and plugins that are themselves subject to connector governance. Agent approval should verify that any connectors or plugins used by the agent are also approved through CPG workflows.

Recommended integration points:

- Use solution 09 rollout flags to prevent newly approved agents from appearing outside approved user cohorts.
- Feed ALG findings into the feature controller so blocked or unapproved agents remain disabled even if manually deployed elsewhere.
- Cross-reference agent connector dependencies with solution 10 approval records before production enablement.
- Align exception handling so rollback decisions in solution 09 can reference ALG approval records and sharing policy audits.

## Monitoring and Evidence

`Monitor-Compliance.ps1` compares the current agent inventory to the approved baseline and flags:

- new agents that are not in the approved baseline
- unapproved or blocked agents still visible in the tenant catalog
- overdue approvals that exceeded the configured SLA
- sharing policy settings that deviate from the approved configuration
- user-created agents with org-wide sharing enabled without approval

`Export-Evidence.ps1` packages the resulting `agent-registry`, `approval-register`, and `sharing-policy-audit` records for audit support, supervisory review, and DORA ICT risk documentation.

## Security Considerations

- Agent approval workflows should verify that the requesting user has appropriate permissions to deploy agents in the target scope.
- Sharing policy audit records should be retained according to the selected governance tier retention schedule.
- User-created agents in Copilot Studio may access organizational data through the user's own permissions; approval workflows should assess data access scope as part of the risk classification.
- CISO sign-off requirements for user-created agents in regulated environments help ensure that agent deployments receive appropriate supervisory review before org-wide distribution.
