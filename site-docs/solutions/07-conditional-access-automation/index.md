# Conditional Access Policy Automation for Copilot

> **Status:** Documentation-first scaffold | **Version:** v0.2.1 | **Priority:** P1 | **Track:** B

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

Conditional Access Policy Automation for Copilot documents, prepares, and validates Conditional Access patterns for Microsoft 365 Copilot. The solution supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 by defining risk-tiered access patterns, maintaining approved policy baselines, monitoring for policy drift, and maintaining an exception register for approved overrides.

This solution is scoped to Conditional Access controls for Copilot access. It depends on `05-dlp-policy-governance` so that prompt, response, and content protection controls are in place before Copilot access is widened.

## What this solution does

- Targets the Microsoft Graph `Office365` Conditional Access app-suite value, which Microsoft Learn lists as including Enterprise Copilot Platform, and reserves individual app IDs for tenant-verified use.
- Generates tier-aware policy templates for baseline, recommended, and regulated deployments.
- Documents and prepares tier-aware Conditional Access policy patterns for low, medium, and high risk-tier users and administrators.
- Prepares a JSON baseline template of approved policy state for change-control and drift monitoring.
- Highlights unauthorized policy changes outside the approved change process.
- Maintains an exception register with approver, approval date, business justification, and expiry.
- Exports evidence packages aligned to `..\..\data\evidence-schema.json`.

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not create Conditional Access policies in Entra ID (policy templates and Graph API commands are generated for manual review and execution)
- ❌ Does not connect to Microsoft Graph APIs by default (scripts use representative sample data; an optional `-Execute` flag documents the pattern for live policy creation but requires explicit opt-in and Graph permissions)
- ❌ Does not deploy Power Automate flows (drift alert workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Copilot application targets

| Application | App ID | Purpose in this solution |
|-------------|--------|--------------------------|
| Microsoft 365 / Office 365 app suite | `Office365` | Primary Microsoft Graph Conditional Access target; Microsoft Learn lists Enterprise Copilot Platform within this app suite |
| Tenant-verified individual app IDs | Tenant service-principal `appId` values | Optional secondary targets after administrator validation; do not use the Microsoft Flow Service app ID as a Copilot Studio target |

## Regulatory context

### OCC 2011-12

OCC 2011-12 expects banks to govern third-party technology with strong access control, change management, and ongoing monitoring. This solution supports compliance with those expectations by documenting who can access Copilot, how approved baselines are maintained, and how unauthorized policy changes are detected.

### FINRA 3110

FINRA 3110 requires supervisory systems that can review and control access to regulated technology workflows. This solution supports compliance with those expectations by defining approval workflows for access exceptions, preserving evidence of overrides, and monitoring Conditional Access changes that affect supervised populations.

### DORA Article 9

DORA Article 9 focuses on ICT security, including identity, access management, and control over critical services. This solution supports compliance with those expectations by defining tiered authentication, compliant-device requirements, and named-location restrictions for Copilot access.

## Conditional Access policy patterns by risk tier

| Configuration tier | Low risk users | Medium risk users | High risk users |
|--------------------|----------------|-------------------|-----------------|
| `baseline` | MFA required; no compliant-device requirement; no named-location requirement | MFA required; no compliant-device requirement; no named-location requirement | MFA required; no compliant-device requirement; no named-location requirement |
| `recommended` | MFA required; no named-location requirement | MFA plus compliant device; named locations for Zone 2 | MFA plus compliant device; named locations for Zone 2 and Zone 3 |
| `regulated` | MFA plus compliant device; named location required; block unknown device states | MFA plus compliant device; named location required; block unknown device states | MFA plus compliant device; named location required; block unknown device states |

Additional regulated-tier safeguards include blocking legacy authentication pathways and requiring strict exception review before temporary overrides are granted.

## Drift detection overview

The solution stores an approved Conditional Access baseline as JSON and compares that baseline with the current Copilot policy state. Scheduled monitoring highlights differences in targeted application IDs, grant controls, device requirements, and named-location conditions so that unauthorized edits can be investigated quickly.

Typical drift scenarios include:

- MFA removed from a medium or high risk policy.
- Compliant-device requirements disabled outside the approved change window.
- Named-location assignments changed for regulated users.
- The `Office365` target or tenant-verified app IDs removed or replaced in a policy target.

## Exception register

The exception register is the authoritative list of approved deviations from the Copilot Conditional Access baseline. Each exception entry should capture:

- Requestor and affected population.
- Approver and approval date.
- Business justification.
- Compensating controls.
- Expiry date and review cadence.

Expired exceptions should be treated as findings until they are closed or renewed through the approved supervisory process.

## Prerequisites

- Confirm that `05-dlp-policy-governance` is complete and that the latest protection baseline has been reviewed.
- Confirm Microsoft Entra ID P1 or P2 licensing and the required Entra administrator roles for Conditional Access management.
- Ensure Microsoft Graph access, change-control approvals, and exception review ownership are in place before policy rollout.

## Deployment

1. Confirm that `05-dlp-policy-governance` is complete.
2. Confirm Microsoft Entra ID P1 or P2 licensing and required administrator roles.
3. Run `scripts\Deploy-Solution.ps1` for the selected tier to generate policy templates, a deployment manifest, and a baseline stub.
4. Review generated policy templates and Graph API command examples.
5. Create or update Conditional Access policies in the Entra admin center or via Microsoft Graph.
6. Run `scripts\Monitor-Compliance.ps1` to validate configuration consistency and drift posture.
7. Run `scripts\Export-Evidence.ps1` to publish evidence outputs and the shared evidence package.

See `docs\deployment-guide.md` for the detailed workflow.

## Evidence Export

| Evidence output | Description | Source |
|-----------------|-------------|--------|
| `ca-policy-state.json` | Snapshot of Copilot-targeting Conditional Access settings, including MFA, compliant-device, and location requirements | `scripts\Export-Evidence.ps1` |
| `drift-alert-summary.json` | Drift findings since the approved baseline, including change descriptions and severity | `scripts\Monitor-Compliance.ps1` and `scripts\Export-Evidence.ps1` |
| `access-exception-register.json` | Approved access overrides with approver, justification, and expiry | Deployment artifacts or existing exception register |

## Solution components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Generates Copilot Conditional Access policy templates, baseline stubs, and deployment metadata |
| `scripts\Monitor-Compliance.ps1` | Validates the selected tier, checks exceptions, and identifies drift findings |
| `scripts\Export-Evidence.ps1` | Produces solution evidence artifacts and the shared evidence package |
| `config\*.json` | Defines shared defaults and tier-specific policy expectations |
| `docs\*.md` | Architecture, prerequisites, deployment, evidence, and troubleshooting guidance |
| `tests\07-conditional-access-automation.Tests.ps1` | Pester validation for docs, configs, and scripts |

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../reference/control-coverage-honesty.md)):
> 3 control(s) are **evidence-export-ready** in scaffold form: 2.3, 2.6, 2.9.

