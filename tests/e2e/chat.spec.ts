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

test("new messages appear at the bottom of the log", async ({ loadedPage }) => {
  const chatInput = loadedPage.getByTestId("chat-input");
  const sendButton = loadedPage.getByTestId("chat-send");
  await expect(chatInput).toBeVisible();
  await expect(sendButton).toBeVisible();

  // Send first message
  const msg1 = `First message ${Date.now()}`;
  await chatInput.fill(msg1);
  await expect(chatInput).toHaveValue(msg1);
  await sendButton.click();

  // Wait for the input to be cleared
  await expect(chatInput).toHaveValue("");

  // Wait for it to appear in log
  await expect(
    loadedPage
      .getByTestId("log-entry-message")
      .filter({ hasText: msg1 })
      .first(),
  ).toBeVisible();

  // Send second message
  const msg2 = `Second message ${Date.now()}`;
  await chatInput.fill(msg2);
  await expect(chatInput).toHaveValue(msg2);
  await sendButton.click();

  // Wait for the input to be cleared
  await expect(chatInput).toHaveValue("");

  // Wait for it to appear in log
  await expect(
    loadedPage
      .getByTestId("log-entry-message")
      .filter({ hasText: msg2 })
      .first(),
  ).toBeVisible();

  // Get all message texts in order
  const messages = await loadedPage
    .getByTestId("log-entry-message")
    .allTextContents();

  // Find indexes of msg1 and msg2 in the message log
  const index1 = messages.findIndex((m) => m.includes(msg1));
  const index2 = messages.findIndex((m) => m.includes(msg2));

  // Both should be present, and msg1 should appear before msg2 (smaller index)
  expect(index1).toBeGreaterThan(-1);
  expect(index2).toBeGreaterThan(-1);
  expect(index1).toBeLessThan(index2);
});
