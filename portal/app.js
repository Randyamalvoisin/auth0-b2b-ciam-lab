// Business Portal: a Regular Web Application that signs users in through Auth0
// (OIDC Authorization Code flow with PKCE) and calls the Business Services API
// with the user's access token.
//
// Organization login (Business Users + Prompt for Organization) is configured on
// the application in the Auth0 dashboard, so no code change is needed for B2B.

require('dotenv').config();
const express = require('express');
const { auth, requiresAuth } = require('express-openid-connect');

const app = express();

app.use(auth({
  authRequired: false,
  auth0Logout: true, // also end the Auth0 session on logout
  issuerBaseURL: process.env.ISSUER_BASE_URL,
  baseURL: process.env.BASE_URL,
  clientID: process.env.CLIENT_ID,
  clientSecret: process.env.CLIENT_SECRET,
  secret: process.env.SECRET,
  authorizationParams: {
    response_type: 'code',
    audience: process.env.AUDIENCE, // ask for an access token for our API
    scope: 'openid profile email read:services update:services read:billing'
  }
}));

app.get('/', (req, res) => {
  if (!req.oidc.isAuthenticated()) {
    return res.send('Logged out | <a href="/login">Login</a>');
  }
  const org = req.oidc.user.org_id ? ` (org: ${req.oidc.user.org_id})` : '';
  res.send(`Logged in as ${req.oidc.user.email || req.oidc.user.name}${org}<br>
    <a href="/profile">Profile</a> | <a href="/tokens">Tokens</a> | <a href="/logout">Logout</a><br><br>
    Call the API:
    <a href="/call/public">public</a> |
    <a href="/call/services">services</a> |
    <a href="/call/services/update">services/update</a> |
    <a href="/call/billing">billing</a>`);
});

app.get('/profile', requiresAuth(), (req, res) => {
  res.type('json').send(JSON.stringify(req.oidc.user, null, 2));
});

// LAB ONLY: exposes raw tokens so they can be decoded at jwt.io.
// Never ship an endpoint like this in a real application.
app.get('/tokens', requiresAuth(), (req, res) => {
  res.type('json').send(JSON.stringify({
    id_token: req.oidc.idToken,
    access_token: req.oidc.accessToken?.access_token
  }, null, 2));
});

// The portal calls the API on the user's behalf with a Bearer token.
app.get('/call/*path', requiresAuth(), async (req, res) => {
  const path = [].concat(req.params.path).join('/');
  const r = await fetch(`http://localhost:4000/api/${path}`, {
    headers: { Authorization: `Bearer ${req.oidc.accessToken.access_token}` }
  });
  res.status(r.status).type('json').send(await r.text());
});

app.listen(3000, () => console.log('Running on http://localhost:3000'));
