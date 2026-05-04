# Prerequisites

## Required Solution Dependencies

- Solution `06-audit-trail-manager` deployed in the target environment
- Solution `11-risk-tiered-rollout` deployed in the target environment
- Upstream solutions that feed the coverage matrix deployed when examination readiness packages are required

## Licensing and Capacity

- Power BI Pro or Premium Per User licenses for report authors and workspace admins
- Dataverse capacity of at least 1 GB for baseline, finding, and evidence tables
- Power Automate Premium licensing for scheduled aggregation and monitoring flows
- Microsoft Purview Suite, Microsoft 365 E5/A5/G5, or the eligible Purview add-on/licensing required for the Purview Compliance Manager templates or evidence features in scope

## Required Permissions

- Fabric administrator or Power Platform administrator rights for tenant-wide settings, plus Power BI workspace Admin rights for the target workspace
- Dataverse System Administrator or a role that can create tables, connections, and environment variables
- Permission to manage Power Automate connection references
- Access to the target Power Platform environment and related service connections

## Workstation and Tooling

- PowerShell 7 for local deployment, monitoring, and evidence export scripts
- Python 3.11 for repository validation scripts
- Network access to the target Dataverse environment and Power BI service

## Shared Modules and Contracts

- `scripts/common/IntegrationConfig.psm1`
- `scripts/common/EvidenceExport.psm1`
- `scripts/common/DataverseHelpers.psm1`
- `data/evidence-schema.json`
- `data/control-coverage.json`

## Operational Readiness

- A selected governance tier: `baseline`, `recommended`, or `regulated`
- Defined evidence freshness thresholds approved by compliance stakeholders
- Confirmed Power BI workspace naming, ownership, and row-level security model
