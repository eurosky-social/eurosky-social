#!/usr/bin/env tsx
import { AtpAgent } from "@atproto/api";
import { Command } from "commander";
import * as dotenv from "dotenv";

dotenv.config();

// Types
interface Config {
  pdsUrl: string;
  plcUrl: string;
  ozoneUrl: string;
  handle: string;
  email: string;
  password: string;
  publicKey: string;
}

interface PlcOperation {
  verificationMethods?: Record<string, string>;
  rotationKeys?: string[];
}

// Constants
const ALREADY_EXISTS_PATTERNS = [
  "already exists",
  "RecordAlreadyExists",
  "already a value at key",
  "Handle already taken",
];

const PLC_OPERATION_DELAY_MS = 5000;

// Helper functions
function isAlreadyExistsError(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;

  const err = error as { message?: string; status?: number };
  const errorMsg = err.message || "";
  const errorStr = JSON.stringify(error);

  const hasExistsPattern = ALREADY_EXISTS_PATTERNS.some(
    pattern => errorMsg.includes(pattern) || errorStr.includes(pattern)
  );

  return hasExistsPattern || err.status === 500;
}

function loadConfig(options: any): Config {
  return {
    pdsUrl: options.pdsUrl || process.env.PDS_URL || "",
    plcUrl: options.plcUrl || process.env.PLC_URL || "",
    ozoneUrl: options.ozoneUrl || process.env.OZONE_URL || "",
    handle: options.handle || process.env.OZONE_HANDLE || "",
    email: options.email || process.env.OZONE_EMAIL || "",
    password: options.password || process.env.OZONE_ADMIN_PASSWORD || "",
    publicKey: options.publicKey || process.env.OZONE_PUBLIC_KEY || "",
  };
}

