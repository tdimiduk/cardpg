import { test, expect } from "./fixtures";

test("can open editor and save a card with validation checks", async ({
  loadedPage,
}) => {
  // Verify the header is visible
  await expect(loadedPage.locator("text=CardPG")).toBeVisible();

  // Open Card Editor via the view mode dropdown
  const viewModeSelect = loadedPage.getByTestId("view-mode-select");
  await expect(viewModeSelect).toBeVisible();
  await viewModeSelect.selectOption({ label: "Card Editor" });

  // Expect the card editor is visible
  await expect(loadedPage.locator("text=Card Authoring Tool")).toBeVisible();

  // Fill fields using sibling selectors
  const nameInput = loadedPage.locator("label:has-text('Card Name') + input");
  await nameInput.fill("Blade Whirl");

  const filePathInput = loadedPage.locator(
    "label:has-text('Target File Path') + input",
  );
  await filePathInput.fill("pc/vallhach.yaml");

  const redStat = loadedPage.locator("label:has-text('Red Stat') + input");
  await redStat.fill("3");

  const yellowStat = loadedPage.locator(
    "label:has-text('Yellow Stat') + input",
  );
  await yellowStat.fill("3");

  const blueStat = loadedPage.locator("label:has-text('Blue Stat') + input");
  await blueStat.fill("0");

  const costInput = loadedPage.locator("label:has-text('Play Cost') + input");
  await costInput.fill("1");

  // Locate the save button
  const saveButton = loadedPage.locator("button:has-text('Save Card to DB')");
  await expect(saveButton).toBeVisible();

  // Fill invalid attack to trigger validation error and disable save button
  const attackInput = loadedPage.locator(
    "label:has-text('Attack (DSL)') + input",
  );
  await attackInput.fill("{InvalidResource}: Str = 4");

  // Verify error text is displayed and save button is disabled
  await expect(loadedPage.locator("text=Attack parse error")).toBeVisible();
  await expect(saveButton).toBeDisabled();

  // Correct the attack input
  await attackInput.fill("{Red}: Str = {Red} + 2");
  await expect(loadedPage.locator("text=Attack parse error")).not.toBeVisible();

  // Fill rules
  const rulesTextarea = loadedPage.locator(
    "label:has-text('Rules') + textarea",
  );
  await rulesTextarea.fill("Passive: +1 {Yellow} when defending");

  // Fill flavor text
  const flavorTextarea = loadedPage.locator(
    "label:has-text('Flavor Text') + textarea",
  );
  await flavorTextarea.fill("A swift blade attack.");

  // Save Card to DB
  await expect(saveButton).toBeEnabled();
  await saveButton.click();

  // Expect success message
  await expect(
    loadedPage.locator("text=Card saved successfully!"),
  ).toBeVisible();
});
