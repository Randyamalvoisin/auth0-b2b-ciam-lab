# Machine-to-machine access and Management API automation

## Partner integration (client credentials)

- M2M app **authorized** for the Business Services API with only `read:services`.
- Token via `scripts/Get-M2MToken.ps1`: `gty = client-credentials`, `sub = <client_id>@clients` (no user).

| Call | Result | Why |
|---|---|---|
| `/api/services` | 200 | Has `read:services` |
| `/api/services/update` | 403 | Missing `update:services` |
| `/api/billing` | 403 | Missing `read:billing` |
| Token request asking for `update:services` | **Refused** | M2M scopes are fixed by the admin's grant |

**User vs M2M scope requests:** for a user, Auth0 trims unauthorized scopes and still issues a token; for an M2M client, it refuses the request. Either way, nobody can raise their own permissions.

**Secret rotation:** old secret → `feccft` failure; new secret → `seccft` success; tokens already issued remain valid until `exp`.

## Admin automation (Management API)

`scripts/Get-TenantReport.ps1` uses a separate M2M app authorized for the Auth0 Management API with **read-only** scopes:

`read:users`, `read:logs`, `read:organizations`, `read:organization_members`

It produces:
- **User inventory by identity source**: `auth0` (database), `samlp` (SAML/Okta), `waad` (Entra)
- **Organization membership**: the raw input for a customer access review
- **Recent failed events** (`type:f*`): failed logins and failed token exchanges

A `DELETE /api/v2/users/{id}` with this token returns **403 insufficient_scope**: least privilege limits the blast radius if the secret leaks.

## Troubleshooting found along the way

- `access_denied` / `Unauthorized` on the token request: the `feccft` log showed the client ID was recognized, so the **secret** was wrong (one bad character).
- Windows PowerShell 5.1 returned **empty tables**: `Invoke-RestMethod` passes a JSON array as one object; wrapping the call in parentheses fixes it. An empty result is not proof of no data.
