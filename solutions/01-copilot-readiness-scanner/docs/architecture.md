# Architecture

## Overview

The Copilot Readiness Assessment Scanner is a PowerShell-first solution that documents how to collect readiness signals from six Microsoft 365 governance domains, applies a financial services weighting model, and exports structured artifacts for Power BI reporting and evidence retention. The architecture is intentionally modular so customer teams can replace the repository's representative sample logic with live tenant connectors, adjust score thresholds, and add new regulatory evidence outputs without changing the repository-wide contracts.

## Component Diagram

```text
+---------------------------------------------------------------+
| Copilot Readiness Assessment Scanner                          |
+---------------------------------------------------------------+
| config/default-config.json                                    |
| config/{baseline|recommended|regulated}.json                  |
+---------------------------+-----------------------------------+
                            |
                            v
+---------------------------+-----------------------------------+
| scripts/Deploy-Solution.ps1                                  |
| - merges configuration                                        |
| - validates prerequisites                                     |
| - verifies Graph connectivity placeholder                     |
| - writes deployment manifest and log                          |
+---------------------------+-----------------------------------+
                            |
                            v
+---------------------------+-----------------------------------+
| scripts/Monitor-Compliance.ps1                               |
| - licensing scan                                              |
| - Entra identity scan                                         |
| - Defender security scan                                      |
| - Purview compliance scan                                     |
| - Power Platform governance scan                              |
| - Copilot configuration scan                                  |
+---------------------------+-----------------------------------+
                            |
                            v
+---------------------------+-----------------------------------+
| Scoring Engine                                                |
| - domain scoring                                              |
| - control weighting                                            |
| - tier threshold evaluation                                   |
| - remediation prioritization                                  |
+---------------------------+-----------------------------------+
                            |
                            v
+---------------------------+-----------------------------------+
| scripts/Export-Evidence.ps1                                  |
| - readiness-scorecard artifact                                |
| - data-hygiene-findings artifact                              |
| - remediation-plan artifact                                   |
| - evidence package and SHA-256 files                          |
+---------------------------+-----------------------------------+
                            |
                            v
+---------------------------+-----------------------------------+
| Power BI Dashboard                                             |
| - readiness scorecard                                          |
| - control status detail                                        |
| - remediation trend and exception views                        |
+---------------------------------------------------------------+
```

## Data Flow

1. `Deploy-Solution.ps1` loads `config/default-config.json` and the selected tier file, validates operator prerequisites, and records the deployment state.
2. `Monitor-Compliance.ps1` uses the merged configuration to determine which domains to scan, what thresholds to apply, and how broadly to inspect the tenant.
3. Domain scan functions currently emit representative domain findings and sample scores while marking clear insertion points for Microsoft Graph, Purview-aligned services, SharePoint Online, and Power Platform admin endpoints.
4. The scoring engine converts domain findings into weighted control scores, calculates an overall readiness posture, and assigns operational statuses. *(Note: Repository version uses representative sample data. For live implementation, customer must bind Microsoft Graph, Purview, and SharePoint endpoints with tenant-specific authentication.)*
5. `Export-Evidence.ps1` writes the readiness scorecard, data hygiene findings, and remediation plan artifacts, then creates a package aligned to the shared evidence schema.
6. Power BI ingests the JSON artifacts to provide executive dashboards, control drill-downs, and remediation views for stakeholders.

## Six Scanning Domains

| Domain | Primary Signals | Typical Data Sources | Mapped Focus Areas |
|--------|-----------------|----------------------|--------------------|
| Licensing | Copilot SKU assignment, license plan drift, cohort alignment | Microsoft Graph subscribed SKUs and user license assignments | 1.9, 1.1 |
| Entra identity | Privileged role assignment, guest access, inactive identities, conditional access dependencies | Microsoft Graph directory objects and sign-in posture | 1.6, 1.1 |
| Defender security | Exposure management, endpoint coverage, recommended hardening state | Defender and security posture APIs | 1.1, 1.6 |
| Purview compliance | Sensitivity labels, retention readiness, DLP alignment, records posture | Purview compliance endpoints and label metadata | 1.5, 1.1 |
| Power Platform governance | Environment inventory, connector risk, DLP policy coverage, maker sprawl | Power Platform admin endpoints | 1.1, 1.6 |
| Copilot configuration | Copilot service enablement, scoped readiness, app configuration drift | Microsoft 365 Copilot admin configuration surfaces | 1.1, 1.9 |

