import { test as base, expect, Page } from "@playwright/test";

/**
 * Extended test fixture that provides a page already loaded with the app visible.
 * Use `loadedPage` instead of `page` to skip the boilerplate goto + wait.
 */
export const test = base.extend<{ loadedPage: Page }>({
  loadedPage: async ({ page }, use) => {
    page.on("console", (msg) =>
      console.log(`[E2E Browser Console] [${msg.type()}] ${msg.text()}`),
    );
    page.on("pageerror", (err) =>
      console.error(`[E2E Browser Error] ${err.message}`),
    );

    await page.goto("/");
    await page.evaluate(() => {
      window.localStorage.setItem("cardpg_client_name", "E2ETester");
      window.localStorage.setItem("cardpg_client_role", "GM");
    });
    await page.reload();
    await expect(page.getByTestId("app-container")).toBeVisible({
      timeout: 10000,
    });
    await use(page);
  },
});

export { expect };
