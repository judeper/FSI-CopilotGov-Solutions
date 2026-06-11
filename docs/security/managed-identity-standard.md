# Managed-Identity Authentication Standard

> **Status:** v1.0 standard | **Scope:** All future runnable scripts | **Audience:** Solution authors, contributors

## Why this standard exists

This repository is documentation-first today: scripts under `scripts/` and `solutions/*/scripts/` use
representative sample data and do not call live Microsoft 365 services. That will change. As soon as
any solution is bound to a tenant, the authentication pattern shipped in this repo becomes the de
facto reference implementation that downstream FSI customers copy.

If the first runnable script lands with a `-ClientSecret` parameter and a `Read-Host -AsPlainText`
example, that pattern propagates. We need to set the default **before** that happens, so the
expected order of preference is recorded, reviewable, and enforceable.

This standard supports compliance with the FSI Copilot Governance Framework controls covering
identity hygiene (1.6), credential protection (2.5), and operational hardening (4.10), and helps
meet the broader principle of secret-less automation expected by FINRA, SEC 17a-4, and DORA
operational-resilience reviewers.

## The standard (preference order)

Future runnable scripts that authenticate to Microsoft Graph, Azure Resource Manager, Power Platform,
or any other Microsoft cloud service **must** select credentials in the following order:

1. **Managed identity (FIRST / default).** System-assigned or user-assigned managed identity when
   the script runs inside Azure (Functions, Automation, Container Apps, VM, Arc). No secret material
   ever leaves the platform.
2. **Federated credential (SECOND).** Workload Identity Federation for GitHub Actions, Azure DevOps,
   or another OIDC issuer. Required when the script must run outside Azure but inside a trusted CI/CD
   pipeline. No long-lived secret is stored.
3. **Certificate-based service principal (THIRD).** App registration with a certificate credential,
   thumbprint resolved from `Cert:\CurrentUser\My\` or a Key Vault reference. Acceptable for
   on-premises operator runs where federation is not yet available.
4. **Client secret (LEGACY, development only).** Permitted only behind an explicit
   `-AllowClientSecret` switch, only after a printed runtime warning, and only with the
   `IDENTITY-STANDARD: legacy-client-secret` marker described below. Not acceptable for production.

Any new script that introduces a `-ClientSecret` parameter without honoring the order above is a
review-blocking change.

## Implementation guidance

A reusable `Get-AccessToken` helper should live under `scripts/common/` once the first runnable
solution lands. The skeleton below is illustrative — it is **not** a working module and must not be
shipped as one. Solution authors should treat it as the contract their helper has to satisfy.

```powershell
function Get-AccessToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]   $TenantId,
        [Parameter()]          [string]   $ClientId,
        [Parameter()]          [string]   $CertificateThumbprint,
        [Parameter()]          [string]   $FederatedTokenFile,
        [Parameter()]          [securestring] $ClientSecret,
        [Parameter()]          [switch]   $AllowClientSecret,
        [Parameter()]          [string]   $Resource = 'https://graph.microsoft.com/.default'
    )

    if ($env:IDENTITY_ENDPOINT -or $env:MSI_ENDPOINT) {
        return Get-MiToken -Resource $Resource                          # 1. managed identity
    }
    if ($FederatedTokenFile -and (Test-Path $FederatedTokenFile)) {
        return Get-FederatedToken -TenantId $TenantId -ClientId $ClientId `
                                  -AssertionFile $FederatedTokenFile -Resource $Resource   # 2. federated
    }
    if ($CertificateThumbprint) {
        return Get-CertToken -TenantId $TenantId -ClientId $ClientId `
                             -Thumbprint $CertificateThumbprint -Resource $Resource        # 3. cert
    }
    if ($AllowClientSecret -and $ClientSecret) {
        Write-Warning 'IDENTITY-STANDARD: client-secret path is LEGACY and only permitted in dev.'
        return Get-SecretToken -TenantId $TenantId -ClientId $ClientId `
                               -Secret $ClientSecret -Resource $Resource                   # 4. legacy
    }
    throw 'No acceptable credential source found. See docs/security/managed-identity-standard.md.'
}
```

Notes:

- The helper **never** silently falls back to a client secret. The caller must pass
  `-AllowClientSecret` and the helper must always print the warning.
- `ClientSecret` is typed as `securestring`, never `string`. Plain-string secret parameters are
  prohibited in any new script.
- Real implementations should also redact the credential type chosen into the run log so reviewers
  can see, after the fact, which branch executed.

## Marking legacy code

Until every existing script is migrated, the repo will continue to contain client-secret code paths.
Each such site **must** carry the marker comment near the call so audit tooling can find it:

```powershell
# IDENTITY-STANDARD: legacy-client-secret -- TODO: migrate to managed identity
$body['client_secret'] = $ClientSecret
```

The TODO line should reference an issue or a target removal date once tenant-binding work is
scheduled. The marker is intentionally a single, greppable string:
`IDENTITY-STANDARD: legacy-client-secret`.

## Audit posture

Stage 3 of the migration (Issue #294) ships an automated guard so the Stage 1 hardening cannot
silently regress. The `Audit Managed Identity` workflow
(`.github/workflows/audit-managed-identity.yml`) runs `scripts/audit-managed-identity.ps1` on
every pull request and on push to `main`.

The script parses each `.ps1` and `.psm1` file under `scripts/` and `solutions/` with the
PowerShell AST and inspects parameter declarations whose name denotes a client or app secret. A
parameter is treated as a plaintext client-secret **site** when its static type is anything other
than `System.Security.SecureString` — for example `[string]`, `[object]`, or an untyped
parameter. A site is permitted only when the `IDENTITY-STANDARD: legacy-client-secret` marker
appears within a few lines above the declaration; any unmarked site fails the build (exit 1).
SecureString-typed parameters are the approved pattern and are skipped, so the check is green on
a clean tree.

The audit is deliberately scoped to *parameter sites* rather than a raw text match. A quick
manual grep is still useful for a one-off sweep:

```powershell
rg -n "ConvertTo-SecureString.*AsPlainText|ClientSecretCredential|client_secret|\[string\]\$ClientSecret" scripts solutions |
    rg -v "IDENTITY-STANDARD: legacy-client-secret"
```

but that heuristic also surfaces the legitimate `client_secret` token-request body key inside
`scripts/common/GraphAuth.psm1`, which is why the CI check uses AST-based parameter inspection
instead. Any line the manual grep surfaces is either a new client-secret site that has not been
marked (review-blocking) or an existing legacy site whose TODO has not been linked to an issue
(tracking gap).

**Stage 2 (tenant-bound, blocked).** Replacing the client-secret code paths in
`scripts/common/GraphAuth.psm1` and the solution 02 / 18 scripts with managed identity requires a
live tenant to validate, so it is tracked separately under tenant binding. When that work lands,
this document should be updated to reference the concrete helper module and the matching Pester
test that verifies the preference order.
