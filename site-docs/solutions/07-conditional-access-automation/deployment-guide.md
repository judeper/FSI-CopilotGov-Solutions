# Deployment Guide

## Before you begin

1. Verify that `05-dlp-policy-governance` is complete for the target tenant.
2. Confirm Microsoft Entra ID P1 or P2 licensing and the Copilot service entitlement for the scoped population.
3. Confirm that the operator has Conditional Access Administrator or Global Administrator permissions.

## Step 1: Select a governance tier

Choose one of the supported tiers:

- `baseline`
- `recommended`
- `regulated`

The selected tier determines MFA, compliant-device, named-location, notification, and exception-handling expectations.

## Step 2: Generate deployment artifacts

Run the deployment script from the solution folder or the repository root.

```powershell
pwsh -File .\solutions\07-conditional-access-automation\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier recommended `
    -TenantId contoso.onmicrosoft.com `
    -OutputPath .\solutions\07-conditional-access-automation\artifacts\recommended
```

The script generates:

- `ca-policy-templates.json`
- `deployment-manifest.json`
- `current-policy-baseline.json` unless `-SkipBaseline` is used
- `graph-api-commands.ps1`
- `access-exception-register.json`

## Step 3: Review the generated policy templates

Review `ca-policy-templates.json` before creating policies. Confirm:

- Target resources use the `Office365` app-suite value or tenant-verified app IDs.
- Grant controls align with the selected tier.
- Named-location labels are tenant-specific and approved, and Graph-ready `namedLocationIds` contain tenant object IDs before execution.
- Emergency access accounts are handled outside the default template.

## Step 4: Create or update Conditional Access policies

Create or update policies manually in the Entra admin center or by using the generated Graph commands.

Manual path:

1. Go to the Microsoft Entra admin center.
2. Browse to **Entra ID** > **Conditional Access** > **Policies**.
3. Create or update policies that target the `Office365` app suite or tenant-verified app IDs.
4. Enable MFA, compliant-device, and named-location controls based on the selected tier.

Graph path:

- Review `graph-api-commands.ps1`.
- Confirm any policy marked `requiresTenantNamedLocationIds` has tenant named-location object IDs before execution; generated commands skip those policies until IDs are populated.
- Connect with `Policy.Read.All` and `Policy.ReadWrite.ConditionalAccess`.
- Run commands only after change approval is recorded.

> **Security note:** These Graph permissions are tenant-wide and grant access to all Conditional Access policies, not just Copilot-targeting ones. Restrict usage to approved Conditional Access Administrators and audit all Graph API calls. See `docs\prerequisites.md` for mitigation guidance.

## Step 5: Validate policy posture

Use `scripts\Monitor-Compliance.ps1` as the local validation step after tenant-specific policies are created or updated.

```powershell
pwsh -File .\solutions\07-conditional-access-automation\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -BaselinePath .\solutions\07-conditional-access-automation\artifacts\recommended\current-policy-baseline.json `
    -ExceptionRegisterPath .\solutions\07-conditional-access-automation\artifacts\recommended\access-exception-register.json `
    -OutputPath .\solutions\07-conditional-access-automation\artifacts\recommended `
    -AlertOnDrift
```

## Step 6: Configure drift monitoring

Schedule the monitor based on the selected tier:

- Baseline: weekly
- Recommended: daily
- Regulated: near real time or the closest supported enterprise schedule

Common scheduling options include Azure Automation, GitHub Actions, Task Scheduler, or an approved CI runner.

## Step 7: Initialize and govern the exception register

The exception register should capture approved deviations with:

- Policy name or impacted population
- Approver
- Approval date
- Business justification
- Expiry date
- Compensating controls

Power Automate can be used to route approvals and reminders for expiring exceptions.

## Step 8: Export evidence

After deployment and validation, export evidence for audit and supervisory review.

```powershell
pwsh -File .\solutions\07-conditional-access-automation\scripts\Export-Evidence.ps1 `
    -ConfigurationTier recommended `
    -OutputPath .\solutions\07-conditional-access-automation\artifacts\recommended `
    -BaselinePath .\solutions\07-conditional-access-automation\artifacts\recommended\current-policy-baseline.json `
    -ExceptionRegisterPath .\solutions\07-conditional-access-automation\artifacts\recommended\access-exception-register.json
```

## Post-deployment review

- Confirm policy propagation before testing user sign-in outcomes.
- Review drift findings and close any unexpected changes.
- Archive evidence according to the selected retention period.
