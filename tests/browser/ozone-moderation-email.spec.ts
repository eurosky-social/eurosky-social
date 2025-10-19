import { test, expect, Page } from "@playwright/test";
import { ComAtprotoModerationDefs } from "@atproto/api";
import { createTestUser } from "../helpers/test-user-factory";
import * as fs from "node:fs";
import * as path from "node:path";
import "dotenv/config";

const DOMAIN = process.env.DOMAIN;
if (!DOMAIN) {
  throw new Error("DOMAIN env var is required");
}

const PARTITION = process.env.PARTITION;
if (!PARTITION) {
  throw new Error("PARTITION env var is required");
}

const PDS_URL = `https://pds.${PARTITION}.${DOMAIN}`;
const OZONE_URL = `https://ozone.${PARTITION}.${DOMAIN}`;
const MAILDEV_URL = process.env.MAILDEV_URL || `https://maildev.${PARTITION}.${DOMAIN}`;

// Read Ozone DID from shared volume file
const ozoneDidPath = path.join(__dirname, "..", "data", "ozone-admin-did.txt");
if (!fs.existsSync(ozoneDidPath)) {
  throw new Error(`Ozone DID file not found at ${ozoneDidPath}`);
}
const OZONE_SERVER_DID = fs.readFileSync(ozoneDidPath, "utf-8").trim();

function getOzoneCreds() {
  const did = OZONE_SERVER_DID;
  const password = process.env.OZONE_ADMIN_PASSWORD || "admin123";
  return { did, password };
}

async function loginToOzone(page: Page, pdsUrl: string, identifier: string, password: string) {
  await page.goto(OZONE_URL);
  await expect(page.getByRole("heading", { name: /ozone moderation service/i })).toBeVisible();

  // Fill in PDS URL using label
  await page.getByLabel(/service/i).clear();
  await page.getByLabel(/service/i).fill(pdsUrl);

  // Fill in credentials
  await page.getByPlaceholder(/account handle/i).fill(identifier);
  await page.getByPlaceholder(/password/i).fill(password);

  // Submit login
  await page.getByRole("button", { name: /sign in/i }).click();

  // Verify login by checking for navigation sidebar (Reports link)
  await expect(page.getByRole("link", { name: /^reports$/i })).toBeVisible({ timeout: 10000 });
}

async function getEmailCount(page: Page): Promise<number> {
  const apiResponse = await page.request.get(`${MAILDEV_URL}/email`);
  const emails = await apiResponse.json();
  return Array.isArray(emails) ? emails.length : 0;
}

async function getLatestEmail(page: Page): Promise<any> {
  const apiResponse = await page.request.get(`${MAILDEV_URL}/email`);
  const emails = await apiResponse.json();
  if (!Array.isArray(emails) || emails.length === 0) {
    return null;
  }
  return emails[emails.length - 1];
}

