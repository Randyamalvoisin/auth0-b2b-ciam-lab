// Auth0 Action — Trigger: Login / Post Login
//
// Risk-based MFA: require a second factor only for users holding the
// "Service Manager" role (people who can change a customer's services).
// Everyone else signs in with lower friction.
//
// Production refinement: in a multi-tenant B2B setup, check the user's role
// within the Organization they are signing into (event.organization), not only
// tenant-wide roles, and consider combining with Adaptive MFA risk signals.

exports.onExecutePostLogin = async (event, api) => {
  const roles = event.authorization?.roles || [];
  if (roles.includes('Service Manager')) {
    api.multifactor.enable('any');
  }
};
