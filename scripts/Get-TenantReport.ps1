<#
.SYNOPSIS
  Read-only Auth0 Management API report: user inventory by identity source,
  Organization membership (access review input), and recent failed authentications.

.DESCRIPTION
  Uses a dedicated M2M app authorized for the Auth0 Management API with ONLY:
    read:users, read:logs, read:organizations, read:organization_members
  Least privilege: a leaked token from this script can read but cannot change
  or delete anything (a DELETE returns 403 insufficient_scope).

.EXAMPLE
  .\Get-TenantReport.ps1 -Tenant https://YOUR_TENANT.us.auth0.com `
     -ClientId $env:ADMIN_CLIENT_ID -ClientSecret $env:ADMIN_CLIENT_SECRET
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Tenant,
  [Parameter(Mandatory)] [string] $ClientId,
  [Parameter(Mandatory)] [string] $ClientSecret,
  [int] $FailedLogCount = 20
)

$Tenant = $Tenant.TrimEnd('/')
$token = & "$PSScriptRoot\Get-M2MToken.ps1" -Tenant $Tenant -ClientId $ClientId `
          -ClientSecret $ClientSecret -Audience "$Tenant/api/v2/"
if (-not $token) { return }
$h = @{ Authorization = "Bearer $token" }

# Note: wrapping Invoke-RestMethod in parentheses makes Windows PowerShell 5.1
# enumerate JSON arrays item by item; without it, Select-Object returns empty rows.

Write-Host "`n== Users by identity source ==" -ForegroundColor Cyan
(Invoke-RestMethod "$Tenant/api/v2/users?per_page=100" -Headers $h) |
  Select-Object email,
                @{ n = 'source'; e = { ($_.user_id -split '\|')[0] } },  # auth0 / samlp / waad
                logins_count, last_login |
  Format-Table -AutoSize

Write-Host "== Organization membership ==" -ForegroundColor Cyan
foreach ($org in (Invoke-RestMethod "$Tenant/api/v2/organizations" -Headers $h)) {
  Write-Host "-- $($org.display_name) ($($org.name))"
  (Invoke-RestMethod "$Tenant/api/v2/organizations/$($org.id)/members" -Headers $h) |
    Select-Object email, user_id | Format-Table -AutoSize
}

Write-Host "== Last $FailedLogCount failed events ==" -ForegroundColor Cyan
(Invoke-RestMethod "$Tenant/api/v2/logs?q=type:f*&per_page=$FailedLogCount&sort=date:-1" -Headers $h) |
  Select-Object date, type, user_name, description |
  Format-Table -AutoSize
