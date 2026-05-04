# Architecture

## Purpose

Solution 19 provides a documentation-first governance framework for Microsoft 365 Copilot Tuning, an early access preview capability currently available to a limited set of customers. During public preview, only eligible tenants with at least 5,000 Microsoft 365 Copilot licenses can see Copilot Tuning settings in the Microsoft 365 admin center. The solution documents governance patterns for tuning request approval, model inventory tracking, risk assessment gates, and evidence export to support model risk management oversight.

## Text-Based Component Diagram

```text
+-----------------------------------------------+
| Tuning Request Intake                          |
| - business unit submits tuning request         |
| - identifies selected SharePoint source data   |
| - records intended use, audience, and snapshot |
+--------------------------+--------------------+
                           |
                           v
+---------------------------------------------------------------+
| Deploy-Solution.ps1                                            |
| - loads default + tier config                                  |
| - validates tuning governance prerequisites                    |
| - records deployment manifest                                  |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| Tuning Approval Workflow                                       |
| - data owner reviews source data classification                |
| - model risk officer assesses tuning risk                      |
| - compliance officer confirms regulatory alignment             |
| - approval or denial recorded to evidence                      |
+-----------+----------------------+-----------------------------+
            |                      |
            v                      v
+-----------------------+   +-----------------------+
| Monitor-Compliance    |   | Model Inventory       |
| - tuning status check |   | - tuned model catalog |
| - governance gaps     |   | - lifecycle tracking  |
| - approval compliance |   | - owner assignment    |
+-----------+-----------+   +-----------------------+
            |
            v
+---------------------------------------------------------------+
| Export-Evidence.ps1                                             |
| - tuning-requests artifact                                     |
| - model-inventory artifact                                     |
| - risk-assessments artifact                                    |
| - JSON + SHA-256 outputs                                       |
+---------------------------------------------------------------+
```

## Core Data Flow

1. `Deploy-Solution.ps1` loads `default-config.json` and the selected governance tier.
2. The deployment process validates that tuning governance prerequisites are in place.
3. Business units submit tuning requests through the documented approval workflow.
4. The intake record identifies explicitly selected SharePoint sources, sensitivity-label review needs, intended audience, and the access control list (ACL) state to capture at tuning time.
5. The approval workflow routes requests through data owner, model risk officer, and compliance officer gates before tuning proceeds in the tenant.
6. Approved tuning jobs are tracked in the model inventory with lifecycle status, tuned-agent sharing scope, and snapshot retention review dates.
7. `Monitor-Compliance.ps1` checks governance compliance status and identifies coverage gaps using representative sample data.
8. `Export-Evidence.ps1` packages tuning requests, model inventory, and risk assessments into schema-aligned JSON plus SHA-256 checksum files.

## Tuning Governance Lifecycle

### Request Phase

Tuning requests are submitted by business units and must include:

- **Selected SharePoint Sources**: Identification of the SharePoint content explicitly selected for tuning
- **Snapshot Governance**: Review of ACLs at tuning time, snapshot retention expectations, and the caveat that source SharePoint DLP and retention policies do not automatically apply to snapshot data
- **Intended Use**: Description of the business problem the tuned agent addresses
- **Target Audience**: Which users or groups will have access to the tuned agent
- **Sensitivity Label Review**: Sensitivity labels and classification considerations for the selected source data
- **Business Justification**: Rationale for why baseline Copilot is insufficient

### Approval Phase

Multi-level approval gates help ensure appropriate oversight:

- **Data Owner**: Confirms source data is appropriate for tuning and properly classified
- **Model Risk Officer**: Assesses tuning risk against institutional model risk management policy
- **Compliance Officer**: Confirms regulatory alignment and evidence requirements

### Monitoring Phase

Active tuned models are monitored for:

- Lifecycle status (pending, active, deprecated, retired)
- Owner assignment and accountability
- Periodic risk reassessment cadence
- Evidence export compliance

### Retirement Phase

Tuned models that are no longer needed or that fail risk reassessment are:

- Marked as deprecated with documented rationale
- Retired after a defined grace period
- Evidence preserved for the retention period specified by the governance tier

## Governance Tier Summary

| Tier | Tenant availability governance target | Approval Gates | Model Inventory | Risk Reassessment |
|------|--------------------------------------|----------------|-----------------|-------------------|
| Baseline | Disable tuning or limit it to approved pilot groups in the Microsoft 365 admin center for eligible preview tenants | N/A | N/A | N/A |
| Recommended | Enable tuning only for approved users or groups after workflow validation | Data owner + model risk officer | Required | Every 90 days |
| Regulated | Enable tuning only for approved users or groups with full model risk oversight | Full multi-level approval | Required with attestation | Every 30 days |

## Integration Points

This solution is designed to operate independently but can be enhanced by output from other governance solutions:

- Solution 03 (Sensitivity Label Coverage Auditor) can inform data classification decisions for tuning source data
- Solution 12 (Regulatory Compliance Dashboard) can include tuning governance evidence in compliance reporting
