# Architecture

## Layered architecture

### Data layer

- Microsoft 365 Unified Audit Log (UAL) with `CopilotInteraction` events for Microsoft-developed Copilot interactions.
- Microsoft Purview retention policies for prompt/response messages in hidden user-mailbox folders; retention labels separately for supported referenced files and exported records.
- Microsoft Purview eDiscovery cases, holds, custodians, and preservation state.

### Processing layer

- Separately implemented audit validation through Microsoft Purview Audit or Exchange Online PowerShell `Search-UnifiedAuditLog`; `Check-AuditLogCompleteness` is a workflow placeholder, not a provided cmdlet.
- Microsoft Purview portal or Security & Compliance PowerShell `AppRetentionCompliancePolicy`/`AppRetentionComplianceRule` cmdlets for new **Microsoft Copilot experiences** retention policies. Older `RetentionCompliance*` cmdlets apply to supported older locations and file/label policies, not the new Copilot location.
- `scripts\Deploy-Solution.ps1`, `scripts\Monitor-Compliance.ps1`, and `scripts\Export-Evidence.ps1` for manifests, monitoring, and evidence export.

### Reporting layer

- Power BI dashboard for audit completeness, retention coverage, and Microsoft Purview eDiscovery readiness.
- JSON compliance outputs from `scripts\Monitor-Compliance.ps1` for downstream reporting.

### Integration layer

- Power Automate retention exception alerts.
- Dataverse-aligned naming using `fsi_cg_atm_{purpose}` for downstream integration points.

## Component diagram

These are parallel evidence surfaces, not a UAL-to-content-retention ingestion pipeline. Audit records describe activities; mailbox prompt/response content and referenced files have separate retention and eDiscovery paths. Reporting, alerts, and live collection require customer implementation.

```text
                 Copilot activity and content
                  /             |             \
                 v              v              v
    +----------------+ +----------------+ +----------------+
    | UAL activity   | | Mailbox prompt | | Referenced     |
    | metadata       | | and response   | | files/records  |
    | Audit log      | | Copilot content| | Supported      |
    | retention      | | retention      | | policies/labels|
    +-------+--------+ +-------+--------+ +-------+--------+
            |                  |                  |
            v                  +--------+---------+
    Audit search                        v
                                  eDiscovery
            \                           /
             +-------------------------+
             | Customer validation and |
             | sanitized summaries     |
             +------------+------------+
                          v
             Power BI / Power Automate
             (customer implementation)

    Local config -> scaffold scripts -> sample JSON + hashes
    (separate from tenant observations; no live ingestion)
```

## Design notes

- UAL is the source of audit completeness evidence for Copilot interaction events.
- Content retention policies, supported file/record labels, and audit log retention policies are distinct. Changing a content policy does not extend UAL retention.
- See [retention locations and cmdlets](https://learn.microsoft.com/purview/retention-cmdlets) and [Copilot content storage](https://learn.microsoft.com/purview/retention-policies-copilot).
- Tier eDiscovery modes, case templates, and counts describe a local readiness baseline, not native product modes or observed tenant state.
- Microsoft Purview eDiscovery readiness captures whether records can be preserved and produced quickly.
- Power BI and Power Automate are documented first so implementation teams can align tenant-specific assets to the same data contract.
