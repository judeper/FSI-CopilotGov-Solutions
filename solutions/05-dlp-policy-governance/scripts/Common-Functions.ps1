#Requires -Version 7.0
<#
.SYNOPSIS
Common utility functions shared across DLP Policy Governance scripts.
.DESCRIPTION
Provides Read-JsonFile, Read-JsonData, Get-PolicyModeValue, Get-CopilotCapabilityIds,
New-DlpPolicyTemplate, and ConvertTo-Array. Dot-source this file from Deploy-Solution.ps1,
Monitor-Compliance.ps1, and Export-Evidence.ps1.
#>

function Read-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "JSON file not found: $Path"
    }

    $rawContent = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($rawContent)) {
        throw "JSON file is empty: $Path"
    }

    return $rawContent | ConvertFrom-Json -Depth 32
}

function Read-JsonData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        return $null
    }

    $rawContent = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($rawContent)) {
        return $null
    }

    return $rawContent | ConvertFrom-Json -Depth 32
}

function Get-PolicyModeValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$PolicyModes,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$Fallback = 'Audit'
    )

    if ($null -ne $PolicyModes -and $PolicyModes.PSObject.Properties.Name -contains $Name) {
        return [string]$PolicyModes.$Name
    }

    return $Fallback
}

function Get-CopilotCapabilityIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$DefaultConfig
    )

    if ($null -ne $DefaultConfig.defaults -and $DefaultConfig.defaults.PSObject.Properties.Name -contains 'copilotCapabilities') {
        return @($DefaultConfig.defaults.copilotCapabilities | ForEach-Object {
            if ($_.PSObject.Properties.Name -contains 'id') {
                [string]$_.id
            } else {
                [string]$_
            }
        })
    }

    return @()
}

function New-DlpPolicyTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$DefaultConfig,

        [Parameter(Mandatory)]
        [object]$TierConfig
    )

    $defaultMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'default' -Fallback 'Audit'
    $highSensitivityMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'highSensitivity' -Fallback $defaultMode
    $npiMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'npi' -Fallback $highSensitivityMode
    $piiMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'pii' -Fallback $highSensitivityMode

    $templates = foreach ($workload in @($TierConfig.copilotWorkloads)) {
        [ordered]@{
            policyName = "Complementary DLP - $workload - $($TierConfig.tier)"
            policyLayer = 'complementary-workload-dlp'
            copilotPolicyLocation = [string]$DefaultConfig.defaults.copilotPolicyLocation
            workload = [string]$workload
            mode = $defaultMode
            highSensitivityMode = $highSensitivityMode
            labelSpecificModes = [ordered]@{
                NPI = $npiMode
                PII = $piiMode
            }
            sensitivityConditions = [ordered]@{
                standard = @($TierConfig.sensitivityConditions.standard)
                highSensitivity = @($TierConfig.sensitivityConditions.highSensitivity)
            }
            scope = [ordered]@{
                includedGroups = @($DefaultConfig.defaults.policyScope.includedGroups)
                excludedGroups = @($DefaultConfig.defaults.policyScope.excludedGroups)
            }
            monitoredCapabilities = Get-CopilotCapabilityIds -DefaultConfig $DefaultConfig
            exceptionHandling = [ordered]@{
                approvalRequired = [bool]$TierConfig.exceptionApprovalRequired
                attestationRequired = [bool]$TierConfig.exceptionAttestationRequired
                approverRole = [string]$TierConfig.exceptionApproverRole
                policyChangeApproval = [string]$TierConfig.policyChangeApproval
            }
            evidenceRetentionDays = [int]$TierConfig.evidenceRetentionDays
            driftCheckFrequency = [string]$TierConfig.driftCheckFrequency
        }
    }

    return $templates
}

function ConvertTo-Array {
    [CmdletBinding()]
    param(
        [Parameter()]
        $InputObject
    )

    if ($null -eq $InputObject) {
        Write-Output -NoEnumerate @()
        return
    }

    if ($InputObject -is [System.Array]) {
        Write-Output -NoEnumerate @($InputObject)
        return
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        Write-Output -NoEnumerate @($InputObject)
        return
    }

    Write-Output -NoEnumerate @($InputObject)
}
