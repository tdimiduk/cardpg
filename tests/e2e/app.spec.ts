import { test, expect } from "@playwright/test";

test("has title", async ({ page }) => {
  await page.goto("/");

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/CardPG/);
});

test("can verify game interface", async ({ page }) => {
  await page.goto("/");

  // Wait for the app to load
  const app = page.getByTestId("app-container");
  await expect(app).toBeVisible({ timeout: 10000 });
});
