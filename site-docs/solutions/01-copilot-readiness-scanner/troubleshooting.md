# Troubleshooting

## Graph API Authentication Failures

### Symptoms

- `Deploy-Solution.ps1` reports a Graph connectivity validation failure.
- `Monitor-Compliance.ps1` cannot initialize tenant context.
- Token acquisition succeeds for one workload but fails for Graph-based scans.

### Diagnostic Steps

1. Confirm the `TenantId` value is correct and matches the intended tenant.
2. Confirm the operator can sign in to Microsoft 365 admin portals with the same account.
3. Verify the required Graph modules are installed:

   ```powershell
   Get-Module -ListAvailable Microsoft.Graph
   ```

4. Confirm the account or service principal has the required Graph permissions for directory, organization, and audit reads.
5. Review any conditional access or token protection policies that may block unattended or delegated access.

### Resolution

- Re-authenticate with an account that has the documented permissions.
- Validate service principal consent if using app-based authentication.
- If the customer requires a custom authentication flow, update the Graph connection placeholder before production use.

## Insufficient Permissions Per Workload

### Symptoms

- One or more domain scans return partial data or empty findings.
- Purview, Teams, Power Platform, or SharePoint checks fail while Graph setup succeeds.

### Diagnostic Steps

1. Compare the operator role assignments against the role matrix in [prerequisites.md](./prerequisites.md).
2. Identify which domain is failing and map it to the required workload role.
3. Run the monitoring script for a single domain to isolate the issue:

   ```powershell
   .\scripts\Monitor-Compliance.ps1 -ConfigurationTier baseline -TenantId 'contoso.onmicrosoft.com' -Domains purview
   ```

4. Review whether the selected tier expects guest review, large-site inventory, or advanced management signals that exceed the current permission set.

### Resolution

- Add the missing workload-specific role or use a controlled Global Administrator account for the initial baseline.
- Re-run the affected domain only, then re-run the full baseline after access is corrected.

## SharePoint PnP Connection Issues

### Symptoms

- SharePoint or OneDrive portions of the assessment fail.
- PnP commands cannot connect to the tenant admin endpoint.

### Diagnostic Steps

1. Confirm `PnP.PowerShell` is installed:

   ```powershell
   Get-Module -ListAvailable PnP.PowerShell
   ```

2. Confirm the operator can access the SharePoint Online admin URL in a browser.
3. Verify SharePoint Administrator rights are assigned.
4. If certificate or app-based authentication is used, verify the thumbprint, certificate validity, and tenant registration.

### Resolution

- Install or update `PnP.PowerShell`.
- Use the correct admin URL and a supported authentication method.
- Validate that SharePoint admin access is available before re-running the scan.

## Evidence Export Path Not Found

### Symptoms

- `Export-Evidence.ps1` fails when writing JSON artifacts.
- The package file is missing even though control assessment logic completed.

### Diagnostic Steps

1. Confirm the `OutputPath` parameter points to an accessible folder.
2. Verify the operator can create files in the destination:

   ```powershell
   Test-Path '.\artifacts'
   New-Item -ItemType Directory -Path '.\artifacts' -Force
   ```

3. Confirm the path is not blocked by controlled folder access, endpoint protection, or network share restrictions.
4. Verify sufficient free space exists for retained evidence.

### Resolution

- Create the folder in advance or use a writable local or approved network path.
- Re-run the export after correcting permissions.
- For regulated tier deployments, confirm the selected storage location supports the required retention and immutability model.

## Tier Configuration Not Found

### Symptoms

- Deployment or monitoring fails immediately with a configuration file error.
- The selected tier does not load or returns missing settings.

### Diagnostic Steps

1. Confirm the tier value is exactly `baseline`, `recommended`, or `regulated`.
2. Confirm the corresponding file exists under `config\`.
3. Validate the JSON syntax of the tier file:

   ```powershell
   Get-Content '.\config\regulated.json' -Raw | ConvertFrom-Json
   ```

4. Compare the tier file against `default-config.json` to ensure required fields are present.

### Resolution

- Correct the tier parameter or restore the missing configuration file.
- Re-run the deployment after validating the JSON file loads cleanly.
