import { test, expect, Page, Browser, TestInfo } from "@playwright/test";
import { setTimeout } from "timers/promises";

const DOMAIN = process.env.DOMAIN || "u-at-proto.work";
const PARTITION = process.env.PARTITION || "local";
const BASE_URL = `https://social.${PARTITION}.${DOMAIN}`;
const PDS_URL = `pds.${PARTITION}.${DOMAIN}`;

function uniqueId() {
  return Date.now().toString();
}

async function createUser(
  browser: Browser,
  userName: string,
  testInfo: TestInfo,
  pdsUrl: string
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

  await page.getByRole("textbox", { name: "Server address" }).fill(pdsUrl);
  await page.getByRole("button", { name: "Done" }).click();

  const email = `${userName}@test.com`;
  const password = "TestPassword123!";
  await page.getByRole("textbox", { name: /enter.*email/i }).fill(email);
  await page.getByRole("textbox", { name: /choose.*password/i }).fill(password);
  await page.getByRole("button", { name: "Next" }).click();

  await page
    .getByRole("textbox", { name: new RegExp(`\\.${pdsUrl}`) })
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
  await page.getByRole("button", { name: /compose.*post|new post/i }).click();
  await page.getByRole("textbox", { name: "Rich-Text Editor" }).fill(text);
  await page
    .getByText("CancelPost")
    .getByRole("button", { name: /post/i })
    .click();
  await setTimeout(2000);
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

  await expect(
    page.getByText(
      "Unfortunately, none of your subscribed labelers supports this report type."
    )
  ).toBeVisible();
}

test.describe("Alice and Bob interaction", () => {
  test("complete interaction flow", async ({ browser }, testInfo) => {
    const aliceName = `alice${uniqueId()}`;
    const { page: alicePage, context: aliceContext } = await createUser(
      browser,
      aliceName,
      testInfo,
      PDS_URL
    );

    const alicePostText = `Hello from ${aliceName}`;
    await createPost(alicePage, alicePostText);

    const bobName = `bob${uniqueId()}`;
    const { page: bobPage, context: bobContext } = await createUser(
      browser,
      bobName,
      testInfo,
      PDS_URL
    );

    await expect(bobPage.getByText(alicePostText)).toBeVisible();
    await likePost(bobPage, alicePostText);

    const bobReplyText = `Hello ${aliceName}, buy everything from ${bobName}!`;
    await replyToPost(bobPage, alicePostText, bobReplyText);

    await alicePage.getByRole("link", { name: /notifications/i }).click();
    await alicePage.reload();
    await expect(alicePage.getByText(bobReplyText)).toBeVisible();

    // Alice reports Bob's reply for spam
    await reportPost(alicePage, bobReplyText, "Spam");

    // Verify report was submitted successfully
    await expect(
      alicePage.getByText(/report.*submitted|thank.*report/i)
    ).toBeVisible({ timeout: 5000 });

    // STOP HERE - Ready for further instructions
    console.log("✅ Alice successfully reported Bob's post for spam");

    await aliceContext.close();
    await bobContext.close();
  });
});
