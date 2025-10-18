import { defineConfig, devices } from "@playwright/test";
import "dotenv/config";

const DOMAIN = process.env.DOMAIN;
if (!DOMAIN) {
  throw new Error("DOMAIN env var is required");
}

const PARTITION = process.env.PARTITION;
if (!PARTITION) {
  throw new Error("PARTITION env var is required");
}

export default defineConfig({
  testDir: "./tests/browser",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["list"], ["html"]],
  timeout: 60_000,
  use: {
    baseURL: `https://ozone.${PARTITION}.${DOMAIN}`,
    trace: process.env.CI ? "on" : "on-first-retry",
    video: process.env.CI ? "on" : undefined,
    screenshot: "only-on-failure",
    actionTimeout: 2_000,
    navigationTimeout: 5_000,
  },

  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
