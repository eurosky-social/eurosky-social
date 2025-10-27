import { test, expect, Page, Browser, TestInfo } from "@playwright/test";
import { setTimeout } from "timers/promises";
import * as fs from "node:fs";
import * as path from "node:path";

const DOMAIN = process.env.DOMAIN || "u-at-proto.work";
const PARTITION = process.env.PARTITION || "local";
const BASE_URL = `https://social.${PARTITION}.${DOMAIN}`;
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
  const context = await browser.newContext({
    ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
  });
  const page = await context.newPage();

  await page.goto(BASE_URL);

  await page.getByRole("button", { name: "Close welcome modal" }).click();
  await page.getByRole("button", { name: "Create account" }).first().click();

  await page.getByRole("button", { name: "Bluesky Social" }).click();
  await page.getByRole("radio", { name: "Custom" }).click();

  await page.getByRole("textbox", { name: "Server address" }).fill(pdsDomain);
  await page.getByRole("button", { name: "Done" }).click();

  const email = `${userName}@test.com`;
  const password = "TestPassword123!";
  await page.getByRole("textbox", { name: /enter.*email/i }).fill(email);
  await page.getByRole("textbox", { name: /choose.*password/i }).fill(password);
  await page.getByRole("button", { name: "Next" }).click();

  await page
    .getByRole("textbox", { name: new RegExp(`\\.${pdsDomain}`) })
    .fill(userName);
  await page.getByRole("button", { name: "Next" }).click();

  await expect(page.getByText("Give your profile a face")).toBeVisible();
  await page.getByRole("button", { name: /continue|skip/i }).click();

  await expect(page.getByText("What are your interests?")).toBeVisible();
  await page.getByRole("button", { name: /continue|skip/i }).click();

  try {
    await expect(
      page.getByText(/Suggested for you|Free your feed/)
    ).toBeVisible();
    await page.getByRole("button", { name: /continue|skip/i }).click();
  } catch {
    await expect(page.getByText(/You're ready to go!/)).toBeVisible();
    await page.getByText(/let.*go/i).click();
  }

  await expect(page.getByText(/what.*hot/i).first()).toBeVisible({
    timeout: 15000,
  });

  return { page, context };
}

async function createPost(page: Page, text: string) {
  await page.getByRole("button", { name: /^New post$/ }).click();
  await page.getByRole("textbox", { name: "Rich-Text Editor" }).fill(text);
  await page
    .getByText("CancelPost")
    .getByRole("button", { name: /post/i })
    .click();
  await setTimeout(5000);
  await page.reload();
  await expect(page.getByText(text, { exact: false })).toBeVisible();
}

async function replyToPost(page: Page, postText: string, replyText: string) {
  await page
    .getByRole("link", { name: postText, exact: false })
    .getByRole("button", { name: /reply/i })
    .click();
  await page.getByRole("textbox", { name: "Rich-Text Editor" }).fill(replyText);
  await page
    .getByText("CancelReply")
    .getByRole("button", { name: /reply/i })
    .click();
  await setTimeout(2000);
  await page.reload();
  await expect(page.getByText(replyText)).toBeVisible();
}

async function likePost(page: Page, postText: string) {
  await page
    .getByRole("link", { name: postText, exact: false })
    .getByRole("button", { name: /like/i })
    .click();
  await setTimeout(2000);
  await page.reload();
}

async function reportPost(
  page: Page,
  postText: string,
  reason: string = "Spam"
) {
  await page
    .getByRole("link", { name: postText, exact: false })
    .getByRole("button", { name: "Open post options menu" })
    .click();

  await page.getByRole("menuitem", { name: /report/i }).click();

  await page
    .getByRole("button", { name: new RegExp(`create.*report.*${reason}`, "i") })
    .click();

  await page.getByRole("button", { name: /submit report/i }).click();
}

test.describe("Alice and Bob interaction", () => {
  test("complete interaction flow", async ({ browser }, testInfo) => {
    // const aliceName = `alice${uniqueId()}`;
    // const { page: alicePage, context: aliceContext } = await createUser(
    //   browser,
    //   aliceName,
    //   testInfo,
    //   PDS_DOMAIN
    // );

    // const alicePostText = `Hello from ${aliceName}`;
    // await createPost(alicePage, alicePostText);

    // const bobName = `bob${uniqueId()}`;
    // const { page: bobPage, context: bobContext } = await createUser(
    //   browser,
    //   bobName,
    //   testInfo,
    //   PDS_DOMAIN
    // );

    // await expect(bobPage.getByText(alicePostText)).toBeVisible();
    // await likePost(bobPage, alicePostText);

    // const bobReplyText = `Hello ${aliceName}, buy everything from ${bobName}!`;
    // await replyToPost(bobPage, alicePostText, bobReplyText);

    // await alicePage.getByRole("link", { name: /notifications/i }).click();
    // await alicePage.reload();
    // await expect(alicePage.getByText(bobReplyText)).toBeVisible();

    // // Alice reports Bob's reply for spam
    // await reportPost(alicePage, bobReplyText, "Spam");

    const { page: adminPage, context: adminContext } = await createOzoneAdmin(
      browser,
      testInfo,
      PDS_DOMAIN
    );
    await setTimeout(2000);
    const bobName = `test5112.pds.eurosky.u-at-proto.work`; // TODO Remove me
    adminPage
      .getByRole("link", { name: `@${bobName}.pds.eurosky.u-at-proto.work` })
      .first();
    await setTimeout(2000);

    // Wait for the action panel dialog to appear automatically with account as subject
    await expect(
      adminPage.getByRole("dialog", { name: /take moderation action/i })
    ).toBeVisible({ timeout: 10000 });
    await expect(adminPage.getByText(/reported user/i)).toBeVisible();

    // Takedown
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

    // Send Email
    await expect(
      adminPage.getByRole("button", { name: /^send email$/i }).first()
    ).toBeVisible();

    // Wait for the email composer form to appear - look for the email Subject field (not the action subject)
    const subjectInput = adminPage.getByPlaceholder(
      "Subject line for the email"
    );
    await expect(subjectInput).toBeVisible({ timeout: 5000 });

    // Fill in the email subject
    await subjectInput.fill("Moderation Action: Content Takedown Notice");

    // Fill in the email message using the MDEditor textarea
    // The MDEditor component renders a textarea with specific classes
    const messageTextarea = adminPage.locator(".w-md-editor-text-input");
    await expect(messageTextarea).toBeVisible();
    await messageTextarea.fill(
      "Hello,\n\nWe have taken action on your content due to a spam violation. " +
        "Your post containing spam has been hidden from the platform.\n\n" +
        "If you believe this was done in error, please contact support.\n\n" +
        "Best regards,\nModeration Team"
    );

    // Submit the email using the Send button (the submit type button, not the dropdown)
    await adminPage.getByRole("button", { name: "Send", exact: true }).click();
    await setTimeout(15000);

    await adminContext.close();
    // await aliceContext.close();
    // await bobContext.close();
  });
});
