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

  // Select custom PDS server (not Bluesky's)
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

  // With the default labeler configured, we should NOT see this error
  // Instead, we should see a success message
  await expect(
    page.getByText(/report.*submitted|Thank you|received/i)
  ).toBeVisible({ timeout: 10000 });
}

test.describe("Report with Default Labeler", () => {
  test("create user and report a post with default labeler", async ({ browser }, testInfo) => {
    const userName = `reporter${uniqueId()}`;
    const { page, context } = await createUser(
      browser,
      userName,
      testInfo,
      PDS_URL
    );

    // Create a post to report
    const postText = `This is a test post from ${userName}`;
    await createPost(page, postText);

    // Report the post for spam
    await reportPost(page, postText, "Spam");

    // Verify the report was successful
    await expect(
      page.getByText(/report.*submitted|Thank you/i)
    ).toBeVisible();

    await context.close();
  });
});
