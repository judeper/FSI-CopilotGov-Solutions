<#
.SYNOPSIS
Shared Microsoft Graph authentication and request module.

.DESCRIPTION
Provides reusable helpers for Graph API authentication (app-only via client credentials
or delegated via Microsoft.Graph SDK), request invocation with retry and throttle handling,
and placeholder context generation for documentation-first repository states.
#>
Set-StrictMode -Version Latest

function New-CopilotGovGraphContext {
    <#
    .SYNOPSIS
    Returns placeholder Graph context metadata for repository scripts.

    .DESCRIPTION
    The returned object is a contract stub only. No tokens are requested, no authenticated session
    is created, and callers must add tenant-approved authentication logic before treating Graph
    connectivity as live.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [string[]]$Scopes = @('https://graph.microsoft.com/.default')
    )

    return [pscustomobject]@{
        TenantId = $TenantId
        Scopes = $Scopes
        ConnectedAt = (Get-Date).ToString('o')
        Mode = 'placeholder'
        Warning = 'No authenticated Microsoft Graph session was created by GraphAuth.psm1.'
    }
}

function Connect-CopilotGovGraph {
    <#
    .SYNOPSIS
    Authenticates to Microsoft Graph and returns an access token context.

    .DESCRIPTION
    Supports app-only authentication via client credentials (ClientId + ClientSecret or
    CertificateThumbprint) and delegated authentication via the Microsoft.Graph SDK
    (Connect-MgGraph). Returns a context object that Invoke-CopilotGovGraphRequest uses
    to authorize requests.

    .PARAMETER TenantId
    Azure AD tenant GUID.

    .PARAMETER ClientId
    Application (client) ID for app-only authentication.

    .PARAMETER ClientSecret
    Client secret for app-only authentication. Mutually exclusive with CertificateThumbprint.

    .PARAMETER CertificateThumbprint
    Certificate thumbprint for app-only authentication. Mutually exclusive with ClientSecret.

    .PARAMETER Scopes
    Delegated permission scopes when using interactive authentication.

    .PARAMETER UseMgGraph
    When set, uses Connect-MgGraph for delegated authentication instead of client credentials.

    .EXAMPLE
    $ctx = Connect-CopilotGovGraph -TenantId $tid -ClientId $cid -ClientSecret $secret
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$ClientSecret,

        [Parameter()]
        [string]$CertificateThumbprint,

        [Parameter()]
        [string[]]$Scopes = @('https://graph.microsoft.com/.default'),

        [Parameter()]
        [switch]$UseMgGraph
    )

    if ($UseMgGraph) {
        if (-not (Get-Command -Name Connect-MgGraph -ErrorAction SilentlyContinue)) {
            throw 'Microsoft.Graph module is not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser'
        }

        $connectParams = @{}
        if ($TenantId) { $connectParams['TenantId'] = $TenantId }
        if ($Scopes -and $Scopes[0] -ne 'https://graph.microsoft.com/.default') {
            $connectParams['Scopes'] = $Scopes
        }

        Connect-MgGraph @connectParams | Out-Null

        return [pscustomobject]@{
            TenantId    = $TenantId
            Scopes      = $Scopes
            ConnectedAt = (Get-Date).ToString('o')
            Mode        = 'delegated'
            AuthMethod  = 'MgGraph'
            AccessToken = $null
        }
    }

    if ([string]::IsNullOrWhiteSpace($ClientId)) {
        throw 'ClientId is required for app-only authentication. Use -UseMgGraph for delegated auth.'
    }

    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id  = $ClientId
        scope      = 'https://graph.microsoft.com/.default'
        grant_type = 'client_credentials'
    }

    if (-not [string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
        $cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction Stop
        $assertion = New-CopilotGovClientAssertion -Certificate $cert -TenantId $TenantId -ClientId $ClientId
        $body['client_assertion_type'] = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        $body['client_assertion'] = $assertion
    }
    elseif (-not [string]::IsNullOrWhiteSpace($ClientSecret)) {
        $body['client_secret'] = $ClientSecret
    }
    else {
        throw 'Either ClientSecret or CertificateThumbprint is required for app-only authentication.'
    }

    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
    }
    catch {
        throw "Graph authentication failed: $($_.Exception.Message)"
    }

    return [pscustomobject]@{
        TenantId    = $TenantId
        Scopes      = $Scopes
        ConnectedAt = (Get-Date).ToString('o')
        Mode        = 'app-only'
        AuthMethod  = if ($CertificateThumbprint) { 'Certificate' } else { 'ClientSecret' }
        AccessToken = $response.access_token
        ExpiresOn   = (Get-Date).AddSeconds([int]$response.expires_in)
    }
}

