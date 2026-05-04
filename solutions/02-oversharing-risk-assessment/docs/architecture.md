# Architecture

## Purpose

Solution 02 provides a documentation-first but implementation-ready pattern for detecting overshared content that Microsoft 365 Copilot could surface from SharePoint, OneDrive, and Teams-connected sites. It focuses on FSI-specific exposure categories and turns raw sharing data into prioritized remediation actions.

## Text-Based Component Diagram

```text
+-----------------------------------------------+
| 01-copilot-readiness-scanner output           |
| - baseline inventory                          |
| - readiness findings                          |
| - prioritization inputs                       |
+--------------------------+--------------------+
                           |
                           v
+---------------------------------------------------------------+
| Deploy-Solution.ps1                                            |
| - loads default + tier config                                  |
| - validates dependency output                                  |
| - records deployment manifest                                  |
| - plans Restricted SharePoint Search action                    |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| Monitor-Compliance.ps1                                         |
| - SharePoint scan stubs                                        |
| - OneDrive scan stubs                                          |
| - Teams scan stubs                                             |
| - risk classification engine                                   |
+-----------+----------------------+-----------------------------+
            |                      |
            v                      v
+-----------------------+   +-----------------------+
| oversharing-findings  |   | remediation-queue     |
| - site inventory      |   | - prioritized actions |
| - risk tier           |   | - owner follow-up     |
| - anomaly counts      |   | - remediation status  |
+-----------+-----------+   +-----------+-----------+
            |                           |
            v                           v
+---------------------------------------------------------------+
| Power Automate flows                                           |
| - SiteOwnerNotification                                        |
| - RemediationApproval                                          |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| Export-Evidence.ps1                                            |
| - evidence package                                              |
| - site-owner-attestations                                       |
| - JSON + SHA-256 outputs                                        |
+---------------------------------------------------------------+
```

## Core Data Flow

1. `Deploy-Solution.ps1` loads `default-config.json` and the selected governance tier.
2. The deployment process checks that solution 01-copilot-readiness-scanner has exported baseline output that can guide workload prioritization.
3. `Monitor-Compliance.ps1` connects to workload APIs or placeholders for SharePoint, OneDrive, and Teams-backed content surfaces.
4. Raw sharing information is normalized into candidate findings with sharing scope, detected FSI signals, and permission anomaly counts.
5. The risk classification engine assigns HIGH, MEDIUM, or LOW based on the configured thresholds and weighted data-type indicators.
6. Findings feed the `oversharing-findings` dataset and create a prioritized `remediation-queue`.
7. Documentation-first Power Automate flows notify site owners, collect approvals, and route exceptions.
8. `Export-Evidence.ps1` packages findings, remediation queue records, and site owner attestations into schema-aligned JSON plus SHA-256 checksum files.

## Workload Coverage

### SharePoint

SharePoint is the primary workload because most Copilot grounding risk in M365 collaboration content comes from site permissions, broad group membership, guest access, and anyone links. The solution is intended to review:

- Site collections with broad sharing or inherited access sprawl
- Libraries and folders linked to regulated business processes
- High-value sites surfaced by Microsoft Purview Data Security Posture Management (DSPM) or upstream readiness findings

### OneDrive

OneDrive scans focus on personal sites that have been shared externally or broadly inside the enterprise. The design is especially relevant when relationship managers, lending teams, or legal staff store regulated documents in personal workspaces that later become accessible to Copilot through oversharing.

### Teams

Teams coverage is handled through site-backed content and channel context, including standard, private, and shared channel exposure patterns. The current design does not replace Teams governance tooling, but it helps flag channels whose underlying SharePoint locations or guest membership introduce elevated Copilot grounding risk.

## Risk Classification Engine

The classification engine combines sharing scope, data-type signals, and permission anomalies into a weighted score.

| Input | Example signal | Typical weight |
|-------|----------------|----------------|
| Sharing scope | Anyone link, guest access, all-employee access | 20 to 40 |
| FSI data type | customerPII, tradingData, legalDocs, regulatedRecords | 20 to 40 |
| Permission anomalies | Broken inheritance, excessive owners, stale guest grants | 5 to 20 |

Default score interpretation:

- HIGH: `>= 70`
- MEDIUM: `>= 40` and `< 70`
- LOW: `< 40`

FSI weighting is intentionally biased toward customer PII, trading data, and regulated records because those exposures create the greatest supervisory, privacy, and records-management concerns.

## Remediation Modes

| Mode | Behavior | Intended use |
|------|----------|--------------|
| `detectOnly` | Finds oversharing and produces evidence without contacting owners | Initial pilot, validation, or audit sampling |
| `notify` | Builds the remediation queue and triggers site owner notifications after review | Standard production governance |
| `autoRemediate` | Reserved for tightly controlled scenarios where approvals and rollback steps are already defined | Narrow, high-confidence automation only |

The default posture is `detectOnly` because FSI institutions typically require business-owner review before removing access to regulated content.

## Power Automate Flows

### SiteOwnerNotification

Documentation-first flow that consumes the remediation queue and sends a structured notification to the site owner or delegated business contact. Expected actions:

- Send Teams or Outlook notice with finding summary, risk tier, due date, and escalation path
- Capture owner acknowledgement and proposed remediation approach
- Update the remediation queue item with notification timestamp and response status

### RemediationApproval

Documentation-first flow used when HIGH-risk findings require approval before permission changes. Expected actions:

- Route requests to security, compliance, or records-management approvers
- Record the decision, rationale, and approver identity
- Trigger follow-up tasks for admin execution or owner attestation

## Integration with 01-copilot-readiness-scanner

Solution 01 provides the baseline readiness context used to focus solution 02 on the most relevant workloads. Typical integration points include:

- Prioritizing sites already flagged for broad access or weak hygiene
- Comparing readiness inventory volume against oversharing findings
- Using readiness evidence as the starting point for remediation planning and executive reporting

The deployment script checks for upstream output before writing the local deployment manifest so the dependency is explicit and auditable.
