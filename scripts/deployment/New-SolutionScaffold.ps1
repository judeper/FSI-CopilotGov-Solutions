[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Slug,
    [Parameter(Mandatory)]
    [string]$DisplayName
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$solutionRoot = Join-Path $repoRoot (Join-Path 'solutions' $Slug)
$paths = @(
    $solutionRoot,
    (Join-Path $solutionRoot 'docs'),
    (Join-Path $solutionRoot 'scripts'),
    (Join-Path $solutionRoot 'config'),
    (Join-Path $solutionRoot 'tests')
)

if ($PSCmdlet.ShouldProcess($solutionRoot, 'Create scaffold directories')) {
    foreach ($path in $paths) {
        $null = New-Item -ItemType Directory -Path $path -Force
    }
}
