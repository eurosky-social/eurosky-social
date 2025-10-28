import { test, expect, Page, Browser, TestInfo } from "@playwright/test";
import { setTimeout } from "timers/promises";
import * as fs from "node:fs";
import * as path from "node:path";

const DOMAIN = process.env.DOMAIN || "u-at-proto.work";
const PARTITION = process.env.PARTITION || "local";
const BASE_URL = `https://social.${PARTITION}.${DOMAIN}`;
const MAILDEV = `https://maildev.${PARTITION}.${DOMAIN}`;
const PDS_DOMAIN = `pds.${PARTITION}.${DOMAIN}`;

// Read Ozone DID from shared volume file
const ozoneDidPath = path.join(__dirname, "..", "data", "ozone-admin-did.txt");
if (!fs.existsSync(ozoneDidPath)) {
  throw new Error(`Ozone DID file not found at ${ozoneDidPath}`);
}
const OZONE_SERVER_DID = fs.readFileSync(ozoneDidPath, "utf-8").trim();
const OZONE_URL = `https://ozone.${PARTITION}.${DOMAIN}`;

function uniqueId() {
  return Date.now().toString();
}

async function createOzoneAdmin(
  browser: Browser,
  testInfo: TestInfo,
  pdsDomain: string
) {
  const context = await browser.newContext({
    ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
  });

  const page = await context.newPage();
  await page.goto(OZONE_URL);
  await expect(
    page.getByRole("heading", { name: /ozone moderation service/i })
  ).toBeVisible();

  // Fill in PDS URL using label
  await page.getByLabel(/service/i).clear();
  await page.getByLabel(/service/i).fill(`https://${pdsDomain}`);

  // Fill in credentials
  await page.getByPlaceholder(/account handle/i).fill(OZONE_SERVER_DID);
  const password = process.env.OZONE_ADMIN_PASSWORD || "admin123";
  await page.getByPlaceholder(/password/i).fill(password);

  // Submit login
  await page.getByRole("button", { name: /sign in/i }).click();

  // Verify login by checking for navigation sidebar (Reports link)
  await expect(page.getByRole("link", { name: /^reports$/i })).toBeVisible({
    timeout: 10000,
  });

  return { page, context };
}

