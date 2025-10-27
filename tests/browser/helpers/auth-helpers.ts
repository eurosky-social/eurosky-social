import { Page, expect } from "@playwright/test";

export const DOMAIN = process.env.DOMAIN || "eurosky.work";
export const PARTITION = process.env.PARTITION || "local";
export const BASE_URL = `https://social.${PARTITION}.${DOMAIN}`;
export const PDS_URL = `pds.${PARTITION}.${DOMAIN}`;
export const OZONE_URL = `https://ozone.${PARTITION}.${DOMAIN}`;
export const OZONE_DID = `did:web:ozone.${PARTITION}.${DOMAIN}`;

export function uniqueId() {
  return (Date.now() % 1000000).toString() + Math.floor(Math.random() * 1000).toString().padStart(3, '0');
}

export async function signUp(page: Page, name: string, pdsUrl: string) {
  await page.getByRole("button", { name: "Close welcome modal" }).click();
  await page.getByRole("button", { name: "Create account" }).first().click();

  await page.getByRole("button", { name: "Bluesky Social" }).click();
  await page.getByRole("radio", { name: "Custom" }).click();

  await page.getByRole("textbox", { name: "Server address" }).fill(pdsUrl);
  await page.getByRole("button", { name: "Done" }).click();

  const email = `${name}@test.com`;
  const password = "TestPassword123!";
  await page.getByRole("textbox", { name: /enter.*email/i }).fill(email);
  await page.getByRole("textbox", { name: /choose.*password/i }).fill(password);
  await page.getByRole("button", { name: "Next" }).click();

  await page
    .getByRole("textbox", { name: new RegExp(`\\.${pdsUrl}`) })
    .fill(name);
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
}

export async function loginToOzone(page: Page, username: string, password: string) {
  await page.goto(OZONE_URL);

  const serviceField = page.getByLabel(/service/i);
  await serviceField.waitFor({ state: "visible", timeout: 5000 });
  await serviceField.clear();
  await serviceField.fill(`https://${PDS_URL}`);

  await page.getByLabel(/account.*handle/i).fill(username);
  await page.getByLabel(/password/i).fill(password);
  await page.getByRole("button", { name: /sign in/i }).click();

  await expect(page.getByText(/reports|moderation/i).first()).toBeVisible({
    timeout: 10000,
  });
}
