#!/usr/bin/env node

import { createOzoneAgent } from "./auth";

async function main(): Promise<void> {
  const uri = process.argv[2];
  const cid = process.argv[3];
  
  if (!uri || !cid) {
    console.error("Usage: ts-node src/report_flash_post.ts <uri> <cid>");
    console.error("Example: ts-node src/report_flash_post.ts 'at://did:plc:xyz/app.flashes.feed.post/abc' 'bafyrei...'");
    process.exit(1);
  }

  const agent = await createOzoneAgent();

  const response = await agent.createModerationReport({
    subject: {
      $type: "com.atproto.repo.strongRef",
      uri: uri,
      cid: cid,
    },
    reasonType: "com.atproto.moderation.defs#reasonSpam",
    reason: "Test report from script",
  });

  console.log(`Report ID: ${response.data.id}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});