import { Page, expect } from "@playwright/test";

export async function navigateToReport(page: Page, searchTerm: string) {
  await page.keyboard.press("Control+K");
  await page.getByRole("textbox", { name: /search/i }).fill(searchTerm);
  await page.keyboard.press("Enter");
  await page.waitForTimeout(1000);
}

export async function performTakedown(page: Page, type: "post" | "account" = "post") {
  await page.getByRole("button", { name: /actions|take action/i }).click();

  if (type === "post") {
    await page.getByRole("menuitem", { name: /takedown.*post|remove.*post/i }).click();
  } else {
    await page.getByRole("menuitem", { name: /takedown.*account|suspend.*account/i }).click();
  }

  await page.getByRole("button", { name: /confirm|takedown/i }).click();

  await expect(page.getByText(/success|taken down/i)).toBeVisible({ timeout: 5000 });
  await page.waitForTimeout(2000);
}

export async function waitForReportToAppear(page: Page, reportText: string, timeout: number = 30000) {
  await page.waitForTimeout(3000);
  await page.reload();
  await page.waitForLoadState("networkidle");
  await expect(page.getByText(reportText, { exact: false })).toBeVisible({ timeout });
}
