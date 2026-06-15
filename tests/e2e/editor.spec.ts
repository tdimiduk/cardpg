import { test, expect } from "./fixtures";

test("can open editor and save a card with validation checks", async ({
  page,
}) => {
  // Go to home page
  await page.goto("/");

  // Verify the header is visible
  await expect(page.locator("text=CardPG Game Console")).toBeVisible();

  // Click "Open Card Editor"
  const openEditorButton = page.locator("text=Open Card Editor");
  await expect(openEditorButton).toBeVisible();
  await openEditorButton.click();

  // Expect the card editor is visible
  await expect(page.locator("text=Card Authoring Tool")).toBeVisible();

  // Fill fields using sibling selectors
  const nameInput = page.locator("label:has-text('Card Name') + input");
  await nameInput.fill("Blade Whirl");

  const filePathInput = page.locator(
    "label:has-text('Target File Path') + input",
  );
  await filePathInput.fill("pc/vallhach.yaml");

  const redStat = page.locator("label:has-text('Red Stat') + input");
  await redStat.fill("3");

  const yellowStat = page.locator("label:has-text('Yellow Stat') + input");
  await yellowStat.fill("3");

  const blueStat = page.locator("label:has-text('Blue Stat') + input");
  await blueStat.fill("0");

  const costInput = page.locator("label:has-text('Play Cost') + input");
  await costInput.fill("1");

  // Locate the save button
  const saveButton = page.locator("button:has-text('Save Card to DB')");
  await expect(saveButton).toBeVisible();

  // Fill invalid attack to trigger validation error and disable save button
  const attackInput = page.locator("label:has-text('Attack (DSL)') + input");
  await attackInput.fill("{InvalidResource}: Str = 4");

  // Verify error text is displayed and save button is disabled
  await expect(page.locator("text=Attack parse error")).toBeVisible();
  await expect(saveButton).toBeDisabled();

  // Correct the attack input
  await attackInput.fill("{Red}: Str = {Red} + 2");
  await expect(page.locator("text=Attack parse error")).not.toBeVisible();

  // Fill rules
  const rulesTextarea = page.locator("label:has-text('Rules') + textarea");
  await rulesTextarea.fill("Passive: +1 {Yellow} when defending");

  // Fill flavor text
  const flavorTextarea = page.locator(
    "label:has-text('Flavor Text') + textarea",
  );
  await flavorTextarea.fill("A swift blade attack.");

  // Save Card to DB
  await expect(saveButton).toBeEnabled();
  await saveButton.click();

  // Expect success message
  await expect(page.locator("text=Card saved successfully!")).toBeVisible();
});
