import { test, expect } from "@playwright/test";
import { AtpAgent } from "@atproto/api";
import {
  signUp,
  loginToOzone,
  uniqueId,
  BASE_URL,
  PDS_URL,
  OZONE_URL,
  OZONE_DID,
} from "./helpers/auth-helpers";
import {
  createPost,
  reportPost,
  verifyPostIsVisible,
  verifyPostIsNotVisible,
} from "./helpers/post-helpers";
import {
  performTakedown,
  waitForReportToAppear,
} from "./helpers/ozone-helpers";
import { subscribeToLabeler } from "./helpers/labeler-helpers";

test.describe("Ozone Moderation Takedown", () => {
  test("post takedown propagates to AppView and hides content", async ({
    browser,
  }, testInfo) => {
    const creatorName = `creator${uniqueId()}`;
    const creatorPostText = `Test post from ${creatorName} - ${uniqueId()}`;

    const creatorContext = await browser.newContext({
      ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
    });
    const creatorPage = await creatorContext.newPage();

    await creatorPage.goto(BASE_URL);
    await signUp(creatorPage, creatorName, PDS_URL);

    const creatorAgent = new AtpAgent({ service: `https://${PDS_URL}` });
    await creatorAgent.login({
      identifier: `${creatorName}.${PDS_URL}`,
      password: "TestPassword123!",
    });
    const creatorDid = creatorAgent.session?.did;
    if (!creatorDid) {
      throw new Error("Failed to get creator DID");
    }

    await createPost(creatorPage, creatorPostText);

    const observerName = `observer${uniqueId()}`;
    const observerContext = await browser.newContext({
      ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
    });
    const observerPage = await observerContext.newPage();

    await observerPage.goto(BASE_URL);
    await signUp(observerPage, observerName, PDS_URL);

    // Subscribe observer to Ozone labeler so they can send reports to it
    await subscribeToLabeler({
      handle: `${observerName}.${PDS_URL}`,
      password: "TestPassword123!",
      pdsUrl: `https://${PDS_URL}`,
      labelerDid: OZONE_DID,
    });

    // Navigate to creator's profile to see their post
    const creatorHandle = `${creatorName}.${PDS_URL}`;
    const profileUrl = `${BASE_URL}/profile/${creatorHandle}`;
    await observerPage.goto(profileUrl);

    // Wait for page to load and profile to appear
    await observerPage.waitForLoadState("networkidle");
    await observerPage.waitForTimeout(2000);

    // Check if page loaded successfully by looking for profile header
    try {
      await expect(observerPage.getByText(creatorName)).toBeVisible({ timeout: 5000 });
    } catch (error) {
      console.log("Profile failed to load with creator name. Checking full page HTML...");
      const html = await observerPage.content();
      console.log(`HTML (first 1000 chars): ${html.substring(0, 1000)}`);
      throw error;
    }

    await verifyPostIsVisible(observerPage, creatorPostText);
    await reportPost(observerPage, creatorPostText, "Spam");

    const ozoneContext = await browser.newContext({
      ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
    });
    const ozonePage = await ozoneContext.newPage();

    await loginToOzone(ozonePage, "ozone.pds.eurosky.u-at-proto.work", "admin123");

    await waitForReportToAppear(ozonePage, creatorPostText);
    await performTakedown(ozonePage, "post");

    await observerPage.reload();
    await observerPage.waitForTimeout(2000);

    await verifyPostIsNotVisible(observerPage, creatorPostText);

    await creatorPage.reload();
    await creatorPage.waitForTimeout(2000);

    await creatorContext.close();
    await observerContext.close();
    await ozoneContext.close();
  });

  test.skip("account takedown hides profile from AppView", async ({
    browser,
  }, testInfo) => {
    const creatorName = `badactor${uniqueId()}`;
    const creatorPostText = `Spam post from ${creatorName} - ${uniqueId()}`;

    const creatorContext = await browser.newContext({
      ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
    });
    const creatorPage = await creatorContext.newPage();

    await creatorPage.goto(BASE_URL);
    await signUp(creatorPage, creatorName, PDS_URL);
    await createPost(creatorPage, creatorPostText);

    const creatorHandle = `${creatorName}.${PDS_URL}`;

    const observerName = `observer${uniqueId()}`;
    const observerContext = await browser.newContext({
      ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
    });
    const observerPage = await observerContext.newPage();

    await observerPage.goto(BASE_URL);
    await signUp(observerPage, observerName, PDS_URL);

    // Subscribe observer to Ozone labeler so they can send reports to it
    await subscribeToLabeler({
      handle: `${observerName}.${PDS_URL}`,
      password: "TestPassword123!",
      pdsUrl: `https://${PDS_URL}`,
      labelerDid: OZONE_DID,
    });

    await observerPage.goto(`${BASE_URL}/profile/${creatorHandle}`);
    await expect(observerPage.getByText(creatorName).first()).toBeVisible();

    await observerPage.getByTestId("profileHeaderDropdownBtn").click();
    await observerPage.getByRole("menuitem", { name: /report account/i }).click();

    const dialog = observerPage.locator('[role="dialog"]');
    await dialog.getByText(/frequently posts unwanted content/i).click();

    await observerPage.waitForTimeout(1000);
    const closeButton = dialog.locator('[aria-label*="Close"], button').first();
    await closeButton.click().catch(() => {});
    await observerPage.waitForTimeout(2000);

    const ozoneContext = await browser.newContext({
      ...(process.env.CI && { recordVideo: { dir: testInfo.outputDir } }),
    });
    const ozonePage = await ozoneContext.newPage();

    await loginToOzone(ozonePage, "ozone.pds.eurosky.u-at-proto.work", "admin123");

    await waitForReportToAppear(ozonePage, creatorHandle);

    await performTakedown(ozonePage, "account");

    await observerPage.goto(`${BASE_URL}/profile/${creatorHandle}`);
    await observerPage.waitForTimeout(2000);

    await expect(
      observerPage.getByText(/account.*not found|account.*suspended|profile.*unavailable/i)
    ).toBeVisible();

    await creatorContext.close();
    await observerContext.close();
    await ozoneContext.close();
  });

});
