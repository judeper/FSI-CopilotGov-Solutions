# Architecture

## Objective

Conditional Access Policy Automation for Copilot provides a documented control plane for Copilot access decisions, policy drift monitoring, and exception governance. The design assumes that data-governance protections from `05-dlp-policy-governance` are already in place.

## Architecture layers

| Layer | Components | Responsibility |
|-------|------------|----------------|
| Policy layer | Microsoft Entra Conditional Access, named locations, MFA, compliant-device grant controls | Enforces access patterns for Microsoft 365 Copilot and Copilot Studio |
| Automation layer | `scripts\Deploy-Solution.ps1`, `scripts\Monitor-Compliance.ps1`, `scripts\Export-Evidence.ps1` | Generates templates, validates tier alignment, and packages evidence |
| Monitoring layer | Scheduled drift detection, Power Automate exception approval, audit review workflow | Highlights unauthorized or unapproved policy changes and routes exception decisions for approval |
| Evidence layer | `ca-policy-state`, `drift-alert-summary`, `access-exception-register` | Produces evidence artifacts aligned to the shared schema |

## Policy layer

The policy layer is implemented in Microsoft Entra Conditional Access and should target the Copilot application IDs defined in `config\default-config.json`. Policies are organized around risk tiers:

- Low: authenticated access with the selected tier safeguards.
- Medium: stronger authentication and device requirements for elevated users.
- High: strongest controls, including named locations and device-state restrictions.

## Automation layer

The automation layer runs in PowerShell:

- `Deploy-Solution.ps1` builds Copilot Conditional Access policy templates, a deployment manifest, and a baseline snapshot stub.
- `Monitor-Compliance.ps1` validates tier settings, compares the approved baseline to the current policy definition, and checks for expired exceptions.
- `Export-Evidence.ps1` writes evidence artifacts, their SHA-256 companions, and the shared evidence package.

> **Note on shared utility functions:** `Read-JsonFile`, `Resolve-ConfiguredPath`, `Merge-Configuration`, and `New-PolicyTemplate` are duplicated across all three scripts. Changes to shared logic (such as JSON parsing, path resolution, configuration merging, or policy template generation) must be applied consistently to all three files. A future refactoring may extract these into a shared `.psm1` module.

## Monitoring layer

The monitoring layer combines scheduled baseline comparisons with exception approvals:

- Scheduled jobs compare approved baseline JSON to the current Copilot Conditional Access policy state.
- Power Automate can route exception approvals and renewal reminders for expiring overrides.
- Drift findings should be logged into a governed store such as Dataverse using the `fsi_cg_caa_{purpose}` naming pattern.
- Environment variables that support deployment automation should follow the `fsi_ev_caa_{setting}` naming pattern.

Recommended Dataverse table names:

- `fsi_cg_caa_baseline`
- `fsi_cg_caa_assessmenthistory`
- `fsi_cg_caa_finding`
- `fsi_cg_caa_evidence`

## Evidence layer

Evidence exports are intentionally simple and machine-readable:

- `ca-policy-state.json` records the expected or approved Conditional Access state for Copilot.
- `drift-alert-summary.json` summarizes unauthorized or unreviewed changes.
- `access-exception-register.json` records approved deviations and expiry dates.
- `07-conditional-access-automation-evidence.json` packages all evidence metadata using the shared schema.

## ASCII diagram

```text
[Copilot access request]
          |
          v
[Conditional Access evaluation]
      |                |
      | grant          | block
      v                v
[Grant access]     [Block sign-in]
      |
      v
[Entra sign-in and audit log]
      |
      v
[Baseline snapshot and drift monitor]
      |
      +--> [Drift alert summary]
      |
      +--> [Power Automate exception approval]
      |
      +--> [Evidence exports]
```

## Integration notes

- Copilot app targeting uses the Microsoft 365 Copilot and Copilot Studio application IDs.
- Drift monitoring should run weekly for baseline, daily for recommended, and near real time for regulated deployments.
- Exception workflows should include supervisory approval, expiry tracking, and compensating-control documentation.
