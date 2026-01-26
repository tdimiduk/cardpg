import { test, expect } from "./fixtures";

test("can send a chat message and see it in the log", async ({
  loadedPage,
}) => {
  // Find the chat input
  const chatInput = loadedPage.getByTestId("chat-input");
  await expect(chatInput).toBeVisible();

  // Type a unique test message
  const testMessage = `Test message ${Date.now()}`;
  await chatInput.fill(testMessage);

  // Click the send button
  const sendButton = loadedPage.getByTestId("chat-send");
  await sendButton.click();

  // Verify the message appears in the game log
  const gameLog = loadedPage.getByTestId("game-log");
  await expect(gameLog).toBeVisible();

  // Wait for at least one message with our text to appear
  // Using .first() to handle potential duplicates from broadcast
  const logMessage = loadedPage
    .getByTestId("log-entry-message")
    .filter({ hasText: testMessage })
    .first();
  await expect(logMessage).toBeVisible({ timeout: 5000 });
});

test("can send chat message with Enter key", async ({ loadedPage }) => {
  // Find the chat input
  const chatInput = loadedPage.getByTestId("chat-input");
  await expect(chatInput).toBeVisible();

  const testMessage = `Enter key test ${Date.now()}`;
  await chatInput.fill(testMessage);
  await chatInput.click(); // Click ensures focus
  await expect(chatInput).toHaveValue(testMessage);

  // Press Enter on the input element
  await chatInput.press("Enter");

  // Verify the input was cleared (confirms Enter was received)
  await expect(chatInput).toHaveValue("");

  // Wait for the message to appear - using first() to handle duplicates
  const logMessage = loadedPage
    .getByTestId("log-entry-message")
    .filter({ hasText: testMessage })
    .first();
  await expect(logMessage).toBeVisible({ timeout: 5000 });
});
