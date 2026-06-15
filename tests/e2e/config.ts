/**
 * Centralized configuration for e2e tests.
 * These values must stay in sync with process-compose.yaml and Caddyfile.
 */
export const config = {
  /** Port where Caddy serves the full app (frontend + proxied API) */
  appPort: Number(process.env.PLAYWRIGHT_PORT || 3000),
  /** Port where the backend server runs directly */
  serverPort: Number(process.env.PLAYWRIGHT_SERVER_PORT || 3001),
  /** Base URL for Playwright tests */
  get baseURL() {
    return (
      process.env.PLAYWRIGHT_BASE_URL || `http://localhost:${this.appPort}`
    );
  },
};
