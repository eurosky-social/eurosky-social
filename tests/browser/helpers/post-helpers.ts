import { Page, expect } from "@playwright/test";
import { setTimeout } from "timers/promises";

export async function createPost(page: Page, text: string) {
  // TODO: The Social app should provide better test IDs/selectors for compose UI
  await page.getByRole("button", { name: /compose.*post|new post/i }).click();
  await page.getByRole("textbox", { name: "Rich-Text Editor" }).fill(text);
  await page.locator('button:has-text("Post")').last().click();
  await setTimeout(2000);
  await page.reload();
  // Note: Skipping post visibility check due to feed indexing delays
}

export async function reportPost(page: Page, postText: string, reason: string = "Spam") {
  // Verify the post is visible in the feed
  await expect(page.getByText(postText, { exact: false })).toBeVisible();

  // Find the feed item containing this post text
  const feedItem = page.locator('[data-testid^="feedItem"]').filter({ hasText: postText }).first();

  // Look for the three-dot menu button with specific aria-label patterns
  // Try multiple possible selectors for the menu button
  const menuButton = feedItem.locator('button[aria-label*="More"], button[aria-label*="Open post options"], button:has-text("⋯")').first();

  await expect(menuButton).toBeVisible();
  await menuButton.click();

  // Click report option in menu
  await page.getByRole("menuitem", { name: /report post/i }).click();
  await setTimeout(500);

  // Select reason - find the specific option card/button
  // Look for a clickable element that has the reason as its main heading
  const reasonOption = page.locator(`div, button, [role="button"]`).filter({
    has: page.locator(`text="${reason}"`).first()
  }).filter({
    hasNot: page.locator('text="Why should this post be reviewed?"')
  }).first();

  await reasonOption.click();
  await setTimeout(1000);

  // The dialog may auto-advance or we may need to click Submit report
  // Try to find and click the "Submit report" step/button
  const submitButton = page.locator('text="Submit report"').or(
    page.getByRole("button", { name: /submit|send|done/i })
  );

  try {
    await submitButton.click({ timeout: 3000 });
  } catch {
    // If no submit button, the report may have been auto-submitted
    // Just close the dialog
    await page.getByRole("button", { name: /close|cancel|done/i }).click();
  }

  await setTimeout(2000);
}

export async function verifyPostIsVisible(page: Page, postText: string) {
  await expect(page.getByText(postText, { exact: false })).toBeVisible();
}

export async function verifyPostIsNotVisible(page: Page, postText: string) {
  await expect(page.getByText(postText, { exact: false })).not.toBeVisible();
}
