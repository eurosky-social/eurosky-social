import * as dotenv from "dotenv";
import { AtpAgent } from "@atproto/api";

dotenv.config();

function getRequiredEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export async function createAuthenticatedAgent(): Promise<AtpAgent> {
  const agent = new AtpAgent({
    service: getRequiredEnvVar("PDS_URL"),
  });

  await agent.login({
    identifier: getRequiredEnvVar("USERNAME"),
    password: getRequiredEnvVar("PASSWORD"),
  });

  return agent;
}

export async function createOzoneAgent(): Promise<AtpAgent> {
  const agent = await createAuthenticatedAgent();
  const labelerIdentity = await agent.resolveHandle({handle: "eurosky-ozone.bsky.social"});
  
  return agent.withProxy("atproto_labeler", labelerIdentity.data.did);
}