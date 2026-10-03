import { test, expect } from "./fixtures";

test("can pass with no action and revise in planning phase", async ({
  loadedPage,
}) => {
  // Select Vallhach actor
  const vallhachSelector = loadedPage.getByTestId("select-actor-Vallhach");
  await expect(vallhachSelector).toBeVisible();
  await vallhachSelector.click();

  const noActionButton = loadedPage.getByTestId("plan-no-action");
  const reviseButton = loadedPage.getByTestId("revise-action");

  // Wait for either button to appear
  await expect(noActionButton.or(reviseButton)).toBeVisible({ timeout: 5000 });

  // If already planned (e.g. from persisted state), revise first
  if (await reviseButton.isVisible()) {
    await reviseButton.click();
    await expect(noActionButton).toBeVisible({ timeout: 5000 });
  }

  // Click No Action
  await expect(noActionButton).toBeVisible();
  await noActionButton.click();

  // After clicking No Action, Revise button should become visible
  await expect(reviseButton).toBeVisible({ timeout: 5000 });

  // Click Revise and verify No Action reappears
  await reviseButton.click();
  await expect(noActionButton).toBeVisible({ timeout: 5000 });
});
