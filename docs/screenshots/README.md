# Screenshots to add

Recommended captures, each **redacted** before committing (blur tenant domain, client IDs, org IDs, IP addresses, locations, emails you don't want public; never include secrets or full tokens):

| File name | What it shows |
|---|---|
| `01-devtools-auth-code-flow.png` | DevTools Network: `login` 302 → `authorize` (with `code_challenge`) → `callback?code=` |
| `02-seacft-backchannel.png` | Auth0 log `seacft` with the server user agent |
| `03-rbac-results.png` | 200 / 403 responses for each role |
| `04-saml-response.png` | SAML-tracer summary: Issuer, Subject, attributes, two signatures |
| `05-org-login-acme.png` | Acme's branded org login page with the SAML button |
| `06-org-members-jit.png` | Acme members list showing the auto-added `samlp|` user |
| `07-token-org-id.png` | Decoded ID tokens for Acme and Globex showing different `org_id` |
| `08-isolation-denied.png` | Acme user denied when logging in through Globex |
| `09-mfa-logs.png` | `gd_` MFA events and the role-based MFA result |
| `10-tenant-report.png` | `Get-TenantReport.ps1` output |
