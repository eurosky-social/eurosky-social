import { test, expect } from "@playwright/test";
import { BASE_URL, OZONE_URL } from "./helpers/auth-helpers";

test.describe("Connectivity Tests", () => {
  test("can reach Social app", async ({ page }) => {
    await page.goto(BASE_URL, { timeout: 30000 });
    const title = await page.title();
    expect(title).toBeTruthy();
  });

  test("can reach Ozone", async ({ page }) => {
    await page.goto(OZONE_URL, { timeout: 30000 });
    const title = await page.title();
    expect(title).toBeTruthy();
  });
});
