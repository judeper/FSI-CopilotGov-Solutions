# Architecture

## Purpose

License Governance and ROI Tracker provides a structured operating model for Copilot seat governance in financial-services environments. It combines license inventory, user-level activity signals, ROI indicators, and exception-aware reallocation recommendations so governance teams can review license consumption with management-ready evidence.

## Component Diagram

```text
+---------------------------+      +--------------------------------------+
| Microsoft Graph           |      | Dependency: 11-risk-tiered-rollout   |
| - /v1.0/users             |      | - protected users                    |
| - /v1.0/subscribedSkus    |      | - rollout wave and risk tier         |
| - /beta/reports/...       |      +-------------------+------------------+
+-------------+-------------+                          |
              |                                        |
              v                                        v
      +---------------------------------------------------------------+
      | Solution scripts and shared modules                           |
      | - Deploy-Solution.ps1                                         |
      | - Monitor-Compliance.ps1                                      |
      | - Export-Evidence.ps1                                         |
      | - IntegrationConfig.psm1, GraphAuth.psm1, EvidenceExport.psm1 |
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
| `GET https://graph.microsoft.com/v1.0/subscribedSkus` | Inventory Copilot for Microsoft 365 SKU availability and consumed units. | Supports seat planning, chargeback, and license optimization controls. |
| `GET https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')` | Retrieve user-level Copilot activity detail for inactivity and utilization analysis. | Response is typically a downloadable report payload; schedule accordingly. |
| `GET https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUsageUserCounts(period='D30')` | Capture aggregate active-user counts for management trend reporting. | Useful for Power BI trend cards and consistency checks. |

## Viva Insights ROI Signal Handling

Viva Insights data is treated as an optional enrichment source. When available, the solution expects a customer-controlled export or curated operational feed that maps business-value indicators, such as estimated time saved or scenario adoption, to business units or user cohorts. When Viva Insights is not enabled, the ROI scorecard should clearly state that the score relies only on Microsoft 365 usage reports and local management inputs.

## Power BI Dataset Description

The repository does not include a `.pbix` file. Instead, the solution documents a customer-owned dataset with the following logical tables:

| Dataset table | Purpose | Example fields |
|---------------|---------|----------------|
| `LicenseInventorySnapshot` | Stores SKU counts and allocation totals from `subscribedSkus`. | SnapshotDate, SkuName, PurchasedSeats, AssignedSeats, AvailableSeats |
| `CopilotUsageDetail` | Stores user-level usage detail from Copilot reports. | UserPrincipalName, Department, LastActivityDate, CopilotActions30D, UtilizationBand |
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

## Security and Control Considerations

- Use application permissions with tenant-admin consent for Graph reporting workloads.
- Limit access to Dataverse tables and Power BI datasets to reviewers with a business need.
- Treat utilization data as operational management information and retain evidence according to the selected tier.
- Record exception rationale for protected users so cost optimization decisions remain challengeable and auditable.
