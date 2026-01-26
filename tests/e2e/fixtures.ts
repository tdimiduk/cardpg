import { test as base, expect, Page } from "@playwright/test";

/**
 * Extended test fixture that provides a page already loaded with the app visible.
 * Use `loadedPage` instead of `page` to skip the boilerplate goto + wait.
 */
export const test = base.extend<{ loadedPage: Page }>({
  loadedPage: async ({ page }, use) => {
    await page.goto("/");
    await expect(page.getByTestId("app-container")).toBeVisible({
      timeout: 10000,
    });
    await use(page);
  },
});

export { expect };