test.describe("Ozone Moderation Email E2E", () => {
  test("complete journey: spam post → takedown label via UI → email sent to user", async ({ page }) => {
    test.setTimeout(120000); // 2 minutes for the entire test

    // Arrange - Create spammer and reporter users
    const spammer = await createTestUser(PDS_URL);
    const reporter = await createTestUser(PDS_URL);

    console.log(`Created spammer: ${spammer.agent.session!.handle} (${spammer.agent.session!.did})`);
    console.log(`Created reporter: ${reporter.agent.session!.handle}`);

    // Create a spam post from the spammer
    const postResult = await spammer.agent.app.bsky.feed.post.create(
      { repo: spammer.agent.session!.did },
      {
        text: "This is spam content - testing moderation email",
        createdAt: new Date().toISOString(),
      }
    );

    console.log(`Created spam post: ${postResult.uri}`);

    // Reporter creates a spam report to Ozone
    const reporterOzoneAgent = reporter.agent.withProxy("atproto_labeler", OZONE_SERVER_DID);
    await reporterOzoneAgent.com.atproto.moderation.createReport({
      reasonType: ComAtprotoModerationDefs.REASONSPAM,
      subject: {
        $type: "com.atproto.repo.strongRef",
        uri: postResult.uri,
        cid: postResult.cid,
      },
      reason: "Spam content detected - automated test",
    });

    console.log("Spam report created successfully");

    // Get initial email count
    const initialEmailCount = await getEmailCount(page);
    console.log(`Initial email count: ${initialEmailCount}`);

    // Act - Login to Ozone UI as admin
    const { did, password } = getOzoneCreds();
    await loginToOzone(page, PDS_URL, did, password);

    // Navigate directly to the account with quickOpen modal (opens with account DID as subject)
    await page.goto(`${OZONE_URL}/reports?resolved=false&quickOpen=${encodeURIComponent(spammer.agent.session!.did)}`);

    // Wait for the action panel dialog to appear automatically with account as subject
    await expect(page.getByRole("dialog", { name: /take moderation action/i })).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(/reported user/i)).toBeVisible();

    // Open the action dropdown
    const acknowledgeButton = page.getByRole("button", { name: /^acknowledge$/i }).first();
    await acknowledgeButton.click();

    // Wait for the dropdown menu to appear
    const emailMenuItem = page.getByRole("menuitem", { name: /send email/i });
    await expect(emailMenuItem).toBeVisible();

    // Click "Send Email" option
    await emailMenuItem.click();

    // Wait for the email composer form to appear - look for the email Subject field (not the action subject)
    const subjectInput = page.getByPlaceholder('Subject line for the email');
    await expect(subjectInput).toBeVisible({ timeout: 5000 });

    // Fill in the email subject
    await subjectInput.fill("Moderation Action: Content Takedown Notice");

    // Fill in the email message using the MDEditor textarea
    // The MDEditor component renders a textarea with specific classes
    const messageTextarea = page.locator('.w-md-editor-text-input');
    await expect(messageTextarea).toBeVisible();
    await messageTextarea.fill(
      "Hello,\n\nWe have taken action on your content due to a spam violation. " +
      "Your post containing spam has been hidden from the platform.\n\n" +
      "If you believe this was done in error, please contact support.\n\n" +
      "Best regards,\nModeration Team"
    );

    // Submit the email using the Send button (the submit type button, not the dropdown)
    const sendButton = page.getByRole("button", { name: "Send", exact: true });
    await expect(sendButton).toBeVisible();

    // Check if button is disabled (might need to fill required field)
    const isDisabled = await sendButton.isDisabled();
    if (isDisabled) {
      console.log("Send button is disabled - checking for validation errors");
      await page.screenshot({ path: 'test-results/send-button-disabled.png' });
    }

    // Wait for network response after clicking send
    // Note: Ozone has a 1-second delay before actually submitting (shows "Action will be performed in 1s")
    const responsePromise = page.waitForResponse(
      response => response.url().includes('emitEvent') && response.request().method() === 'POST',
      { timeout: 15000 }  // Increased timeout to account for the delay
    ).catch(() => null);

    await sendButton.click();

    // Wait for the delayed submission to actually happen
    const response = await responsePromise;

    if (response) {
      const status = response.status();
      console.log(`Email API response status: ${status}`);

      if (status !== 200) {
        const responseBody = await response.text();
        console.log(`Email API error response: ${responseBody}`);
        throw new Error(`Failed to send email: HTTP ${status} - ${responseBody}`);
      }
    } else {
      console.log("No emitEvent API call detected - form may not have submitted");
      await page.screenshot({ path: 'test-results/no-api-call.png' });
    }

    console.log("Email send action completed");

    // Assert - Verify email was received in MailDev
    // Wait a bit for the email to be delivered
    await page.waitForTimeout(2000);

    const finalEmailCount = await getEmailCount(page);
    console.log(`Final email count: ${finalEmailCount}`);

    expect(finalEmailCount).toBeGreaterThan(initialEmailCount);

    // Get the latest email and verify its content
    const latestEmail = await getLatestEmail(page);
    expect(latestEmail).not.toBeNull();
    expect(latestEmail.subject).toContain("Moderation Action");
    expect(latestEmail.html || latestEmail.text).toContain("spam violation");

    console.log(`Email verification successful! Subject: ${latestEmail.subject}`);
  });
});
