<#
.SYNOPSIS
  Calls the Business Services API with a token and prints the status code,
  to demonstrate 200 vs 401 (authentication) vs 403 (authorization).

.EXAMPLE
  .\Test-ApiAuth.ps1 -Token $token
  .\Test-ApiAuth.ps1 -Token "abc.def.ghi"     # garbage token -> 401
  .\Test-ApiAuth.ps1                          # no token      -> 401
#>
param(
  [string] $Token,
  [string] $BaseUrl = 'http://localhost:4000/api',
  [string[]] $Paths = @('public', 'services', 'services/update', 'billing')
)

foreach ($path in $Paths) {
  $headers = @{}
  if ($Token) { $headers.Authorization = "Bearer $Token" }
  try {
    $r = Invoke-RestMethod "$BaseUrl/$path" -Headers $headers
    "{0,-16} 200  {1}" -f $path, ($r | ConvertTo-Json -Compress)
  }
  catch {
    $code = $_.Exception.Response.StatusCode.value__
    "{0,-16} {1}  {2}" -f $path, $code, $_.ErrorDetails.Message
  }
}
