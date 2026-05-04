# Architecture

## Purpose

License Governance and ROI Tracker provides a structured operating model for Copilot seat governance in financial-services environments. It combines license inventory, user-level activity signals, ROI indicators, and exception-aware reallocation recommendations so governance teams can review license consumption with management-ready evidence.

## Component Diagram

```text
+---------------------------+      +--------------------------------------+
| Microsoft Graph           |      | Dependency: 11-risk-tiered-rollout   |
| - /v1.0/users             |      | - protected users                    |
| - /v1.0/subscribedSkus    |      | - rollout wave and risk tier         |
| - /v1.0/copilot/reports   |      +-------------------+------------------+
+-------------+-------------+                          |
              |                                        |
              v                                        v
      +---------------------------------------------------------------+
      | Solution scripts and shared modules                           |
      | - Deploy-Solution.ps1                                         |
      | - Monitor-Compliance.ps1                                      |
      | - Export-Evidence.ps1                                         |
      | - IntegrationConfig.psm1, GraphAuth.psm1, EvidenceExport.psm1 |
      | - DataverseHelpers.psm1                                       |
      +-------------------------+-------------------+-----------------+
                                |                   |
                                |                   |
                                v                   v
                +---------------------------+   +---------------------------+
                | Dataverse operational     |   | Evidence package outputs  |
                | tables                    |   | JSON plus SHA-256         |
                | - fsi_cg_lgr_baseline     |   | - license-utilization     |
                | - fsi_cg_lgr_finding      |   | - roi-scorecard           |
                | - fsi_cg_lgr_evidence     |   | - reallocation queue      |
                +-------------+-------------+   +-------------+-------------+
                              |                               |
                              +---------------+---------------+
                                              |
                                              v
                                  +---------------------------+
                                  | Power BI dataset design   |
                                  | and management reporting  |
                                  +---------------------------+

Additional ROI input: Viva Insights exports or curated analyst-provided extracts.
```

## Data Flow

1. `Deploy-Solution.ps1` reads `default-config.json` and the selected tier file to establish inactivity thresholds, notification mode, retention expectations, and audit-trail depth.
2. The deployment script prepares a Graph query plan for user inventory, subscribed SKUs, and Copilot usage reports, then documents the required Dataverse tables and Power BI dataset structure.
3. `Monitor-Compliance.ps1` collects or simulates Copilot usage detail rows, applies the inactivity threshold, and calculates utilization metrics such as active seats, inactive seats, and recoverable spend.
4. Risk-tier signals from solution `11-risk-tiered-rollout` are used to identify protected populations that should not be automatically reallocated without exception review.
5. Findings are intended to be stored in `fsi_cg_lgr_finding`, while retained baseline settings and evidence references are intended to be stored in `fsi_cg_lgr_baseline` and `fsi_cg_lgr_evidence`.
6. `Export-Evidence.ps1` writes the license utilization report, ROI scorecard, and reallocation recommendation artifacts before packaging them into a JSON evidence file and a companion SHA-256 file.
7. Power BI consumes the documented dataset entities to present utilization trends, ROI views, and exception-focused review queues for license-governance stakeholders.

## Microsoft Graph Endpoints

| Endpoint | Purpose in LGR | Notes |
|----------|----------------|-------|
| `GET https://graph.microsoft.com/v1.0/users?$select=id,displayName,userPrincipalName,department,assignedLicenses,accountEnabled` | Identify licensed user population, departments, and active accounts for governance review. | Used to align seat holders to business units and reviewer routing. |
| `GET https://graph.microsoft.com/v1.0/subscribedSkus` | Inventory Microsoft 365 Copilot SKU availability and consumed units. | Supports seat planning, chargeback, and license optimization controls. |
| `GET https://graph.microsoft.com/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')` | Retrieve most recent activity data for enabled Microsoft 365 Copilot users for inactivity and utilization analysis. | Response is a report stream; tracking per-user Copilot prompt counts across tenants is not supported. |
| `GET https://graph.microsoft.com/v1.0/copilot/reports/getMicrosoft365CopilotUserCountSummary(period='D30')` | Retrieve the aggregated number of active and enabled Microsoft 365 Copilot users for management trend reporting. | Useful for Power BI trend cards and consistency checks. |

## Viva Insights ROI Signal Handling

Viva Insights data is treated as an optional enrichment source. When available, the solution expects a customer-controlled export or curated operational feed that maps business-value indicators, such as estimated time saved or scenario adoption, to business units or user cohorts. When Viva Insights is not enabled, the ROI scorecard should clearly state that the score relies only on Microsoft 365 usage reports and local management inputs.

## Power BI Dataset Description

The repository does not include a `.pbix` file. Instead, the solution documents a customer-owned dataset with the following logical tables:

| Dataset table | Purpose | Example fields |
|---------------|---------|----------------|
| `LicenseInventorySnapshot` | Stores SKU counts and allocation totals from `subscribedSkus`. | SnapshotDate, SkuName, PurchasedSeats, AssignedSeats, AvailableSeats |
| `CopilotUsageDetail` | Stores user-level usage detail from Copilot reports. | UserPrincipalName, Department, LastActivityDate, AccountEnabled, UtilizationBand |
| `VivaImpactSignals` | Stores optional ROI signals from Viva Insights or curated scorecards. | BusinessUnit, VivaImpactScore, EstimatedHoursSaved, ScenarioCoveragePct |
| `RiskTierAssignments` | Stores dependency output from solution `11-risk-tiered-rollout`. | UserPrincipalName, RiskTier, RolloutWave, ExceptionRequired |
| `ReallocationRecommendations` | Stores action-ready review records for governance meetings. | UserPrincipalName, RecommendedAction, AnnualizedRecoverableCostUsd, ManagerApprovalRequired |