function Invoke-CopilotGovGraphRequest {
    <#
    .SYNOPSIS
    Sends a request to the Microsoft Graph API with retry and throttle handling.

    .DESCRIPTION
    Wraps Invoke-RestMethod (for app-only contexts) or Invoke-MgGraphRequest (for delegated
    contexts) with automatic retry on HTTP 429 and 503 responses. Supports paging via the
    @odata.nextLink pattern when -AllPages is specified.

    .PARAMETER Context
    Graph context object returned by Connect-CopilotGovGraph.

    .PARAMETER Uri
    Graph API URI (relative or absolute). Relative paths are prefixed with
    https://graph.microsoft.com/v1.0/.

    .PARAMETER Method
    HTTP method. Defaults to GET.

    .PARAMETER Body
    Request body for POST/PATCH/PUT requests.

    .PARAMETER AllPages
    When set, follows @odata.nextLink to retrieve all pages of results.

    .PARAMETER MaxRetries
    Maximum number of retries on throttle or transient error responses.

    .EXAMPLE
    $sites = Invoke-CopilotGovGraphRequest -Context $ctx -Uri '/sites?$select=id,displayName' -AllPages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')]
        [string]$Method = 'GET',

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [switch]$AllPages,

        [Parameter()]
        [int]$MaxRetries = 3
    )

    if ($Uri -match '^/') {
        $Uri = "https://graph.microsoft.com/v1.0$Uri"
    }
    elseif ($Uri -notmatch '^https?://') {
        $Uri = "https://graph.microsoft.com/v1.0/$Uri"
    }

    $allResults = @()
    $currentUri = $Uri

    do {
        $response = $null
        $retryCount = 0
        $succeeded = $false

        while (-not $succeeded -and $retryCount -le $MaxRetries) {
            try {
                if ($Context.AuthMethod -eq 'MgGraph') {
                    $mgParams = @{
                        Method = $Method
                        Uri    = $currentUri
                    }
                    if ($null -ne $Body) {
                        $mgParams['Body'] = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
                    }
                    $response = Invoke-MgGraphRequest @mgParams -ErrorAction Stop
                }
                else {
                    $headers = @{
                        Authorization  = "Bearer $($Context.AccessToken)"
                        'Content-Type' = 'application/json'
                    }
                    $restParams = @{
                        Uri     = $currentUri
                        Method  = $Method
                        Headers = $headers
                    }
                    if ($null -ne $Body) {
                        $restParams['Body'] = if ($Body -is [string]) { $Body } else { ($Body | ConvertTo-Json -Depth 20) }
                    }
                    $response = Invoke-RestMethod @restParams -ErrorAction Stop
                }

                $succeeded = $true
            }
            catch {
                $statusCode = $null
                if ($_.Exception.Response) {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                }

                if ($statusCode -in @(429, 503) -and $retryCount -lt $MaxRetries) {
                    $retryAfter = 5
                    if ($_.Exception.Response.Headers -and $_.Exception.Response.Headers['Retry-After']) {
                        $retryAfter = [int]$_.Exception.Response.Headers['Retry-After']
                    }

                    $waitSeconds = [Math]::Max($retryAfter, [Math]::Pow(2, $retryCount + 1))
                    Write-Warning "Graph API throttled (HTTP $statusCode). Retrying in $waitSeconds seconds..."
                    Start-Sleep -Seconds $waitSeconds
                    $retryCount++
                }
                else {
                    throw
                }
            }
        }

        if ($response -is [hashtable] -or $response -is [pscustomobject]) {
            $valueProperty = if ($response -is [hashtable]) { $response['value'] } else { $response.value }

            if ($null -ne $valueProperty) {
                $allResults += @($valueProperty)
            }
            else {
                $allResults += $response
            }

            $nextLink = if ($response -is [hashtable]) { $response['@odata.nextLink'] } else { $response.'@odata.nextLink' }
            $currentUri = if ($AllPages -and $nextLink) { $nextLink } else { $null }
        }
        else {
            $allResults += $response
            $currentUri = $null
        }
    } while ($null -ne $currentUri)

    return $allResults
}

function New-CopilotGovClientAssertion {
    <#
    .SYNOPSIS
    Creates a client assertion JWT for certificate-based app-only authentication.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [string]$ClientId
    )

    $thumbprintBytes = [Convert]::FromBase64String(
        [Convert]::ToBase64String($Certificate.GetCertHash())
    )
    $x5t = [Convert]::ToBase64String($thumbprintBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')

    $header = @{
        alg = 'RS256'
        typ = 'JWT'
        x5t = $x5t
    } | ConvertTo-Json -Compress

    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $payload = @{
        aud = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        iss = $ClientId
        sub = $ClientId
        jti = [guid]::NewGuid().ToString()
        nbf = $now
        exp = $now + 600
    } | ConvertTo-Json -Compress

    $toBase64Url = { param($bytes) [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_') }

    $headerB64 = & $toBase64Url ([System.Text.Encoding]::UTF8.GetBytes($header))
    $payloadB64 = & $toBase64Url ([System.Text.Encoding]::UTF8.GetBytes($payload))

    $signingInput = "$headerB64.$payloadB64"
    $rsa = $Certificate.PrivateKey
    $sigBytes = $rsa.SignData(
        [System.Text.Encoding]::UTF8.GetBytes($signingInput),
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
    )
    $sigB64 = & $toBase64Url $sigBytes

    return "$headerB64.$payloadB64.$sigB64"
}

Export-ModuleMember -Function New-CopilotGovGraphContext, Connect-CopilotGovGraph, Invoke-CopilotGovGraphRequest
