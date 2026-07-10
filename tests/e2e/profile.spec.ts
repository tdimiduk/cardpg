import { test, expect } from "@playwright/test";

test("profile selection registration and switching workflow", async ({
  page,
}) => {
  page.on("console", (msg) =>
    console.log(`[E2E Browser Console] [${msg.type()}] ${msg.text()}`),
  );
  page.on("pageerror", (err) =>
    console.error(`[E2E Browser Error] ${err.message}`),
  );

  // 1. Navigate to the app with clear local storage
  await page.goto("/");

  // 2. Verify setup overlay is visible on startup
  const setupOverlay = page.getByTestId("setup-overlay");
  await expect(setupOverlay).toBeVisible();

  // 3. Verify submit button "Begin Adventure" is disabled
  const beginBtn = page.getByRole("button", { name: "Begin Adventure" });
  await expect(beginBtn).toBeDisabled();

  // 4. Fill in display name
  const nameInput = page.getByPlaceholder("Your name...");
  await nameInput.fill("Arthur Pendragon");

  // 5. Verify button is still disabled (no role selected)
  await expect(beginBtn).toBeDisabled();

  // 6. Select "Game Master" role card
  const gmCard = page.getByText("Game Master");
  await gmCard.click();

  // 7. Verify button is now enabled
  await expect(beginBtn).toBeEnabled();

  // 8. Submit profile
  await beginBtn.click();

  // 9. Verify setup overlay disappears and main app loads
  await expect(setupOverlay).not.toBeVisible();
  const appContainer = page.getByTestId("app-container");
  await expect(appContainer).toBeVisible();

  // 10. Verify name and role in the sidebar header
  await expect(page.getByText("Arthur Pendragon")).toBeVisible();
  await expect(page.getByText("Game Master")).toBeVisible();

  // 11. Click "Switch Profile"
  const switchBtn = page.getByRole("button", { name: "Switch Profile" });
  await expect(switchBtn).toBeVisible();
  await switchBtn.click();

  // 12. Verify we are returned to the setup overlay and input is cleared
  await expect(setupOverlay).toBeVisible();
  await expect(nameInput).toHaveValue("");
  await expect(beginBtn).toBeDisabled();
});
