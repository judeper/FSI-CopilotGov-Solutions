#Requires -Version 7.0
<#
.SYNOPSIS
Audits PowerShell sources for unmarked plaintext client-secret parameter sites.

.DESCRIPTION
Stage 3 of Issue #294 (follow-up to #221 / PR #292). Stage 1 hardened the seven legacy
client-secret sites by converting every '[string]$ClientSecret' parameter to
'[System.Security.SecureString]' and tagging the remaining legacy code paths with the
greppable marker comment '# IDENTITY-STANDARD: legacy-client-secret'.

This static audit guards that hardening from regression. It parses every .ps1 / .psm1 file
under the scan roots with the PowerShell AST and inspects parameter declarations whose name
denotes a client/app secret. A parameter is treated as a plaintext-capable secret site when
its static type is anything other than System.Security.SecureString (for example [string],
[object], or an untyped parameter). Such a site is only permitted when the
'IDENTITY-STANDARD: legacy-client-secret' marker appears within a small proximity window
above the declaration; otherwise the audit fails.

SecureString-typed secret parameters are the approved pattern and are ignored, so the audit
passes on the current (clean) main where all secret parameters are SecureString-typed.

This script performs a source-code scan only. It does not connect to Microsoft Graph or any
other Microsoft cloud service and requests no tokens.

See docs/security/managed-identity-standard.md for the authentication standard it enforces.

.PARAMETER Path
One or more root directories to scan. Defaults to the repository's 'scripts' and 'solutions'
directories (resolved relative to this script's location).

.PARAMETER MarkerWindow
Number of lines above a flagged parameter declaration to search for the marker comment.
Defaults to 6, which accommodates the '[Parameter()]' attribute plus the marker comment line.

.EXAMPLE
pwsh ./scripts/audit-managed-identity.ps1

.EXAMPLE
pwsh ./scripts/audit-managed-identity.ps1 -Path ./solutions/02-oversharing-risk-assessment
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$Path,

    [Parameter()]
    [int]$MarkerWindow = 6
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The single, greppable marker that flags an acknowledged legacy client-secret site.
$marker = 'IDENTITY-STANDARD: legacy-client-secret'

# Parameter names that denote a client/app secret (case-insensitive substring match).
$secretNamePattern = 'secret'

# SecureString is the only approved type for a secret-bearing parameter. Anything else
# (e.g. [string], [object], untyped) is a plaintext-capable site that must be marked.
$approvedTypeName = 'System.Security.SecureString'

# Resolve scan roots relative to the repository root (the parent of this scripts/ folder).
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Path -or $Path.Count -eq 0) {
    $Path = @(
        (Join-Path $repoRoot 'scripts'),
        (Join-Path $repoRoot 'solutions')
    )
}

$selfPath = $PSCommandPath

$files = foreach ($root in $Path) {
    if (Test-Path -LiteralPath $root) {
        Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.ps1', '.psm1' }
    }
    else {
        Write-Warning "Scan root not found, skipping: $root"
    }
}
$files = @($files | Where-Object { $_.FullName -ne $selfPath } | Sort-Object -Property FullName -Unique)

$violations = [System.Collections.Generic.List[pscustomobject]]::new()
$siteCount = 0

foreach ($file in $files) {
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$null, [ref]$parseErrors)

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        # A genuinely malformed PowerShell file is caught by the lint/AST CI gates; here we
        # skip it (fail-open on parse) rather than mask the real syntax error with a marker
        # finding.
        Write-Warning "Skipping (parse errors): $($file.FullName)"
        continue
    }

    $lines = @(Get-Content -LiteralPath $file.FullName)

    $paramAsts = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.ParameterAst] }, $true)

    foreach ($param in $paramAsts) {
        $paramName = $param.Name.VariablePath.UserPath
        if ($paramName -notmatch $secretNamePattern) { continue }

        $typeName = $param.StaticType.FullName
        if ($typeName -eq $approvedTypeName) { continue }  # SecureString is approved.

        # Plaintext-capable client-secret parameter site.
        $siteCount++

        $startLine = $param.Extent.StartLineNumber
        $endLine = $param.Extent.EndLineNumber
        $searchStart = [Math]::Max(1, $startLine - $MarkerWindow)
        $windowText = ($lines[($searchStart - 1)..($endLine - 1)] -join "`n")

        if ($windowText -notmatch [regex]::Escape($marker)) {
            $relative = [System.IO.Path]::GetRelativePath($repoRoot, $file.FullName).Replace('\', '/')
            $violations.Add([pscustomobject]@{
                    File      = $relative
                    Line      = $startLine
                    Parameter = "`$$paramName"
                    Type      = if ($typeName) { $typeName } else { '(unresolved)' }
                })
        }
    }
}

Write-Host 'Managed-identity audit (Stage 3, Issue #294)'
Write-Host "  Files scanned:             $($files.Count)"
Write-Host "  Client-secret param sites: $siteCount (plaintext-typed or untyped)"
Write-Host "  Unmarked violations:       $($violations.Count)"

if ($violations.Count -gt 0) {
    Write-Host ''
    foreach ($v in $violations) {
        $detail = "$($v.File):$($v.Line) parameter $($v.Parameter) is typed as [$($v.Type)] " +
            "(a plaintext-capable client secret) without the '$marker' marker."
        Write-Host "::error file=$($v.File),line=$($v.Line)::$detail"
    }
    Write-Host ''
    Write-Host 'Client-secret parameters must be [System.Security.SecureString] (preferred). If a'
    Write-Host "legacy plaintext site is genuinely required, add the '# $marker' marker comment"
    Write-Host 'directly above the declaration. See docs/security/managed-identity-standard.md.'
    exit 1
}

Write-Host ''
Write-Host 'PASS: no unmarked plaintext client-secret parameter sites found.'
exit 0
