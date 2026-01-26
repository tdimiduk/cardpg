import { test, expect } from "@playwright/test";

test("can send a chat message and see it in the log", async ({ page }) => {
  await page.goto("/");

  // Wait for the app to load
  const app = page.getByTestId("app-container");
  await expect(app).toBeVisible({ timeout: 10000 });

  // Find the chat input
  const chatInput = page.getByTestId("chat-input");
  await expect(chatInput).toBeVisible();

  // Type a unique test message
  const testMessage = `Test message ${Date.now()}`;
  await chatInput.fill(testMessage);

  // Click the send button
  const sendButton = page.getByTestId("chat-send");
  await sendButton.click();

  // Verify the message appears in the game log
  const gameLog = page.getByTestId("game-log");
  await expect(gameLog).toBeVisible();

  // Wait for at least one message with our text to appear
  // Using .first() to handle potential duplicates from broadcast
  const logMessage = page
    .getByTestId("log-entry-message")
    .filter({ hasText: testMessage })
    .first();
  await expect(logMessage).toBeVisible({ timeout: 5000 });
});

test("can send chat message with Enter key", async ({ page }) => {
  await page.goto("/");

  // Wait for the app to load
  const app = page.getByTestId("app-container");
  await expect(app).toBeVisible({ timeout: 10000 });

  // Find the chat input
  const chatInput = page.getByTestId("chat-input");
  await expect(chatInput).toBeVisible();

  // Type a unique test message and press Enter
  const testMessage = `Enter key test ${Date.now()}`;
  await chatInput.fill(testMessage);
  // to force waiting until the text is actually there. It looks like maybe enter can be too fast leading to flakyness
  // Is there a cleaner way to do this?
  await chatInput.selectText(testMessage);
  await chatInput.press("Enter");

  // Wait for the message to appear - using first() to handle duplicates
  const logMessage = page
    .getByTestId("log-entry-message")
    .filter({ hasText: testMessage })
    .first();
  await expect(logMessage).toBeVisible({ timeout: 5000 });

  // Verify the input was cleared after sending
  await expect(chatInput).toHaveValue("");
});
