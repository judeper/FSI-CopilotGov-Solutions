# Deployment Guide

## 1. Verify the dependency solution

1. Confirm `solutions\03-sensitivity-label-auditor` has completed its latest label review.
2. Validate that the NPI, PII, and high-sensitivity labels referenced by this solution are current.
3. Record the dependency review in the delivery checklist before continuing.

## 2. Prepare access and modules

Run the following from PowerShell 7 if the modules are not already installed:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

Connect to the required services with read permissions:

```powershell
Connect-ExchangeOnline -ShowBanner:$false
Connect-IPPSSession
Connect-MgGraph -Scopes 'InformationProtectionPolicy.Read', 'Policy.Read.All'
```

## 3. Create the baseline snapshot

From `solutions\05-dlp-policy-governance`, run:

```powershell
.\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier recommended `
    -OutputPath .\artifacts `
    -BaselinePath .\artifacts\dlp-policy-baseline.json
```

Expected outputs:

- `artifacts\dlp-policy-baseline.json`
- `artifacts\deployment-manifest.json`
- `artifacts\connection-stubs\graph-connection.stub.ps1`
- `artifacts\connection-stubs\exchange-online-connection.stub.ps1`

## 4. Configure the Power Automate exception flow

Use the documented flow design to create an exception approval process that:

1. Accepts requests for temporary DLP policy deviations.
2. Validates the request against the latest baseline and drift findings.
3. Routes approval to the correct role for the selected tier.
4. Writes approved exceptions to the structured attestation log.
5. Preserves approval date, attestor, justification, and expiry fields.

## 5. Schedule drift monitoring

Schedule `Monitor-Compliance.ps1` using the cadence defined by the chosen tier:

- Baseline: weekly
- Recommended: daily
- Regulated: real-time or near-real-time orchestration

Example command:

```powershell
.\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -BaselinePath .\artifacts\dlp-policy-baseline.json `
    -OutputPath .\artifacts `
    -AlertOnDrift
```

## 6. Validate evidence export

Run the export command for the reporting period that needs review:

```powershell
.\scripts\Export-Evidence.ps1 `
    -ConfigurationTier recommended `
    -OutputPath .\artifacts `
    -PeriodStart 2026-01-01 `
    -PeriodEnd 2026-01-31
```

Confirm the following files exist after export:

- `artifacts\dlp-policy-baseline.json`
- `artifacts\policy-drift-findings.json`
- `artifacts\exception-attestations.json`
- `artifacts\05-dlp-policy-governance-evidence.json`
- SHA-256 companion files for each JSON artifact
