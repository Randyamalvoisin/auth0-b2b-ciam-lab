# Attack protection and MFA

## Defense in depth

| Protection | Stops | Gap it leaves |
|---|---|---|
| Brute-force protection | Many failed attempts on **one account from one IP** | Attackers rotating IPs |
| Suspicious IP throttling | **One IP** hitting many accounts | Attackers rotating IPs |
| Breached password detection | Passwords already leaked elsewhere (first-try credential stuffing) | Passwords not in known breaches |
| Bot detection | Automated scripts (CAPTCHA only when traffic looks automated) | Human-driven attacks |
| **MFA** | A correct password alone is not enough | Phishing-resistant FIDO2 / passkeys close most of the rest |

## Brute-force test

- Threshold lowered to 3; 4 wrong passwords → account blocked **for that IP** (`limit_wc`). The **correct** password also failed while blocked.
- Why per-IP: a global lock would let anyone lock out any customer (lockout denial of service).
- Admin actions (unblock, threshold change) appear as **API Operation** events: an audit trail of who changed what.

**Allowlisting:** a large customer's single egress IP can look like credential stuffing. Allowlist it **only from throttling**; users behind it still authenticate with MFA (network location is never proof of identity).

## MFA

- Enabled OTP and WebAuthn (security keys); SMS left off (SIM-swap / interception risk).
- Enrollment events: `gd_enrollment_complete`, *Second Factor Started*, success events, all prefixed by Guardian (`gd_`).
- **Roaming** authenticator (YubiKey, `webauthn-roaming`) vs **platform** authenticator (Windows Hello / Touch ID, `webauthn-platform`). Both are phishing-resistant FIDO2.

## Risk-based MFA with an Action

`actions/mfa-for-service-managers.js` requires MFA only for the Service Manager role. Verified: Service Manager prompted; Billing Viewer not prompted and no `gd_` events logged.

For federated customers, MFA usually happens at the customer's IdP; the SP can verify it from the authentication method evidence (e.g. `amr`) rather than assume it.