> **Admin center readiness input:** Microsoft 365 admin center Copilot > Settings scenarios provide selected Copilot management controls and shortcuts to related admin centers that can complement the scanner's domain-level assessment pattern. Organizations should review those scenarios alongside the scanner's outputs when evaluating overall Copilot readiness posture.

## Scoring Model

### Domain Scores

- Each domain returns a score from 0 to 100 based on the percentage of expected readiness checks that pass for the selected governance tier.
- Domain findings are categorized into data exposure, control gap, retention gap, or operating model exception.
- Thresholds are tier-aware and read from configuration so customers can tighten expectations as governance matures.

### Control Weighting

The default weighting model is stored in `config/default-config.json`:

- 1.1 = 30 percent
- 1.5 = 18 percent
- 1.6 = 22 percent
- 1.7 = 12 percent
- 1.9 = 18 percent

This weighting increases the impact of data hygiene, permission governance, and licensing readiness because those areas carry outsized supervisory and confidentiality risk for financial services deployments.

### Regulatory Weighting

- FINRA 3110 emphasis is reflected in stronger weight on repeatable supervision, deployment logging, and exception tracking.
- SEC records retention expectations influence control 1.7 evidence retention settings, especially in the regulated tier.
- GLBA 501(b) and FFIEC expectations are reflected in data exposure, least privilege, and governance evidence outputs.
- OCC 2011-12 considerations inform the emphasis on documented scoring inputs, deployment logging, and remediation traceability.

## Tier Differences

| Tier | Operating Intent | Scan Cadence | Threshold | Scope Expectations | Evidence Posture |
|------|------------------|--------------|-----------|--------------------|------------------|
| baseline | Minimum viable governance for initial rollout readiness | Weekly | Alert below 60 | Up to 500 sites, internal focus, no guest review | 90-day retention and summary notifications |
| recommended | Strong production posture for most regulated deployments | Daily | Alert below 75 | Up to 2,000 sites, guest review included | 180-day retention, Power BI enabled, standard notifications |
| regulated | Examination-ready posture for high-risk or heavily supervised tenants | Continuous | Alert below 90 | Full scope or unlimited site coverage, guest review included | 7-year retention, immutable evidence expectation, strict notifications |

## Integration Points With Shared Modules

The solution integrates with shared repository modules to stay aligned with repository-wide contracts:

- `..\..\..\scripts\common\IntegrationConfig.psm1` normalizes governance tiers, status scores, and evidence schema version values.
- `..\..\..\scripts\common\GraphAuth.psm1` provides the placeholder Graph context used by deployment validation and can be replaced with customer-approved authentication flows.
- `..\..\..\scripts\common\EvidenceExport.psm1` defines the repository-wide packaging and hashing pattern referenced by this solution.
- Shared modules are treated as dependencies only; solution-specific logic and artifacts remain isolated inside this solution folder.

## Evidence Integrity Considerations

The `regulated.json` tier declares `"immutableEvidenceStorage": true` and `"requireExaminerReadyEvidence": true`. However, the current scripts write deployment logs, manifests, evidence artifacts, and `.sha256` sidecar files to mutable local storage. An actor with write access to the output path could tamper with artifacts and regenerate matching hashes.

**This is a known architectural limitation.** Production deployments targeting SEC 17a-4 WORM requirements or FINRA 3110 examination-ready evidence should:

- Store evidence artifacts in WORM-capable storage (e.g., Azure Immutable Blob Storage, Compliance-locked SharePoint libraries, or third-party archival services)
- Use externally signed manifests or digital signatures to establish trust anchors independent of the artifact storage path
- Implement access controls that prevent the scanner operator from modifying previously written evidence

The `immutableEvidenceStorage` configuration flag signals the operational intent but does not enforce immutability at the storage layer. Enforcement must be provided by the target storage platform selected during deployment.

## Operational Notes

- The current scripts are documentation-first monitoring stubs that provide credible flow, structure, and outputs without embedding tenant-specific secrets or claiming live tenant collection.
- Power BI models should treat the readiness package as a staging input and keep long-term trend logic in the report dataset rather than in the scanner scripts.
- Customers with very large SharePoint estates should plan for sampling, throttling management, and off-peak execution windows.
