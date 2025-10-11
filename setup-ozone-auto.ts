#!/usr/bin/env tsx
import { AtpAgent } from "@atproto/api";
import * as dotenv from "dotenv";

dotenv.config();

function getEnv(key: string) {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Environment variable ${key} is not set`);
  }
  return value;
}

const PDS_DOMAIN = getEnv("PDS_DOMAIN");
const PLC_DOMAIN = getEnv("PLC_DOMAIN");
const OZONE_ADMIN_PASSWORD = getEnv("OZONE_ADMIN_PASSWORD");
const OZONE_DOMAIN = getEnv("OZONE_DOMAIN");
const MAILDEV_URL = getEnv("MAILDEV_URL");
const OZONE_PUBLIC_KEY = getEnv("OZONE_PUBLIC_KEY");
const EMAIL_DOMAIN = getEnv("EMAIL_DOMAIN");

// Derived constants
const PDS_URL = `https://${PDS_DOMAIN}`;
const OZONE_URL = `https://${OZONE_DOMAIN}`;
const OZONE_HANDLE = `ozone.${PDS_DOMAIN}`;
const OZONE_EMAIL = `ozone@${EMAIL_DOMAIN}`;

// Magic numbers
const PLC_OPERATION_DELAY_MS = 5000;


async function getLatestEmailCode(): Promise<string> {
  const response = await fetch(`${MAILDEV_URL}/email`);
  const emails = await response.json();
  if (!emails || emails.length === 0) {
    throw new Error("No emails found in maildev");
  }

  const latestEmail = emails[emails.length - 1];
  const emailResponse = await fetch(`${MAILDEV_URL}/email/${latestEmail.id}`);
  const email = await emailResponse.json();
  const codeMatch = email.html.match(/([A-Z0-9]{5}-[A-Z0-9]{5})/);

  if (!codeMatch) {
    throw new Error("Could not find confirmation code in email");
  }

  return codeMatch[1];
}

async function setupOzoneAuto() {
  console.log("Setting up Ozone labeler...");

  const agent = new AtpAgent({ service: PDS_URL });
  console.log(`Checking if account ${OZONE_HANDLE} exists...`);

  let accountExists = false;
  try {
    const resolveResponse = await agent.resolveHandle({ handle: OZONE_HANDLE });
    console.log(`✅ Account already exists with DID: ${resolveResponse.data.did}`);
    accountExists = true;
  } catch (error) {
    console.log("Account doesn't exist, creating new Ozone admin account...");
  }

  if (!accountExists) {
    try {
      const createResponse = await agent.com.atproto.server.createAccount({
        email: OZONE_EMAIL,
        handle: OZONE_HANDLE,
        password: OZONE_ADMIN_PASSWORD,
      });
      console.log(`✅ Created Ozone admin with DID: ${createResponse.data.did}`);
    } catch (createError: any) {
      console.error("❌ Failed to create account:", createError);
      throw createError;
    }
  }

  console.log("Logging in...");
  await agent.login({
    identifier: OZONE_HANDLE,
    password: OZONE_ADMIN_PASSWORD,
  });

  try {
    await agent.app.bsky.actor.profile.create(
      { repo: agent.session!.did },
      {
        displayName: "Ozone Moderator",
        description: "Automated moderation service",
        createdAt: new Date().toISOString(),
      }
    );
    console.log("✅ Created profile record");
  } catch (error: any) {
    const errorMsg = error.message || "";
    if (errorMsg.includes("already exists") ||
        errorMsg.includes("already a value at key") ||
        error.status === 500) {
      console.log("✅ Profile record already exists");
    } else {
      console.error("❌ Failed to create profile record:", errorMsg);
      throw error;
    }
  }

  await agent.com.atproto.identity.requestPlcOperationSignature();
  await new Promise(resolve => setTimeout(resolve, PLC_OPERATION_DELAY_MS));
  const token = await getLatestEmailCode();

  const plcLogResponse = await fetch(`https://${PLC_DOMAIN}/${agent.session!.did}/log`);
  const plcLog = await plcLogResponse.json();
  const lastOp = plcLog[plcLog.length - 1];
  const existingVerificationMethods: Record<string, string> = lastOp.verificationMethods || {};
  const existingRotationKeys = lastOp.rotationKeys || [];

  const { data: signed } = await agent.com.atproto.identity.signPlcOperation({
    token,
    rotationKeys: existingRotationKeys,
    services: {
      atproto_pds: {
        type: "AtprotoPersonalDataServer",
        endpoint: PDS_URL,
      },
      atproto_labeler: {
        type: "AtprotoLabeler",
        endpoint: OZONE_URL,
      },
    },
    verificationMethods: {
      ...existingVerificationMethods,
      atproto_label: OZONE_PUBLIC_KEY,
    },
  });

  try {
    await agent.com.atproto.identity.submitPlcOperation({
      operation: signed.operation,
    });
  } catch (error: any) {
    console.error("❌ Failed to submit PLC operation:", error.message);
    console.error("Signed operation:", JSON.stringify(signed.operation, null, 2));
    throw error;
  }

  console.log("Updating handle...");
  await agent.com.atproto.identity.updateHandle({
    handle: OZONE_HANDLE,
  });
  console.log("✅ Handle updated");

  console.log("Creating labeler service record...");
  try {
    await agent.app.bsky.labeler.service.create(
      { repo: agent.session!.did },
      {
        policies: {
          labelValues: ["spam"],
          labelValueDefinitions: [
            {
              identifier: "spam",
              severity: "inform",
              blurs: "content",
              defaultSetting: "warn",
              adultOnly: false,
              locales: [
                {
                  lang: "en",
                  name: "Spam",
                  description: "Applied to content that is unsolicited, repetitive, or promotional in nature.",
                }
              ]
            }
          ],
        },
        createdAt: new Date().toISOString(),
      }
    );
    console.log("✅ Labeler service record created");
  } catch (error: any) {
    const errorMsg = error.message || "";
    const errorStr = JSON.stringify(error);

    if (errorMsg.includes("already exists") ||
        errorMsg.includes("RecordAlreadyExists") ||
        errorMsg.includes("already a value at key") ||
        errorStr.includes("already exists") ||
        errorStr.includes("already a value at key") ||
        error.status === 500) {
      console.log("✅ Labeler service record already exists");
    } else {
      console.error("❌ Failed to create labeler service record:", errorMsg);
      console.error("Full error:", errorStr);
      throw error;
    }
  }

  const fs = await import('fs');
  const didFile = '/data/ozone-admin-did.txt';
  fs.writeFileSync(didFile, agent.session!.did);

  const hostDidFile = '/host-data/ozone-admin-did.txt';
  try {
    fs.mkdirSync('/host-data', { recursive: true });
    fs.writeFileSync(hostDidFile, agent.session!.did);
  } catch (err) {
    console.warn("Could not write to host-data:", err);
  }

  console.log("✅ Ozone setup complete!");
  console.log(`   Admin DID: ${agent.session!.did}`);
  console.log(`   Login at: ${OZONE_URL}`);
}

setupOzoneAuto().catch((error) => {
  console.error("\n❌ Error:", error.message);
  process.exit(1);
});
