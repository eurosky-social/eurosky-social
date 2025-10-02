#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { z } from "zod";
import { createUnauthenticatedOzoneAgent } from "./auth";

const ArgsSchema = z.object({
  uriPatterns: z.array(z.string()),
  sources: z.array(z.string()).optional(),
  limit: z.number().int().positive().optional(),
});

async function main(): Promise<void> {
  const argv = await yargs(hideBin(process.argv))
    .option('uriPatterns', {
      type: 'array',
      description: 'URI patterns to query (e.g., "*" for all)',
      default: ['*']
    })
    .option('sources', {
      type: 'array',
      description: 'Label sources to filter by'
    })
    .option('limit', {
      type: 'number',
      description: 'Maximum number of labels to return'
    })
    .help()
    .parse();

  const validation = ArgsSchema.safeParse(argv);
  if (!validation.success) {
    console.error("Invalid arguments:");
    validation.error.issues.forEach(issue => {
      console.error(`  ${issue.path.join('.')}: ${issue.message}`);
    });
    process.exit(1);
  }

  const args = validation.data;
  const agent = await createUnauthenticatedOzoneAgent();

  const response = await agent.api.com.atproto.label.queryLabels({
    uriPatterns: args.uriPatterns,
    ...args.sources && { sources: args.sources },
    ...args.limit && { limit: args.limit }
  });

  console.log(JSON.stringify(response.data, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
