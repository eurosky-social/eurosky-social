#!/usr/bin/env node

import { createOzoneAdminAgent } from "./auth";

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  const agent = await createOzoneAdminAgent();

  // Parse arguments and build query
  let query: any = { limit: 50, sortDirection: "desc" };
  let useGetEvent = false;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === "--reports") {
      query.types = ["tools.ozone.moderation.defs#modEventReport"];
    } else if (arg === "--id") {
      const id = args[++i];
      if (!id || !id.match(/^\d+$/)) {
        console.error(
          JSON.stringify({ error: "Invalid or missing ID after --id" }, null, 2)
        );
        process.exit(1);
      }
      useGetEvent = true;
      query = { id: parseInt(id) };
      break; // --id is exclusive
    } else if (arg === "--subject") {
      const subject = args[++i];
      if (!subject) {
        console.error(
          JSON.stringify({ error: "Missing subject after --subject" }, null, 2)
        );
        process.exit(1);
      }
      query.subject = subject;
    } else {
      console.error(
        JSON.stringify({ error: `Unknown argument: ${arg}` }, null, 2)
      );
      process.exit(1);
    }
  }

  // Execute query
  if (useGetEvent) {
    const response = await agent.api.tools.ozone.moderation.getEvent(query);
    console.log(JSON.stringify(response.data, null, 2));
  } else {
    const response = await agent.api.tools.ozone.moderation.queryEvents(query);
    console.log(JSON.stringify(response.data.events, null, 2));
  }
}

main().catch((e) => {
  console.error(JSON.stringify({ error: e.message }, null, 2));
  process.exit(1);
});
