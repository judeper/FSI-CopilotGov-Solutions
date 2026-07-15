# Conditional Access Policy Automation for Copilot

> **Status:** Documentation-first scaffold | **Version:** v0.2.5 | **Priority:** P1 | **Track:** B

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

Conditional Access Policy Automation for Copilot documents, prepares, and validates Conditional Access patterns for Microsoft 365 Copilot. The solution supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 by defining risk-tiered access patterns, maintaining approved policy baselines, monitoring for policy drift, and maintaining an exception register for approved overrides.

This solution is scoped to Conditional Access controls for Copilot access. It depends on `05-dlp-policy-governance` so that prompt, response, and content protection controls are in place before Copilot access is widened.

## What this solution does

- Targets the Microsoft Graph `Office365` Conditional Access app-suite value, which Microsoft Learn lists as including Enterprise Copilot Platform, and reserves individual app IDs for tenant-verified use.
- Generates tier-aware policy templates for baseline, recommended, and regulated deployments.
- Documents and prepares tier-aware Conditional Access policy patterns for low, medium, and high risk-tier users and administrators.
- Models a break-glass/emergency-access exclusion slot (`excludeGroups`) in every generated policy and flags policies for manual review until `emergencyAccessExclusionGroupIds` is populated.
- Prepares a JSON baseline template of approved policy state for change-control and drift monitoring.
- Highlights unauthorized policy changes outside the approved change process.
- Maintains an exception register with approver, approval date, business justification, and expiry.
- Exports evidence packages aligned to `..\..\data\evidence-schema.json`.

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not create Conditional Access policies in Entra ID (policy templates and Graph API commands are generated for manual review only)
- ❌ Does not execute live Microsoft Graph policy writes; the retained `-Execute` compatibility switch fails closed until a tenant-bound executor can enforce tenant proof, disposable targeting, ownership, read-back, and cleanup
- ❌ Does not create, own, modify, or delete **Microsoft-managed** or **Baseline security mode** Conditional Access policies; those policies are owned by Microsoft and appear with **Microsoft** in the **Created by** column. Drift monitoring is scoped to this solution's own Copilot policy baseline only.
- ❌ Does not enforce break-glass protection on its own; it models an `excludeGroups` slot for review, while a tenant-bound executor must verify emergency-access and automation-identity exclusions before any future write
- ❌ Does not deploy Power Automate flows (drift alert workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Copilot application targets

| Application | App ID | Purpose in this solution |
|-------------|--------|--------------------------|
| Microsoft 365 / Office 365 app suite | `Office365` | Primary Microsoft Graph Conditional Access target; Microsoft Learn lists Enterprise Copilot Platform within this app suite |
| Tenant-verified individual app IDs | Tenant service-principal `appId` values | Optional secondary targets after administrator validation; do not use the Microsoft Flow Service app ID as a Copilot Studio target |

Microsoft Learn recommends targeting the `Office365` app-suite grouping instead of individual cloud apps to avoid Conditional Access [service dependencies](https://learn.microsoft.com/entra/identity/conditional-access/service-dependencies). Because the suite covers many Microsoft 365 services in addition to Enterprise Copilot Platform, policies that target it apply broadly, not to Copilot alone.

## Break-glass and emergency-access exclusions

Microsoft recommends excluding at least one emergency-access (break-glass) account from every Conditional Access policy so a misconfigured policy cannot lock every administrator out of the tenant. This solution models that guidance:

- Every generated policy includes an `excludeGroups` slot populated from `emergencyAccessExclusionGroupIds` in `config\default-config.json`.
- Until that list is populated, each policy is marked `requiresBreakGlassExclusion` and `manualReviewRequired`. Live `-Execute` remains disabled even after population because the documentation-first script cannot prove the other tenant-safety and cleanup requirements.
- Populate `emergencyAccessExclusionGroupIds` with the tenant break-glass group object ID before switching any policy state to `enabled`.

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
- Confirm Microsoft Graph access, change-control approvals, and exception review ownership are in place before policy rollout.

## Deployment

1. Confirm that `05-dlp-policy-governance` is complete.
2. Confirm Microsoft Entra ID P1 or P2 licensing and required administrator roles.
3. Run `scripts\Deploy-Solution.ps1` for the selected tier to generate policy templates, a deployment manifest, and a baseline stub.
4. Review generated policy templates and Graph API command examples.
5. Hand approved templates to a tenant-bound deployment process that enforces positive tenant proof, scoped targets, ownership, read-back, and cleanup.
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
- Conditional Access policy changes can take up to two hours to be effective (up to one day in some cases). Enforcement applies at the next token issuance after the policy update propagates.
- Named-location strategies still require tenant-specific design for branch offices, vendors, and break-glass accounts.
- This solution documents Graph API deployment commands, but the repository script refuses live writes; production execution requires a separate tenant-bound process with administrator review and cleanup enforcement.

## Microsoft Learn References

- [Apps included in Conditional Access Office 365 app suite](https://learn.microsoft.com/en-us/entra/identity/conditional-access/reference-office-365-application-contents) — Microsoft Learn; lists **Enterprise Copilot Platform** (Microsoft 365 Copilot) among the applications covered by the Microsoft Graph `Office365` Conditional Access app-suite value. Verified 2026-07-14.
- [Conditional Access: Target resources](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-cloud-apps) — Microsoft Learn; recommends targeting the Microsoft 365 (`Office365`) grouping instead of individual cloud apps to avoid service dependencies. Verified 2026-07-14.
- [Microsoft 365 Copilot architecture and how it works](https://learn.microsoft.com/en-us/microsoft-365/copilot/microsoft-365-copilot-architecture) — Microsoft Learn; documents that Microsoft 365 Copilot honors Conditional Access policies and multifactor authentication. Verified 2026-07-14.
- [Microsoft-managed Conditional Access policies](https://learn.microsoft.com/en-us/entra/identity/conditional-access/managed-policies) — Microsoft Learn; explains that Microsoft-managed and Baseline security mode policies are owned by Microsoft (administrators can edit only state and exclusions, or duplicate). Verified 2026-07-14.
- [Manage emergency access accounts in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access) — Microsoft Learn; recommends excluding emergency-access accounts from Conditional Access policies. Verified 2026-07-14.
- [conditionalAccessPolicy resource type](https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy) — Microsoft Graph; documents the `state` values `enabled`, `disabled`, and `enabledForReportingButNotEnforced`. Verified 2026-07-14.

> The individual first-party application ID historically associated with the Enterprise Copilot Platform is not published on Microsoft Learn. This solution targets the `Office365` app suite — which Microsoft Learn confirms includes Enterprise Copilot Platform — and reserves individual app IDs for tenant-verified use only. Confirm tenant-specific service-principal `appId` values with Microsoft Graph before adding them as Conditional Access targets.
