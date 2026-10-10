// Business Services API: a resource server protected by Auth0.
//
// Every protected route answers two separate questions:
//   1. Is this a valid token for this API?  (signature, issuer, audience, expiry) -> else 401
//   2. Does the token carry the scope this route needs?                          -> else 403
//
// With RBAC enabled on the Auth0 API, Auth0 trims `scope` down to what the user's
// roles (or an M2M client's grants) allow, so checking scopes enforces RBAC.

const express = require('express');
const { auth, requiredScopes } = require('express-oauth2-jwt-bearer');

const AUDIENCE = process.env.API_AUDIENCE || 'https://api.example.test';
const ISSUER = process.env.ISSUER_BASE_URL || 'https://YOUR_TENANT.us.auth0.com/';

const app = express();

const checkJwt = auth({
  audience: AUDIENCE,
  issuerBaseURL: ISSUER,
  tokenSigningAlg: 'RS256'
});

app.get('/api/public', (req, res) => {
  res.json({ message: 'Public endpoint: anyone can see this' });
});

app.get('/api/services', checkJwt, requiredScopes('read:services'), (req, res) => {
  res.json({ services: ['Business Internet 1Gig', 'SD-WAN', 'Voice'], caller: req.auth.payload.sub });
});

// A real API would use POST/PATCH; GET keeps the lab easy to click through.
app.get('/api/services/update', checkJwt, requiredScopes('update:services'), (req, res) => {
  res.json({ message: 'Service updated', caller: req.auth.payload.sub });
});

app.get('/api/billing', checkJwt, requiredScopes('read:billing'), (req, res) => {
  res.json({ balance: '$1,249.00', due: '2026-11-01', caller: req.auth.payload.sub });
});

// Return auth failures as readable JSON (401 invalid_token / 403 insufficient_scope).
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({ status: err.status, error: err.code || err.name, message: err.message });
});

app.listen(4000, () => console.log('API running on http://localhost:4000'));
