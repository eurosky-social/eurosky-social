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

test.describe("Ozone Report Display", () => {
  test("create spam report and verify it appears in ozone console", async ({ page }) => {
    test.setTimeout(60000); // 1 minute for the entire test

    // Arrange - Create spammer and reporter users
    const spammer = await createTestUser(PDS_URL);
    const reporter = await createTestUser(PDS_URL);

    // Create a spam post from the spammer
    const postResult = await spammer.agent.app.bsky.feed.post.create(
      { repo: spammer.agent.session!.did },
      {
        text: "This is spam content",
        createdAt: new Date().toISOString(),
      }
    );

    // Reporter creates a spam report to Ozone
    const reporterOzoneAgent = reporter.agent.withProxy("atproto_labeler", OZONE_SERVER_DID);
    await reporterOzoneAgent.com.atproto.moderation.createReport({
      reasonType: ComAtprotoModerationDefs.REASONSPAM,
      subject: {
        $type: "com.atproto.repo.strongRef",
        uri: postResult.uri,
        cid: postResult.cid,
      },
      reason: "Spam content detected",
    });

    // Act - Login to Ozone UI as admin
    const { did, password } = getOzoneCreds();
    await loginToOzone(page, PDS_URL, did, password);

    // Wait for queue table to load
    await expect(page.getByRole("columnheader", { name: /subject/i })).toBeVisible();

    // Assert - Look for the spammer's handle in the queue
    const postLink = page.getByRole("link").filter({ hasText: new RegExp(spammer.agent.session!.handle, "i") }).first();
    await expect(postLink).toBeVisible();
  });
});
