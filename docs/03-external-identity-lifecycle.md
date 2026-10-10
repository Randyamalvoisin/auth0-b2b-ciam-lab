# Lifecycle for external identities

Onboarding is the easy half. These tests show **what actually stops access** at each layer when a customer's user should lose it.

## Layers

| Layer | Example | Owned by |
|---|---|---|
| Customer IdP | Acme's Okta | The customer's IT team |
| Identity platform | Auth0 Organization membership, user status, sessions | Service provider IAM |
| App + tokens | Portal session, access token | Valid until expiry |

## Tests and results

| Action | Existing session / token | New login |
|---|---|---|
| Remove user from the Organization (Auth0) | **Still works** until token/session expiry | **Denied**: membership checked at login |
| Unassign user from the app at the customer's Okta | **Still works** | **Fails at Okta** ("User is not assigned to this application"); Auth0 receives no assertion |
| **Block** user in Auth0, while Okta still allows them | Revoke sessions to end | **Denied by Auth0** ("user is blocked"): the SP has the final say |
| Rotate a leaked M2M client secret | Old access token **still valid** until `exp` | Old secret **fails** (`feccft`), new secret works |

## Control matrix

| Control | Owner | Stops new logins | Kills existing access tokens |
|---|---|---|---|
| Unassign / deactivate at customer IdP | Customer | ✅ (once the Auth0 session is gone) | ❌ |
| Remove from Organization | SP | ✅ | ❌ |
| Block user | SP | ✅ even if the IdP says yes | ❌ |
| Revoke sessions + refresh tokens | SP | ✅ forces re-auth | Partly: stops renewal |
| Short access-token lifetime | SP (design) | — | ✅ shrinks the window |

## Key takeaway

> Removing access stops **new** logins immediately, but tokens and sessions already issued stay valid until they expire. Keep access tokens short-lived, set sensible session lifetimes (they decide how often the customer IdP is re-checked), and revoke sessions / block users for urgent cases.

## Notes from testing

- Auth0 session SSO can skip the customer IdP entirely on a new app login; logging out (`auth0Logout: true`) was needed for the IdP change to take effect.
- An IdP-side denial leaves **no failure in Auth0's logs**. Empty SP logs + "can't log in" points to the customer's side.
- MFA reset ("lost my key") is a common ticket and a social-engineering target: verify identity first.
