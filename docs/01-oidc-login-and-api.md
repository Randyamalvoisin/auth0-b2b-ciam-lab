# OIDC login and a protected API with RBAC

## What was built

- **Business Portal** (Regular Web Application) signing users in with the **Authorization Code flow + PKCE**.
- **Business Services API** (`https://api.example.test`) with permissions `read:services`, `update:services`, `read:billing`, RBAC enabled, and "Add Permissions in the Access Token" on.
- **Roles:** Service Manager (`read:services`, `update:services`), Billing Viewer (`read:billing`).

## The flow, as captured in browser DevTools

1. `GET /login` → **302** from the portal to Auth0 `/authorize`.
2. `/authorize` carries `client_id`, `redirect_uri`, `response_type=code`, `scope`, `state`, `nonce`, `code_challenge`, `code_challenge_method=S256`.
3. User authenticates (or consents; Auth0 always asks consent for apps on `localhost`).
4. `GET /callback?code=…&state=…&iss=…` back to the portal.
5. **Not visible in the browser:** the portal's server exchanges the code + client secret + PKCE `code_verifier` at `/oauth/token`. This is the **back channel**. The Auth0 log confirms it with a `seacft` event whose user agent is the Node server, not Chrome.
6. Portal validates the ID token (`iss`, `aud` = client ID, `exp`, `nonce` matches step 2) and creates a session.

## Tokens

| | ID token | Access token |
|---|---|---|
| For | The **app** | The **API** |
| `aud` | Client ID | API identifier (`https://api.example.test`) |
| Carries | Who the user is | `scope` / `permissions` the user is allowed |
| Lifetime observed | 10 hours (36,000 s) | 24 hours (86,400 s) |

Never send an ID token to an API: it fails the audience check (401).

## 401 vs 403

| Result | Question that failed | Typical causes |
|---|---|---|
| **401 Unauthorized** | *Is this a valid token for this API?* | No token, bad signature, wrong `aud` (e.g. an ID token), expired, wrong issuer |
| **403 Forbidden** | *Is this caller allowed to do this?* | Valid token without the required scope / permission |

Verified results:

| Endpoint | Service Manager | Billing Viewer |
|---|---|---|
| `/api/public` | 200 | 200 |
| `/api/services` | 200 | 403 |
| `/api/services/update` | 200 | 403 |
| `/api/billing` | 403 | 200 |

## Lessons

- **Audience matters to both sides.** The portal requests it; the API enforces it. A typo'd audience broke *login* (Auth0 had no such API) before any API call was made.
- **RBAC trims scopes for users.** A user who requests scopes they don't hold still gets a token, minus those scopes.
- **Tokens are snapshots.** Changing a role does not change a token already issued; the user must sign in again (or the token must expire).
- **Least privilege needs verification.** Roles initially granted every permission; decoding the token (`permissions` claim) is what exposed it.
