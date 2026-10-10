# B2B: Organizations, SAML federation (Okta) and OIDC federation (Entra ID)

## Scenario

A service provider runs one customer portal for many business customers. Each customer is an **Auth0 Organization**. Larger customers sign in with **their own IdP**; smaller ones use accounts stored in Auth0.

| Customer (fictional) | Organization | How users sign in |
|---|---|---|
| Acme Logistics | `acme-logistics` | Database accounts **and** SAML from Acme's **Okta** (`acme-okta`) |
| Globex Retail | `globex-retail` | Database accounts **and** OIDC from Globex's **Entra ID** (`globex-entra`) |

Portal settings: **Type of Users = Business Users**, **Login Flow = Prompt for Organization**, **Organization Discovery = organization name**.

## SAML: Acme's Okta → Auth0

**What the service provider (Auth0) gives the customer:**

| Value | Pattern |
|---|---|
| ACS URL | `https://YOUR_TENANT.us.auth0.com/login/callback?connection=acme-okta` |
| SP Entity ID / Audience | `urn:auth0:YOUR_TENANT:acme-okta` |

**What the customer (Okta) gives back:** IdP SSO URL, signing certificate, Issuer, ideally as a single **metadata URL**. In the metadata XML: Issuer = `entityID`, SSO URL = `SingleSignOnService Location`, cert = `X509Certificate`.

**Okta app settings:** NameID format EmailAddress, Response + Assertion signed (RSA-SHA256), attribute statements `email`, `given_name`, `family_name`.

**Verified in the SAMLResponse (SAML-tracer):**
- `Issuer` = Okta app's entityID
- `Audience` = `urn:auth0:YOUR_TENANT:acme-okta`
- `NameID` = user's email
- `Conditions`: NotBefore / NotOnOrAfter = ±5 minutes around IssueInstant (anti-replay)
- Two embedded certificates: Response **and** Assertion signed

**Result:** user `samlp|acme-okta|<email>` created, auto-added to Acme (JIT membership), ID token contains `org_id` for Acme.

## OIDC: Globex's Entra ID → Auth0

**Service provider gives:** redirect URI `https://YOUR_TENANT.us.auth0.com/login/callback`.
**Customer gives:** Application (client) ID, client secret (expires: track it), tenant domain.

**Result:** user `waad|globex-entra|<Entra object ID>`, auto-added to Globex, `org_id` for Globex, `name` populated.

## SAML vs OIDC, from these two setups

| | SAML (Okta) | OIDC (Entra) |
|---|---|---|
| SP gives customer | ACS URL + Entity ID | Redirect URI |
| Customer gives SP | SSO URL + signing certificate | Client ID + client secret + domain |
| What comes back | Signed XML assertion, **front channel** (browser POST) | Authorization code, exchanged **back channel** |
| Expiring credential | Signing certificate | Client secret |
| Auth0 user ID built from | NameID (email, **mutable**) | Entra object ID (**immutable**) |

Either way, the portal receives the **same OIDC token**: Auth0 normalizes every customer IdP.

**Design note:** keying users on email (SAML default here) means an email change at the customer creates a *new* Auth0 user. Prefer an immutable IdP identifier as the user ID attribute.

## Tenant isolation, verified

| Test | Result |
|---|---|
| Acme database user logs in through `acme-logistics` | ✅ `org_id` = Acme |
| Globex database user logs in through `globex-retail` | ✅ `org_id` = Globex (different value) |
| **Acme user tries to log in through `globex-retail`** | ❌ **Denied**: membership is enforced at login |
| Globex Entra button on Acme's login page | Not shown: connections are enabled per Organization |

APIs must still check `org_id` before returning customer data; the token says *which* customer, the API must enforce it.
