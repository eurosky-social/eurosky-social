#!/usr/bin/env node

import { createOzoneAdminAgent } from "./auth";

async function main(): Promise<void> {
  const uri = process.argv[2];
  const showAll = process.argv.includes('--all');
  
  if (!uri && !showAll) {
    console.error("Usage:");
    console.error("  ts-node src/check_moderation_events.ts <post-uri>");
    console.error("  ts-node src/check_moderation_events.ts --all");
    console.error("");
    console.error("Examples:");
    console.error("  ts-node src/check_moderation_events.ts 'at://did:plc:xyz/app.flashes.feed.post/abc'");
    console.error("  ts-node src/check_moderation_events.ts --all");
    process.exit(1);
  }

  const agent = await createOzoneAdminAgent();

  if (showAll) {
    const response = await agent.api.tools.ozone.moderation.queryEvents({
      limit: 50,
      sortDirection: 'desc',
    });
    
    console.log(JSON.stringify(response.data.events, null, 2));

  } else {
    const response = await agent.api.tools.ozone.moderation.queryEvents({
      subject: uri,
      limit: 20,
      sortDirection: 'desc',
    });

    console.log(JSON.stringify(response.data.events, null, 2));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});