function validateConfig(config: Config, required: (keyof Config)[]): void {
  const missing = required.filter(key => !config[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required configuration: ${missing.join(", ")}`);
  }
}

// Core functions
async function createAccount(agent: AtpAgent, config: Config): Promise<void> {
  const createResponse = await agent.com.atproto.server.createAccount({
    email: config.email,
    handle: config.handle,
    password: config.password,
  });
  console.log(`✅ Created Ozone admin with DID: ${createResponse.data.did}`);
}

async function login(agent: AtpAgent, config: Config): Promise<void> {
  console.log("Logging in...");
  await agent.login({
    identifier: config.handle,
    password: config.password,
  });
}

async function createProfile(agent: AtpAgent): Promise<void> {
  await agent.app.bsky.actor.profile.create(
    { repo: agent.session!.did },
    {
      displayName: "Ozone Moderator",
      description: "Automated moderation service",
      createdAt: new Date().toISOString(),
    }
  );
  console.log("✅ Created profile record");
}

async function requestPlcSignature(agent: AtpAgent): Promise<void> {
  await agent.com.atproto.identity.requestPlcOperationSignature();
}

async function fetchPlcLog(plcUrl: string, did: string): Promise<PlcOperation> {
  const plcLogResponse = await fetch(`${plcUrl}/${did}/log`);
  const plcLog = await plcLogResponse.json();
  return plcLog[plcLog.length - 1];
}

async function signPlcOperation(
  agent: AtpAgent,
  config: Config,
  token: string,
  lastOp: PlcOperation
) {
  const existingVerificationMethods: Record<string, string> = lastOp.verificationMethods || {};
  const existingRotationKeys = lastOp.rotationKeys || [];

  const { data: signed } = await agent.com.atproto.identity.signPlcOperation({
    token,
    rotationKeys: existingRotationKeys,
    services: {
      atproto_pds: {
        type: "AtprotoPersonalDataServer",
        endpoint: config.pdsUrl,
      },
      atproto_labeler: {
        type: "AtprotoLabeler",
        endpoint: config.ozoneUrl,
      },
    },
    verificationMethods: {
      ...existingVerificationMethods,
      atproto_label: config.publicKey,
    },
  });

  return signed;
}

async function submitPlcOperation(agent: AtpAgent, operation: { [_ in string]: unknown }): Promise<void> {
  try {
    await agent.com.atproto.identity.submitPlcOperation({ operation });
  } catch (error: unknown) {
    const err = error as { message?: string };
    console.error("❌ Failed to submit PLC operation:", err.message || "Unknown error");
    console.error("Signed operation:", JSON.stringify(operation, null, 2));
    throw error;
  }
}

async function updatePlcDocument(agent: AtpAgent, config: Config, token: string): Promise<void> {
  const lastOp = await fetchPlcLog(config.plcUrl, agent.session!.did);
  const signed = await signPlcOperation(agent, config, token, lastOp);
  await submitPlcOperation(agent, signed.operation);
}

async function updateHandle(agent: AtpAgent, config: Config): Promise<void> {
  console.log("Updating handle...");
  await agent.com.atproto.identity.updateHandle({
    handle: config.handle,
  });
  console.log("✅ Handle updated");
}

async function createLabelerService(agent: AtpAgent): Promise<void> {
  console.log("Creating labeler service record...");
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
}

// Command implementations
async function initCommand(options: any) {
  const config = loadConfig(options);
  validateConfig(config, ["pdsUrl", "handle", "email", "password"]);

  console.log("🚀 Initializing Ozone labeler account...");
  const agent = new AtpAgent({ service: config.pdsUrl });

  try {
    await createAccount(agent, config);
  } catch (error: unknown) {
    if (isAlreadyExistsError(error)) {
      console.log("✅ Account already exists");
    } else {
      throw error;
    }
  }

  await login(agent, config);

  try {
    await createProfile(agent);
  } catch (error: unknown) {
    if (isAlreadyExistsError(error)) {
      console.log("✅ Profile record already exists");
    } else {
      throw error;
    }
  }

  console.log("\n✅ Initialization complete!");
  console.log(`   DID: ${agent.session!.did}`);
  console.log(`   Handle: ${config.handle}`);
  console.log("\nNext steps:");
  console.log(`   1. Run: setup-ozone plc-request --handle ${config.handle} --password <password>`);
  console.log(`   2. Check your email (${config.email}) for the PLC token`);
  console.log(`   3. Run: setup-ozone plc-complete --token <TOKEN> --handle ${config.handle} --password <password>`);
}

async function plcRequestCommand(options: any) {
  const config = loadConfig(options);
  validateConfig(config, ["pdsUrl", "handle", "password"]);

  console.log("📧 Requesting PLC signature...");
  const agent = new AtpAgent({ service: config.pdsUrl });

  await login(agent, config);
  await requestPlcSignature(agent);

  console.log("\n✅ PLC signature request sent!");
  console.log(`   Check your email (${config.email || 'configured email'}) for the confirmation token`);
  console.log("\nNext step:");
  console.log(`   Run: setup-ozone plc-complete --token <TOKEN> --handle ${config.handle} --password <password>`);
}

async function plcCompleteCommand(token: string, options: any) {
  const config = loadConfig(options);
  validateConfig(config, ["pdsUrl", "plcUrl", "ozoneUrl", "handle", "password", "publicKey"]);

  console.log("🔐 Completing PLC configuration...");
  const agent = new AtpAgent({ service: config.pdsUrl });

  await login(agent, config);
  await updatePlcDocument(agent, config, token);
  await updateHandle(agent, config);

  console.log("\n✅ PLC configuration complete!");
  console.log(`   DID: ${agent.session!.did}`);
  console.log("\nNext step:");
  console.log(`   Run: setup-ozone labeler --handle ${config.handle} --password <password>`);
}

async function labelerCommand(options: any) {
  const config = loadConfig(options);
  validateConfig(config, ["pdsUrl", "handle", "password"]);

  console.log("🏷️  Creating labeler service...");
  const agent = new AtpAgent({ service: config.pdsUrl });

  await login(agent, config);

  try {
    await createLabelerService(agent);
  } catch (error: unknown) {
    if (isAlreadyExistsError(error)) {
      console.log("✅ Labeler service record already exists");
    } else {
      throw error;
    }
  }

  console.log("\n✅ Ozone labeler setup complete!");
  console.log(`   Admin DID: ${agent.session!.did}`);
  console.log(`   Login at: ${config.ozoneUrl}`);
}

async function fullAutoCommand(options: any) {
  const config = loadConfig(options);
  const maildevUrl = options.maildevUrl || process.env.MAILDEV_URL;

  if (!maildevUrl) {
    throw new Error("--maildev-url or MAILDEV_URL required for full-auto mode");
  }

  validateConfig(config, ["pdsUrl", "plcUrl", "ozoneUrl", "handle", "email", "password", "publicKey"]);

  console.log("🚀 Running full automated setup (test environment only)...");
  const agent = new AtpAgent({ service: config.pdsUrl });

  try {
    await createAccount(agent, config);
  } catch (error: unknown) {
    if (isAlreadyExistsError(error)) {
      console.log("✅ Account already exists");
    } else {
      throw error;
    }
  }

  await login(agent, config);

  try {
    await createProfile(agent);
  } catch (error: unknown) {
    if (isAlreadyExistsError(error)) {
      console.log("✅ Profile record already exists");
    } else {
      throw error;
    }
  }

  await requestPlcSignature(agent);
  console.log("⏳ Waiting for email...");
  await new Promise(resolve => setTimeout(resolve, PLC_OPERATION_DELAY_MS));

  const token = await getLatestEmailCode(maildevUrl);
  await updatePlcDocument(agent, config, token);
  await updateHandle(agent, config);

  try {
    await createLabelerService(agent);
  } catch (error: unknown) {
    if (isAlreadyExistsError(error)) {
      console.log("✅ Labeler service record already exists");
    } else {
      throw error;
    }
  }

  console.log("\n✅ Full automated setup complete!");
  console.log(`   Admin DID: ${agent.session!.did}`);
  console.log(`   Login at: ${config.ozoneUrl}`);
}

async function getLatestEmailCode(maildevUrl: string): Promise<string> {
  const response = await fetch(`${maildevUrl}/email`);
  const emails = await response.json();
  if (!emails || emails.length === 0) {
    throw new Error("No emails found in maildev");
  }

  const latestEmail = emails[emails.length - 1];
  const emailResponse = await fetch(`${maildevUrl}/email/${latestEmail.id}`);
  const email = await emailResponse.json();
  const codeMatch = email.html.match(/([A-Z0-9]{5}-[A-Z0-9]{5})/);

  if (!codeMatch) {
    throw new Error("Could not find confirmation code in email");
  }

  return codeMatch[1];
}

// CLI setup
const program = new Command();

program
  .name("setup-ozone")
  .description("CLI tool for setting up Ozone labeler accounts")
  .version("1.0.0");

program
  .command("init")
  .description("Create Ozone account and profile (Step 1)")
  .option("--pds-url <url>", "PDS URL")
  .option("--handle <handle>", "Ozone handle")
  .option("--email <email>", "Ozone email")
  .option("--password <password>", "Admin password")
  .action(async (options) => {
    try {
      await initCommand(options);
    } catch (error: any) {
      console.error("\n❌ Error:", error.message);
      process.exit(1);
    }
  });

program
  .command("plc-request")
  .description("Request PLC signature token (Step 2)")
  .option("--pds-url <url>", "PDS URL")
  .option("--handle <handle>", "Ozone handle")
  .option("--password <password>", "Admin password")
  .option("--email <email>", "Ozone email (for display only)")
  .action(async (options) => {
    try {
      await plcRequestCommand(options);
    } catch (error: any) {
      console.error("\n❌ Error:", error.message);
      process.exit(1);
    }
  });

program
  .command("plc-complete")
  .description("Complete PLC configuration with email token (Step 3)")
  .argument("<token>", "PLC confirmation token from email")
  .option("--pds-url <url>", "PDS URL")
  .option("--plc-url <url>", "PLC directory URL")
  .option("--ozone-url <url>", "Ozone URL")
  .option("--handle <handle>", "Ozone handle")
  .option("--password <password>", "Admin password")
  .option("--public-key <key>", "Ozone public signing key")
  .action(async (token, options) => {
    try {
      await plcCompleteCommand(token, options);
    } catch (error: any) {
      console.error("\n❌ Error:", error.message);
      process.exit(1);
    }
  });

program
  .command("labeler")
  .description("Create labeler service record (Step 4)")
  .option("--pds-url <url>", "PDS URL")
  .option("--ozone-url <url>", "Ozone URL")
  .option("--handle <handle>", "Ozone handle")
  .option("--password <password>", "Admin password")
  .action(async (options) => {
    try {
      await labelerCommand(options);
    } catch (error: any) {
      console.error("\n❌ Error:", error.message);
      process.exit(1);
    }
  });

program
  .command("full-auto")
  .description("Full automated setup (test environment only - requires MailDev)")
  .option("--pds-url <url>", "PDS URL")
  .option("--plc-url <url>", "PLC directory URL")
  .option("--ozone-url <url>", "Ozone URL")
  .option("--handle <handle>", "Ozone handle")
  .option("--email <email>", "Ozone email")
  .option("--password <password>", "Admin password")
  .option("--public-key <key>", "Ozone public signing key")
  .option("--maildev-url <url>", "MailDev URL (test only)")
  .action(async (options) => {
    try {
      await fullAutoCommand(options);
    } catch (error: any) {
      console.error("\n❌ Error:", error.message);
      process.exit(1);
    }
  });

program.parse();
