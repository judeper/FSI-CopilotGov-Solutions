# Deployment Guide

## Deployment Objective

Deploy FMC so the tenant has an approved Copilot feature baseline, documented rollout rings, monitoring configuration, and evidence export capability for supported workloads.

## Step 1: Review the target tier

Select the governance tier before touching tenant settings:

- `baseline` for initial inventory and standard Copilot features only
- `recommended` for active ring management across Microsoft 365 and Teams
- `regulated` for all tracked features, strict approvals, hourly drift checks, and extended evidence retention

Review:

- `config\default-config.json`
- `config\baseline.json`
- `config\recommended.json`
- `config\regulated.json`

## Step 2: Confirm roles and scopes

Before running the deployment script, verify:

- Microsoft 365 Global Administrator, Copilot Administrator, or equivalent delegated access for Microsoft 365 admin center Copilot settings
- Teams Administrator access for documented Teams meeting/event and calling policy exports
- Power Platform Administrator access for Copilot settings and administrative exports
- Cloud Policy service access for the `Allow web search in Copilot` policy
- Dataverse capacity for baseline, findings, and evidence records

## Step 3: Prepare the target environment

1. Choose the target environment name, such as `Sandbox`, `UAT`, or `Production`.
2. Confirm the output path for deployment artifacts.
3. Decide whether the first run should use `-BaselineOnly`.
4. Document the supervisory approver for ring promotion in regulated deployments.

## Step 4: Run baseline capture

Use the deployment script to create the first baseline snapshot:

```powershell
.\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier baseline `
    -TenantId 'contoso.onmicrosoft.com' `
    -Environment 'Sandbox' `
    -OutputPath .\artifacts\FMC `
    -BaselineOnly
```

Expected outputs:

- `feature-state-baseline.json`
- `fmc-deployment-summary.json`

Review the baseline for:

- tracked features
- expected ring assignments
- enabled or restricted state
- drift interval
- Dataverse table references

## Step 5: Review rollout ring plan

For `recommended` and `regulated` tiers, validate the ring plan before promotion:

- Preview Ring targets 5 percent of approved users
- Early Adopters targets 15 percent of approved users
- General Availability contains approved broad deployment populations
- Restricted remains blocked for users or apps outside approval scope

Run:

```powershell
.\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier recommended `
    -TenantId 'contoso.onmicrosoft.com' `
    -Environment 'Production' `
    -OutputPath .\artifacts\FMC
```

Use `-WhatIf` if the change window is not open yet.

## Step 6: Document Power Automate assets

FMC follows a documentation-first rule for Power Automate. Before importing or enabling flows:

1. Review flow names, triggers, and owners in the deployment summary.
2. Confirm connector usage and environment references.
3. Confirm notification recipients and escalation path.
4. Capture approval reference for `FMC-RingPromotion` in regulated deployments.

## Step 7: Configure recurring monitoring

Run the compliance monitor against the approved baseline:

```powershell
.\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -BaselinePath .\artifacts\FMC\feature-state-baseline.json `
    -AlertThreshold 3
```

Confirm that the output includes:

- drift count
- drift score
- alert status
- finding detail for each drifted feature

## Step 8: Export evidence

After deployment or after a change window closes, export evidence:

```powershell
.\scripts\Export-Evidence.ps1 `
    -ConfigurationTier recommended `
    -OutputPath .\artifacts\FMC
```

Confirm:

- evidence JSON package exists
- `.sha256` companion file exists
- control statuses reflect the current implementation state

## Step 9: Operational handoff

Provide the following to operations, compliance, and service owners:

- approved tier and environment
- baseline artifact location
- ring promotion process
- drift review cadence
- evidence export location and retention period

## Rollback Considerations

If a feature must be restricted quickly:

1. Move the feature to the `Restricted` ring.
2. Refresh baseline after emergency approval is documented.
3. Re-run monitoring to confirm the tenant matches the revised baseline.
4. Export evidence to capture the emergency change.
