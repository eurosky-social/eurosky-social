#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { z } from "zod";
import { createOzoneAgent } from "./auth";

// Zod schemas for validation
const UriSchema = z.string().startsWith("at://");
const CidSchema = z.string().startsWith("bafy");
const ReasonTypeSchema = z.enum([
  "com.atproto.moderation.defs#reasonSpam",
  "com.atproto.moderation.defs#reasonViolation",
  "com.atproto.moderation.defs#reasonMisleading",
  "com.atproto.moderation.defs#reasonSexual",
  "com.atproto.moderation.defs#reasonRude",
  "com.atproto.moderation.defs#reasonOther",
]);

const ArgsSchema = z.object({
  uri: UriSchema,
  cid: CidSchema,
  reasonType: ReasonTypeSchema,
  reason: z.string().optional(),
});

async function main(): Promise<void> {
  const argv = await yargs(hideBin(process.argv))
    .positional("uri", {
      describe: "AT URI of the post to report",
      type: "string",
    })
    .positional("cid", {
      describe: "CID of the post to report",
      type: "string",
    })
    .option("reasonType", {
      type: "string",
      description: "Reason type for the report",
      choices: [
        "com.atproto.moderation.defs#reasonSpam",
        "com.atproto.moderation.defs#reasonViolation",
        "com.atproto.moderation.defs#reasonMisleading",
        "com.atproto.moderation.defs#reasonSexual",
        "com.atproto.moderation.defs#reasonRude",
        "com.atproto.moderation.defs#reasonOther",
      ],
      default: "com.atproto.moderation.defs#reasonSpam",
    })
    .option("reason", {
      type: "string",
      description: "Additional details for the report",
      default: "Test report from script",
    })
    .demandCommand(2, 2, "You must specify both URI and CID")
    .help()
    .parse();

  // Validate arguments with Zod
  const validation = ArgsSchema.safeParse({
    uri: argv._[0],
    cid: argv._[1],
    reasonType: argv.reasonType,
    reason: argv.reason,
  });

  if (!validation.success) {
    console.error("Invalid arguments:");
    validation.error.issues.forEach((issue) => {
      console.error(`  ${issue.path.join(".")}: ${issue.message}`);
    });
    process.exit(1);
  }

  const args = validation.data;
  const agent = await createOzoneAgent();

  const response = await agent.createModerationReport({
    subject: {
      $type: "com.atproto.repo.strongRef",
      uri: args.uri,
      cid: args.cid,
    },
    reasonType: args.reasonType,
    reason: args.reason,
  });
  console.log(JSON.stringify(response.data, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
