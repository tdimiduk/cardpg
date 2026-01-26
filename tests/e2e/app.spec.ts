import { test, expect } from "./fixtures";

test("has title", async ({ page }) => {
  await page.goto("/");

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/CardPG/);
});

test("can verify game interface", async ({ loadedPage }) => {
  // loadedPage already waited for app-container to be visible
  const app = loadedPage.getByTestId("app-container");
  await expect(app).toBeVisible();
});
