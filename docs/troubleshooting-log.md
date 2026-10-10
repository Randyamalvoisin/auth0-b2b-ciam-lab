# Troubleshooting log

Real issues hit while building the lab, and how each was diagnosed. Method every time: **read the actual error → find the matching log event → compare to configuration → fix → verify.**

| # | Symptom | Evidence | Root cause | Fix |
|---|---|---|---|---|
| 1 | "Callback URL mismatch" on login | Auth0 error page + failure log | Allowed Callback URL had a typo (`/callbak`) | Corrected to `/callback` |
| 2 | `ERR_CONNECTION_REFUSED` on localhost | `app.js` was 0 bytes; later, the `node app.js` line was pasted but never submitted | Empty file / command not run | Wrote file via here-string; pressed Enter |
| 3 | `BadRequestError: authorization response from the server is an error` | `error_description` in the callback URL | Portal requested an audience that didn't exist | Matched `AUDIENCE` in portal and API to the real API identifier |
| 4 | Protected endpoints returned **401** for a valid but under-privileged user | `Unexpected 'permissions' value` | Claim check library reported authz failures as 401 | Switched to `requiredScopes` → correct **403 insufficient_scope** |
| 5 | Users had access beyond their role | Decoded `permissions` claim | Both roles granted all permissions, then flipped | Fixed role → permission mapping; re-login for fresh tokens |
| 6 | Okta: "User is not assigned to this application" | Okta error page; no Auth0 failure | Browser reused an Okta session for an unassigned account | Assigned test users; tested in Incognito. **IdP-side issue.** |
| 7 | "Forbidden" on Auth0's connection tester | URL contained `code=` | Login succeeded; tester page needs a dashboard session | Signed into the dashboard in the same window |
| 8 | Organization prompt: "invalid" for a Gmail address | No Organization domain mapped | Email discovery needs a registered domain; public domains can't map to one customer | Used the organization name |
| 9 | "Wrong email or password" for a federated user | Database form used | Federated users have no password in Auth0 | Used the enterprise connection button |
| 10 | `AADSTS700016` application not found in directory | Client ID in the error ≠ Application (client) ID | **Object ID** pasted instead of Application (client) ID | Used the Application (client) ID |
| 11 | M2M token: `access_denied` / Unauthorized | `feccft` log recognized the client | One wrong character in the client secret | Corrected the secret |
| 12 | Management API tables printed headers but no rows | Data existed in the dashboard | Windows PowerShell 5.1 pipes JSON arrays as one object | Wrapped `Invoke-RestMethod` in parentheses |
