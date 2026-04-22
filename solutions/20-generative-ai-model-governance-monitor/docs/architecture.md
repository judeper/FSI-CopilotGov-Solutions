# Generative AI Model Governance Monitor Architecture

## Solution Overview

The Generative AI Model Governance Monitor (GMG) provides a documentation-first model risk management (MRM) monitoring pattern for Microsoft 365 Copilot. It applies Federal Reserve SR 11-7 / OCC Bulletin 2011-12 principles to a vendor-supplied generative AI system during the period in which SR 26-2 / OCC Bulletin 2026-13 explicitly excludes generative AI from its scope.

## Component Diagram

```text
+--------------------------------------------------------------+
| Manual operator input (sample inventory + monitoring data)   |
+------------------------------+-------------------------------+
                               |
                               v
+------------------------------+-------------------------------+
| Monitor-Compliance.ps1                                       |
| - Inventory snapshot builder (representative sample)         |
| - Validation status check                                    |
| - Ongoing monitoring observations                            |
| - Third-party due diligence cadence check                    |
+------------------------------+-------------------------------+
                               |
                               v
+------------------------------+-------------------------------+
| Export-Evidence.ps1                                          |
| - copilot-model-inventory                                    |
| - validation-summary                                         |
| - ongoing-monitoring-log                                     |
| - third-party-due-diligence                                  |
| - JSON + SHA-256 sidecars                                    |
+--------------------------------------------------------------+
                               |
                               v
+--------------------------------------------------------------+
| Manual handoff to model risk committee and compliance review |
+--------------------------------------------------------------+
```

## Data Flow

1. The operator selects a governance tier and runs `Deploy-Solution.ps1` to produce a deployment manifest reflecting the inventory review cadence, validation requirement, monitoring cadence, and third-party review cadence.
2. `Monitor-Compliance.ps1` builds a representative sample inventory snapshot for Microsoft 365 Copilot, Copilot Chat, and Copilot Agents, then records validation, monitoring, and vendor-review status.
3. `Export-Evidence.ps1` writes four JSON evidence artifacts and a SHA-256 sidecar for each.
4. The artifacts are reviewed by the model risk officer and the model risk committee through manual workflow steps documented in `docs/deployment-guide.md`.

## Components

### Inventory Snapshot Builder

Documents how Copilot is registered in the firm's model inventory. The current repository version emits a representative sample inventory record so the structure can be reviewed before live data is available.

### Validation Status Check

Records the validation scope adapted for vendor-supplied generative AI models. Because Microsoft does not expose the underlying foundation model parameters, validation activity is limited to conceptual soundness review, output testing on representative use cases, and a documented limitations log.

### Ongoing Monitoring

Captures sampling cadence, output review observations, user feedback signals, drift indicators, and escalation thresholds. The repository version uses sample data; live integration with Microsoft Graph or Purview is deferred.

### Third-Party Due Diligence

Records the cadence and content of vendor governance review for Microsoft as the model provider. Reviewers should reference Microsoft's published Responsible AI documentation, SOC reports, and Copilot transparency notes.

## Integration Points (Future)

These integrations are documented but not implemented in v0.1.0:

- **Microsoft Graph audit logs** — Copilot interaction telemetry to support output sampling
- **Microsoft Purview** — sensitivity-labeled prompt and response review
- **Microsoft Sentinel** — alert correlation for AI incident response (control 3.12)
- **Dataverse model inventory tables** — structured persistence for inventory and validation records

## Dataverse Tables (Reserved Names)

- `fsi_cg_genai_model_governance_inventory`
- `fsi_cg_genai_model_governance_validation`
- `fsi_cg_genai_model_governance_monitoring`
- `fsi_cg_genai_model_governance_vendor_review`

## Security Considerations

- Treat the model inventory and validation findings as sensitive material; restrict access to model risk and compliance roles.
- Preserve evidence immutability for regulated deployments using the storage account environment variable `GMG_IMMUTABLE_STORAGE_ACCOUNT`.
- Avoid embedding any user-prompt content in evidence artifacts unless the firm's data classification policy allows it.

## Regulatory Alignment Notes

GMG is designed to support compliance with SR 11-7 / OCC Bulletin 2011-12 model-risk principles for generative AI, which continue to be applied as interim guidance after SR 26-2 / OCC Bulletin 2026-13 excluded generative AI from its scope. The solution does not on its own constitute model validation; it organizes the artifacts the model risk officer and validation team need to perform that work.