| Control | Objective | Regulations | Evidence |
|---------|-----------|-------------|----------|
| `2.3` | Copilot access control and Conditional Access enforcement | OCC 2011-12, FINRA 3110, DORA Article 9 | `ca-policy-state.json`, `drift-alert-summary.json` |
| `2.6` | Change oversight, exception governance, and policy drift review for Copilot access controls | OCC 2011-12, FINRA 3110 | `drift-alert-summary.json`, `access-exception-register.json` |
| `2.9` | Device compliance requirements for Copilot sessions | OCC 2011-12, DORA Article 9 | `ca-policy-state.json`, `drift-alert-summary.json` |

## Regulatory Alignment

This solution supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 by defining approved Copilot access patterns, preserving baseline and drift evidence, and documenting exception approvals for regulated populations. It supports access governance and change review, but production rollout still requires tenant-specific administrator action and oversight.

## Known limitations

- Conditional Access policy creation requires Microsoft Entra ID P1 or P2 licensing, and risk-based policies require Microsoft Entra ID P2.
- Microsoft 365 Copilot requires an eligible prerequisite subscription plan plus the Microsoft 365 Copilot add-on or entitlement; Microsoft 365 E3 and E5 are examples, not the complete prerequisite list.
- Conditional Access policy evaluation can take about 5 minutes after a change before the new state is consistently enforced.
- Named-location strategies still require tenant-specific design for branch offices, vendors, and break-glass accounts.
- This solution documents Graph API deployment commands, but production execution still requires administrator review and tenant connectivity.
