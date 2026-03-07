# Architecture

## Layered architecture

### Data layer

- Microsoft 365 Unified Audit Log (UAL) with CopilotInteraction and AIInteraction events.
- Microsoft Purview retention policies and retention labels for Copilot interaction artifacts.
- Microsoft Purview eDiscovery cases, holds, custodians, and preservation state.

### Processing layer

- `Check-AuditLogCompleteness` and related operational validation steps for audit capture.
- `Set-RetentionPolicy` or equivalent Purview policy deployment actions.
- `scripts\Deploy-Solution.ps1`, `scripts\Monitor-Compliance.ps1`, and `scripts\Export-Evidence.ps1` for manifests, monitoring, and evidence export.

### Reporting layer

- Power BI dashboard for audit completeness, retention coverage, and eDiscovery readiness.
- JSON compliance outputs from `scripts\Monitor-Compliance.ps1` for downstream reporting.

### Integration layer

- Power Automate retention exception alerts.
- Dataverse-aligned naming using `fsi_cg_atm_{purpose}` for downstream integration points.

## Component diagram

```text
+-----------------------+
| Copilot interactions  |
| prompts, responses,   |
| shared files, notes   |
+-----------+-----------+
            |
            v
+-----------------------+
| Microsoft 365 Unified |
| Audit Log             |
| CopilotInteraction    |
| AIInteraction         |
+-----------+-----------+
            |
            +------------------------------+
            |                              |
            v                              v
+-----------------------+        +-----------------------+
| Purview retention     |        | Power BI dashboard    |
| policies and labels   |        | completeness metrics  |
+-----------+-----------+        +-----------------------+
            |
            +------------------------------+
            |                              |
            v                              v
+-----------------------+        +-----------------------+
| eDiscovery cases,     |        | Power Automate        |
| holds, custodians     |        | retention exceptions  |
+-----------+-----------+        +-----------------------+
            |
            v
+-----------------------+
| Export-Evidence.ps1   |
| JSON artifacts + hash |
+-----------+-----------+
            |
            v
+-----------------------+
| Examination evidence  |
| audit completeness    |
| retention coverage    |
| eDiscovery readiness  |
+-----------------------+
```

## Design notes

- UAL is the source of audit completeness evidence for Copilot interaction events.
- Purview retention policies and labels define the target preservation schedule.
- eDiscovery readiness captures whether records can be preserved and produced quickly.
- Power BI and Power Automate are documented first so implementation teams can align tenant-specific assets to the same data contract.