async function createUser(
  browser: Browser,
  userName: string,
  testInfo: TestInfo,
  pdsDomain: string
) {
  // User opens browser and goes to the bsky social app url
  const context = await browser.newContext({
    ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
  });
  const page = await context.newPage();
  await page.goto(BASE_URL);

  // User clicks on "Create account" button
  await page.getByRole("button", { name: "Close welcome modal" }).click();
  await page.getByRole("button", { name: "Create account" }).first().click();

  // User selects "Bluesky Social" and then "Custom" to enter its preferred PDS
  await page.getByRole("button", { name: "Bluesky Social" }).click();
  await page.getByRole("radio", { name: "Custom" }).click();
  await page.getByRole("textbox", { name: "Server address" }).fill(pdsDomain);
  await page.getByRole("button", { name: "Done" }).click();

  // User fills in email, password, handle
  const email = `${userName}@test.com`;
  const password = "TestPassword123!";
  await page.getByRole("textbox", { name: /enter.*email/i }).fill(email);
  await page.getByRole("textbox", { name: /choose.*password/i }).fill(password);
  await page.getByRole("button", { name: "Next" }).click();
  await page
    .getByRole("textbox", { name: pdsDomain, exact: false })
    .fill(userName);
  await page.getByRole("button", { name: "Next" }).click();

  // User goes through the onboarding steps
  // Step 1
  await expect(page.getByText("Give your profile a face")).toBeVisible();
  await page.getByRole("button", { name: /continue|skip/i }).click();
  // Step 2
  await expect(page.getByText("What are your interests?")).toBeVisible();
  await page.getByRole("button", { name: /continue|skip/i }).click();
  // Step 3
  try {
    await expect(
      page.getByText(/Suggested for you|Free your feed/)
    ).toBeVisible();
    await page.getByRole("button", { name: /continue|skip/i }).click();
  } catch {
    // Steps have random multipath...
    await expect(page.getByText(/You're ready to go!/)).toBeVisible();
    await page.getByText(/let.*go/i).click();
    // ...they can also fail from time to time
  }

  // Verify that the user is logged in by checking for the home feed
  await expect(page.getByText(/what.*hot/i).first()).toBeVisible({
    timeout: 15000,
  });

  return { page, context };
}

async function takedownAccount(adminPage: Page, user: string) {}

test.describe("Alice and Bob interaction", () => {
  test("complete interaction flow", async ({ browser }, testInfo) => {
    // Alice signs up
    const aliceName = `alice${uniqueId()}`;
    const { page: alicePage, context: aliceContext } = await createUser(
      browser,
      aliceName,
      testInfo,
      PDS_DOMAIN
    );

    // Alice creates a post
    const alicePostText = `Hello from ${aliceName}`;
    await alicePage.getByRole("button", { name: /^New post$/ }).click();
    await alicePage
      .getByRole("textbox", { name: "Rich-Text Editor" })
      .fill(alicePostText);
    await alicePage
      .getByText("CancelPost")
      .getByRole("button", { name: /post/i })
      .click();
    await setTimeout(5000);
    await alicePage.reload();
    await expect(
      alicePage.getByText(alicePostText, { exact: false })
    ).toBeVisible();

    // Bob signs up
    const bobName = `bob${uniqueId()}`;
    const { page: bobPage, context: bobContext } = await createUser(
      browser,
      bobName,
      testInfo,
      PDS_DOMAIN
    );

    // Bob likes Alice's post
    await bobPage
      .getByRole("link", { name: alicePostText, exact: false })
      .getByRole("button", { name: /like/i })
      .click();
    await setTimeout(2000);
    await bobPage.reload();

    // Bob replies to Alice's post with spam
    const bobReplyText = `Hello ${aliceName}, buy everything from ${bobName}!`;
    await bobPage
      .getByRole("link", { name: alicePostText, exact: false })
      .getByRole("button", { name: /reply/i })
      .click();
    await bobPage
      .getByRole("textbox", { name: "Rich-Text Editor" })
      .fill(bobReplyText);
    await bobPage
      .getByText("CancelReply")
      .getByRole("button", { name: /reply/i })
      .click();
    await setTimeout(2000);
    await bobPage.reload();
    await expect(bobPage.getByText(bobReplyText)).toBeVisible();

    // Alice checks notifications
    await alicePage.getByRole("link", { name: /notifications/i }).click();
    await alicePage.reload();
    await expect(alicePage.getByText(bobReplyText)).toBeVisible();

    // Alice finds Bob's reply and reports it as spam
    await alicePage
      .getByRole("link", { name: bobReplyText, exact: false })
      .getByRole("button", { name: "Open post options menu" })
      .click();

    await alicePage.getByRole("menuitem", { name: /report/i }).click();

    await alicePage
      .getByRole("button", {
        name: new RegExp(`create.*report.*spam`, "i"),
      })
      .click();

    await alicePage.getByRole("button", { name: /submit report/i }).click();

    // Moderator (Ozone) logs in
    const { page: adminPage, context: adminContext } = await createOzoneAdmin(
      browser,
      testInfo,
      PDS_DOMAIN
    );

    // Moderator click the report from the Ozone dashboard
    await setTimeout(2000);
    await adminPage
      .getByRole("link", { name: `@${bobName}.${PDS_DOMAIN}` })
      .click();
    await setTimeout(2000);

    // ... Verify report details are visible ...
    await expect(
      adminPage.getByRole("dialog", { name: /take moderation action/i })
    ).toBeVisible();
    await expect(adminPage.getByText(/reported user/i)).toBeVisible();

    // Moderator takes takedown action on Bob's account
    await adminPage
      .getByRole("button", { name: /^acknowledge$/i })
      .first()
      .click();
    await adminPage.getByRole("menuitem", { name: /takedown/i }).click();
    await adminPage
      .getByRole("combobox")
      .filter({ hasText: /permanent/i })
      .selectOption("0");
    await adminPage.getByText("(S)ubmit").click();

    // Moderator sends takedown email to Bob
    await expect(
      adminPage.getByRole("button", { name: /^send email$/i }).first()
    ).toBeVisible();
    const subjectInput = adminPage.getByPlaceholder(
      "Subject line for the email"
    );
    await expect(subjectInput).toBeVisible({ timeout: 5000 });
    await subjectInput.fill("Moderation Action: Content Takedown Notice");
    const messageTextarea = adminPage.locator(".w-md-editor-text-input");
    await expect(messageTextarea).toBeVisible();
    await messageTextarea.fill(
      "Hello,\n\nWe have taken action on your content due to a spam violation. " +
        "Your post containing spam has been hidden from the platform.\n\n" +
        "If you believe this was done in error, please contact support.\n\n" +
        "Best regards,\nModeration Team"
    );
    await adminPage.getByRole("button", { name: "Send", exact: true }).click();
    // There is a 10 sec wait for undoing sending emails
    await setTimeout(15000);

    // Bob tries to create a new post
    await bobPage.getByRole("button", { name: /^New post$/ }).click();
    await bobPage
      .getByRole("textbox", { name: "Rich-Text Editor" })
      .fill("some more spam");
    await bobPage
      .getByText("CancelPost")
      .getByRole("button", { name: /post/i })
      .click();

    // Bob sees account takedown message
    await expect(
      bobPage.getByText(/account has been taken down/i)
    ).toBeVisible();

    // Bob goes finds an account takedown email in his inbox
    await bobPage.goto(MAILDEV);
    await bobPage.getByText(`${bobName}@test.com`).click();
    await setTimeout(2000);
    await expect(
      bobPage
        .locator(".email-content")
        .locator("iframe")
        .first()
        .contentFrame()
        .getByText(
          "We have taken action on your content due to a spam violation"
        )
    ).toBeVisible();

    // Alice checks her post...
    await alicePage.getByRole("link", { name: "Profile", exact: true }).click();
    await alicePage
      .getByRole("link", { name: alicePostText, exact: false })
      .click();
    await setTimeout(2000);
    // ...and find outs Bob's reply is gone
    await expect(alicePage.getByText(bobReplyText)).not.toBeVisible();

    await adminContext.close();
    await aliceContext.close();
    await bobContext.close();
  });
});