Recommended Power BI measures:

- `UtilizationPct`
- `InactiveSeatCount`
- `EstimatedRecoverableSpendUsd`
- `ROISignalCoveragePct`
- `ProtectedSeatCount`

Recommended visuals:

- Seat utilization trend by reporting period
- Business-unit utilization heat map
- ROI scorecard by business unit
- Exception queue filtered by protected or high-risk users
- Control-status summary for 1.9, 4.5, 4.6, and 4.8

## Dataverse Tables

The solution uses the repository naming contract `fsi_cg_{solution}_{purpose}` with the solution code `lgr`:

| Table | Purpose | Suggested fields |
|-------|---------|------------------|
| `fsi_cg_lgr_baseline` | Stores approved tier settings and deployment assumptions. | ConfigurationTier, InactivityThresholdDays, NotificationMode, ReallocationTriggerUtilizationPct, ReportingPeriodDays, ApprovedBy |
| `fsi_cg_lgr_finding` | Stores inactive-seat and low-utilization findings. | UserPrincipalName, Department, LastActivityDate, UtilizationPct, RiskTier, RecommendedAction, FindingStatus |
| `fsi_cg_lgr_evidence` | Stores evidence package references and integrity data. | EvidenceType, PackagePath, Sha256Hash, PeriodStart, PeriodEnd, ExportedAt, Reviewer |

## Integration With Solution 11-Risk-Tiered-Rollout

Solution `11-risk-tiered-rollout` is a required dependency because license governance decisions should account for rollout wave, user sensitivity, and protected populations. LGR expects a periodically refreshed user-to-risk-tier mapping so that:

- high-risk users are routed to manual review rather than automatic reallocation,
- early adoption cohorts can be protected from premature seat reclamation,
- evidence packages can explain why a low-utilization user remained assigned, and
- management reporting can distinguish optimization opportunities from approved exceptions.

## Consumption-Based Billing Governance

Beginning April 2026, Microsoft introduced consumption-based pricing for Copilot features. This section documents the governance patterns for organizations that adopt pay-as-you-go (PAYG) messaging or prepaid message packs alongside, or instead of, traditional per-seat licensing.

### Billing Policy Assignment by Entra ID Security Group

Billing policies in the Microsoft 365 admin center control which users may consume PAYG messages. Each policy is scoped to one or more Entra ID security groups, enabling administrators to align consumption entitlements with department, business unit, or risk tier. This solution documents the recommended governance pattern: maintain a dedicated security group per billing policy, require change-management approval before group membership changes, and retain a log of policy-to-group assignments for audit review.

### Message Pack vs PAYG Cost Tracking

Organizations may choose between individual pay-as-you-go billing at $0.01 per message or prepaid 25,000-message packs at a fixed monthly rate. This solution documents the pattern for tracking consumption across both models, including message volume by user and department, pack utilization percentage, and overage forecasting. These patterns support compliance with SOX 404 cost allocation expectations by providing traceable spend data at the business-unit level.

### Azure Cost Management Integration Pattern

PAYG charges for Copilot appear in the linked Azure subscription and are visible through Azure Cost Management. This solution documents the tagging and filtering conventions recommended for financial-services organizations, including the use of the `m365copilotchat` cost-tracking tag, departmental cost-center tags, and budget alert rules. Budget alerts help meet OCC 2011-12 expectations for technology expense oversight by notifying governance teams when consumption approaches defined thresholds; they do not enforce a hard budget limit or prevent usage beyond the budget.

### High-Usage User Visibility and Alerting

High-volume message consumption may indicate productive adoption, shadow workflows, or unintended automation against the Copilot endpoint. This solution documents the pattern for identifying users whose daily message count exceeds a configurable threshold, routing high-usage findings to management review, and recording review outcomes in the evidence package. These patterns provide a framework for institutions that require periodic review of outlier consumption.

### Departmental Chargeback and Showback Model

For institutions that allocate technology costs to business units, this solution documents a chargeback and showback model that apportions PAYG and message pack costs by department based on user-level consumption data. The model supports compliance with SOX 404 expectations for cost allocation traceability and helps meet OCC 2011-12 governance requirements for technology expense reporting to business-line management.

> **Note:** All patterns described in this section are documentation-first governance scaffolds. They do not configure billing policies, create Azure budget alerts, or connect to live cost-management APIs. Implementation requires manual configuration in the Microsoft 365 admin center and Azure portal following the documented patterns.

## Security and Control Considerations

- Use application permissions with tenant-admin consent for Graph reporting workloads.
- Limit access to Dataverse tables and Power BI datasets to reviewers with a business need.
- Treat utilization data as operational management information and retain evidence according to the selected tier.
- Record exception rationale for protected users so cost optimization decisions remain challengeable and auditable.
