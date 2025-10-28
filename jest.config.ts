import type { Config } from "jest";
import { createDefaultPreset } from "ts-jest";

const config: Config = {
  // [...]
  ...createDefaultPreset(),
  testEnvironment: "node",
  testMatch: ["<rootDir>/tests/**/*.test.[jt]s?(x)"],
  testPathIgnorePatterns: [
    "<rootDir>/node_modules/",
    "<rootDir>/tests/browser/",
  ],
  transformIgnorePatterns: [
    "<rootDir>/node_modules/(?!(?:@atproto|multiformats)/)",
  ],
};

export default config;
