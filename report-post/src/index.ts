#!/usr/bin/env node

import * as dotenv from "dotenv";
import { reportPost, ReportConfig } from "./reportPost";

dotenv.config();

function getRequiredEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function main(): Promise<void> {
  const config: ReportConfig = {
    pdsUrl: getRequiredEnvVar("PDS_URL"),
    username: getRequiredEnvVar("USERNAME"),
    password: getRequiredEnvVar("PASSWORD"),
  };

  const response = await reportPost(config);
  console.log("Report created:", response);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
