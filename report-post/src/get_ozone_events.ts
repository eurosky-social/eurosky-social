#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { z } from "zod";
import { createOzoneAdminAgent } from "./auth";

const IdSchema = z.number().int().positive();
const SubjectSchema = z.string().startsWith("at://");

const ArgsSchema = z.object({
  reports: z.boolean().optional(),
  id: IdSchema.optional(),
  subject: SubjectSchema.optional(),
}).refine(
  (data) => {
    // Only one of id, subject, or reports can be specified
    const specified = [data.id, data.subject, data.reports].filter(Boolean).length;
    return specified <= 1;
  },
  {
    message: "Only one of --id, --subject, or --reports can be specified"
  }
);

async function main(): Promise<void> {
  const argv = await yargs(hideBin(process.argv))
    .option('reports', {
      type: 'boolean',
      description: 'Get only report events'
    })
    .option('id', {
      type: 'number',
      description: 'Get specific event by ID'
    })
    .option('subject', {
      type: 'string',
      description: 'Get events for specific subject URI'
    })
    .help()
    .parse();

  // Validate arguments with Zod
  const validation = ArgsSchema.safeParse(argv);
  if (!validation.success) {
    console.error(JSON.stringify({ 
      error: "Invalid arguments",
      details: validation.error.format()
    }, null, 2));
    process.exit(1);
  }

  const args = validation.data;
  const agent = await createOzoneAdminAgent();

  if (args.id) {
    const response = await agent.api.tools.ozone.moderation.getEvent({ id: args.id });
    console.log(JSON.stringify(response.data, null, 2));
  } else {
    const response = await agent.api.tools.ozone.moderation.queryEvents({
      limit: 50,
      sortDirection: 'desc',
      ...args.reports && { types: ['tools.ozone.moderation.defs#modEventReport'] },
      ...args.subject && { subject: args.subject }
    });
    console.log(JSON.stringify(response.data.events, null, 2));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
