# Deployment Guide

## Prerequisites

Review [Prerequisites](./prerequisites.md) before running the solution scripts. Confirm `04-finra-supervision-workflow` is already deployed because this solution uses its reviewer escalation operating model.

## Step 1: Verify Purview licenses and permissions

1. Confirm Microsoft Purview Communication Compliance is licensed for the tenant.
2. Confirm the deployment operator has Communication Compliance Administrator or Compliance Administrator permissions.
3. Confirm reviewers and supervisors have approved roles before policy publication.
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

Communication Compliance publication is manual in this version. Use the generated policy templates and perform the following portal steps:

1. Open the Microsoft Purview compliance portal.
2. Navigate to **Communication Compliance** and create or update a policy.
3. Copy the policy name, scope, keywords, conditions, and reviewer guidance from the matching JSON template.
4. Assign the correct reviewers and escalation contacts from the deployment manifest.
5. Publish the policy and document the publication timestamp.
6. Repeat for each template required by the selected tier.

## Step 5: Configure reviewer assignments

1. Review the `reviewerWorkflow` section in the deployment manifest.
2. Assign the default reviewer group.
3. Assign escalation reviewers and legal reviewers where applicable.
4. For regulated deployments, confirm dual-review routing for high-risk communications.

## Step 6: Set lexicon keywords per regulated words list

1. Open the Purview lexicon or keyword settings used by the selected policy.
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
