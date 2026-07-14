# Deployment Guide

## Prerequisites

Review [Prerequisites](./prerequisites.md) before running the solution scripts. Confirm `04-finra-supervision-workflow` is already deployed because this solution uses its reviewer escalation operating model.

## Step 1: Verify Purview licenses and permissions

1. Confirm Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance), Office 365 E5, or Office 365 E3 with the Advanced Compliance add-on covers users governed by Communication Compliance policies.
2. Confirm the deployment operator is in the `Communication Compliance Admins` role group or has the Microsoft Entra ID `Compliance Administrator` role or Microsoft Purview portal `Compliance Administrator` role group, as appropriate.
3. Confirm reviewers and supervisors are assigned to `Communication Compliance Analysts`, `Communication Compliance Investigators`, or other approved role groups before policy publication.
4. Confirm the target tenant ID is available for deployment records.

## Step 2: Review and customize policy templates in `config\`

1. Review `config\default-config.json` for shared metadata, reviewer defaults, and environment references.
2. Review the selected tier file (`baseline.json`, `recommended.json`, or `regulated.json`).
3. Confirm policy template IDs, lexicon words, reviewer SLA values, and escalation flags match customer requirements.
4. Confirm legal and compliance owners approve lexicon terms before production use.

## Step 3: Run `Deploy-Solution.ps1` with `-WhatIf` first

Use `-WhatIf` to preview generated artifacts before writing files:

```powershell
Set-Location C:\Dev\FSI-CopilotGov-Solutions\solutions\14-communication-compliance-config\scripts
.\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId <tenant-guid> -WhatIf
```

Then generate the deployment artifacts:

```powershell
.\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId <tenant-guid>
```

Expected outputs:

- `artifacts\deployment\policy-templates\*.json`
- `artifacts\deployment\communication-compliance-config-deployment-manifest.json`

## Step 4: Deploy Purview policies manually

Microsoft Purview Communication Compliance publication is manual in this version. Use the generated policy templates and perform the following portal steps:

1. Open the Microsoft Purview portal (purview.microsoft.com).
2. Navigate to **Microsoft Purview Communication Compliance** and create or update a policy.
3. Copy the policy name, scope, keywords, conditions, and reviewer guidance from the matching JSON template.
4. Assign the correct reviewers and escalation contacts from the deployment manifest.
5. Publish the policy and document the publication timestamp.
6. Repeat for each template required by the selected tier.

> **Current portal wizard reference (verify before use):** In the Microsoft Purview portal, go to **Communication Compliance** > **Policies** > **Create policy**. For Copilot supervision, the built-in **Detect Microsoft Copilot interactions** template pre-selects the **Microsoft 365 Copilot and Microsoft 365 Copilot Chat** location with the Prompt Shields and Protected material classifiers at a 100% review percentage. Select **Customize policy** to adjust the users and groups in scope, reviewers, review percentage, and conditions. Reviewers are chosen during policy creation and must be assigned in the specific policy.

> **PowerShell alternative:** Baseline policy shells, reviewers, sampling (review) percentages, and keyword or sensitive-information-type conditions can also be configured with the Security & Compliance PowerShell `New-`/`Get-SupervisoryReviewPolicyV2` and `New-`/`Get-`/`Set-SupervisoryReviewRule` cmdlets. The Copilot detection location and its trainable classifiers are not exposed to those cmdlets, so complete Copilot-scoped configuration in the portal. `-WhatIf` is not honored in Security & Compliance PowerShell.

## Step 5: Configure reviewer assignments

1. Review the `reviewerWorkflow` section in the deployment manifest.
2. Assign the default reviewer group.
3. Assign escalation reviewers and legal reviewers where applicable.
4. For regulated deployments, confirm dual-review routing for high-risk communications.

## Step 6: Set lexicon keywords per regulated words list

1. Open the custom keyword dictionary settings in the Microsoft Purview portal for the selected policy.
2. Add approved AI disclosure, promotional language, best-interest, and conflict-of-interest terms from the selected tier file.
3. Record the publication date and approver names for evidence collection.
4. If the customer uses a separate regulated words list, reconcile differences before publication.

## Step 7: Run `Monitor-Compliance.ps1` to baseline queue metrics

```powershell
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -OutputPath ..\artifacts\monitoring -PassThru
```

Use the output to confirm:

- expected policy templates are represented in deployment artifacts
- activation verification files are present if available
- queue collection status is documented
- lexicon version and last update date are recorded

## Step 8: Export evidence and verify

```powershell
.\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath ..\artifacts\evidence -PassThru
```

Verify the output includes:

- `policy-template-export.json`
- `reviewer-queue-metrics.json`
- `lexicon-update-log.json`
- `14-communication-compliance-config-evidence.json`
- `14-communication-compliance-config-evidence.json.sha256`

## Dependency Notes

- `04-finra-supervision-workflow` must be deployed first to provide the operating procedure for escalations.
- Manual reviewer actions remain necessary for supervisory sign-off and exception handling.
- Portal publication steps should be documented for each release because automation is partial.

## Lab validation handoff

The read-only lab validation contract at `lab\14-communication-compliance-config.lab.json` defines the first validation cycle for this solution. That cycle is **detect-only** (`mutations: []`): it compares tenant identity with a separate sanctioned-lab record, uses least-privileged role access (including Global Reader for role-group membership inspection), confirms licensing and pay-as-you-go posture, inspects the current portal route and Copilot policy wizard fields, inventories the documented PowerShell parameter surface, and runs the sample export offline — without creating, editing, publishing, or enforcing any policy, reviewer assignment, Power Automate flow, remediation action, or retention change. Use the contract to confirm the currency of the Communication Compliance claims before planning any configuration change. Offline output uses ignored `lab-evidence/14-communication-compliance-config` staging and is removed fail-closed after evidence capture. Record honest `BLOCKED` or `NOT-APPLICABLE` dispositions when a feature, license, role, policy, or rollout is absent in the target tenant.
