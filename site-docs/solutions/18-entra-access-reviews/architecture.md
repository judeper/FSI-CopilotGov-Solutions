# Architecture

## Purpose

Solution 18 provides a documentation-first but implementation-ready pattern for automating Entra ID Access Reviews across SharePoint sites that Microsoft 365 Copilot can surface during grounded responses. It uses risk scores from solution 02 to prioritize review creation and set review cadence proportional to each site's oversharing risk tier.

## Text-Based Component Diagram

```text
+-----------------------------------------------+
| 02-oversharing-risk-assessment output          |
| - risk-scored site inventory                   |
| - HIGH / MEDIUM / LOW classifications          |
| - oversharing findings                         |
+--------------------------+--------------------+
                           |
                           v
+---------------------------------------------------------------+
| Deploy-Solution.ps1                                            |
| - loads default + tier config                                  |
| - validates upstream risk score output                         |
| - records deployment manifest                                  |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| New-AccessReview.ps1                                           |
| - reads risk scores from upstream output                       |
| - creates review definitions via Graph API patterns            |
| - sets cadence per risk tier (30 / 90 / 180 days)              |
| - assigns site owner as reviewer                               |
+-----------+----------------------+-----------------------------+
            |                      |
            v                      v
+-----------------------+   +-----------------------+
| Get-ReviewResults.ps1 |   | access-review-defs    |
| - queries decisions   |   | - review definitions  |
| - flags near-expiry   |   | - cadence settings    |
| - escalation alerts   |   | - reviewer assignment  |
+-----------+-----------+   +-----------------------+
            |
            v
+---------------------------------------------------------------+
| Apply-ReviewDecisions.ps1                                      |
| - applies deny decisions                                       |
| - removes access from SharePoint sites                         |
| - logs all actions to evidence                                 |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| Export-Evidence.ps1                                             |
| - access-review-definitions artifact                           |
| - review-decisions artifact                                    |
| - applied-actions artifact                                     |
| - JSON + SHA-256 outputs                                       |
+---------------------------------------------------------------+
```

## Core Data Flow

1. `Deploy-Solution.ps1` loads `default-config.json` and the selected governance tier.
2. The deployment process checks that solution 02-oversharing-risk-assessment has exported risk-scored site output.
3. `New-AccessReview.ps1` reads risk scores and creates Entra ID Access Review definitions via `POST /identityGovernance/accessReviews/definitions`.
4. Reviews are created in priority order: HIGH-risk sites first, then MEDIUM, then LOW.
5. Review scope targets SharePoint site members and guests; reviewer is set to the site owner.
6. Review cadence and duration are driven by `config/review-schedule.json` settings per risk tier.
7. `Get-ReviewResults.ps1` queries `GET /identityGovernance/accessReviews/definitions/{id}/instances/{id}/decisions` for pending and completed decisions.
8. Reviews approaching expiry (within 48 hours) are flagged for escalation.
9. `Apply-ReviewDecisions.ps1` applies deny decisions via `POST .../decisions/apply` and logs all actions.
10. `Export-Evidence.ps1` packages review definitions, decisions, and applied actions into schema-aligned JSON plus SHA-256 checksum files.

## Review Lifecycle

### Creation Phase

Access reviews are created for each SharePoint site based on its risk tier. The review definition includes:

- **Scope**: Site members and guest users
- **Reviewer**: Site owner (resolved from SharePoint site properties), with compliance officer fallback
- **Duration**: 7 days for HIGH, 14 days for MEDIUM and LOW
- **Recurrence**: Every 30, 90, or 180 days depending on risk tier

### Monitoring Phase

Active reviews are monitored for:

- Pending decisions that have not been completed
- Reviews approaching expiry within the configured reminder window (default 48 hours)
- Reviewer responsiveness and escalation needs

### Decision Application Phase

Completed review decisions are processed:

- **Approve** decisions maintain current access
- **Deny** decisions trigger access removal from the SharePoint site
- All decisions are logged to the evidence file with timestamps and reviewer identity

## Risk Tier Cadence

| Risk Tier | Review Frequency | Duration | Justification |
|-----------|-----------------|----------|---------------|
| HIGH | Every 30 days | 7 days | Sites with customer PII, trading data, or regulated records require frequent recertification |
| MEDIUM | Every 90 days | 14 days | Sites with broad internal sharing need quarterly review |
| LOW | Every 180 days | 14 days | Sites with targeted sharing receive semi-annual review |

## Integration with 02-oversharing-risk-assessment

Solution 02 provides the risk-scored site inventory that drives review prioritization. Typical integration points include:

- Using HIGH/MEDIUM/LOW risk classifications to set review cadence
- Anchoring review creation to documented oversharing findings
- Correlating review outcomes with remediation queue items from solution 02

The deployment script checks for upstream output before writing the local deployment manifest so the dependency is explicit and auditable.

## Orchestrator Pattern

`Invoke-RiskTriagedReviews.ps1` coordinates the full lifecycle:

1. Read risk scores from solution 02 output
2. Create access reviews for HIGH-risk sites
3. Collect review results
4. Apply completed decisions
5. Export evidence package

This provides a single entry point for scheduled automation while keeping individual scripts available for targeted operations.
