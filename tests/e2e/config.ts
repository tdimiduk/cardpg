/**
 * Centralized configuration for e2e tests.
 * These values must stay in sync with process-compose.yaml and Caddyfile.
 */
export const config = {
  /** Port where Caddy serves the full app (frontend + proxied API) */
  appPort: 3000,
  /** Port where the backend server runs directly */
  serverPort: 3001,
  /** Base URL for Playwright tests */
  get baseURL() {
    return `http://localhost:${this.appPort}`;
  },
};
