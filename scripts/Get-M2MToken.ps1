<#
.SYNOPSIS
  Gets an access token with the OAuth 2.0 client credentials grant (machine-to-machine).

.EXAMPLE
  $token = .\Get-M2MToken.ps1 -Tenant https://YOUR_TENANT.us.auth0.com `
           -ClientId $env:M2M_CLIENT_ID -ClientSecret $env:M2M_CLIENT_SECRET `
           -Audience https://api.example.test

.NOTES
  Works on Windows PowerShell 5.1 and PowerShell 7. Keep secrets in environment
  variables or a secret store, never in the script or in source control.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Tenant,
  [Parameter(Mandatory)] [string] $ClientId,
  [Parameter(Mandatory)] [string] $ClientSecret,
  [Parameter(Mandatory)] [string] $Audience,
  [string] $Scope
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$body = @{
  client_id     = $ClientId
  client_secret = $ClientSecret
  audience      = $Audience
  grant_type    = 'client_credentials'
}
if ($Scope) { $body.scope = $Scope }

try {
  $resp = Invoke-RestMethod -Method Post -Uri "$($Tenant.TrimEnd('/'))/oauth/token" `
          -ContentType 'application/json' -Body ($body | ConvertTo-Json)
  $resp.access_token
}
catch {
  # 401 access_denied "Unauthorized" = bad client credentials (check the feccft log event)
  # 403 access_denied = client not authorized for this audience or scope
  Write-Error "Token request failed: $($_.ErrorDetails.Message)"
}
