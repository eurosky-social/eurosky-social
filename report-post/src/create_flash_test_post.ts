#!/usr/bin/env node

import { createAuthenticatedAgent } from "./auth";

async function main(): Promise<void> {
  const useGtube = process.argv.includes('--gtube');
  
  const gtubeString = "XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X";
  const text = useGtube 
    ? `Test flash post with GTUBE string: ${gtubeString}`
    : "This is a test text-only flash post";

  const agent = await createAuthenticatedAgent();

  const response = await agent.com.atproto.repo.createRecord({
    repo: agent.session?.did!,
    collection: "app.flashes.feed.post",
    record: {
      $type: "app.flashes.feed.post",
      createdAt: new Date().toISOString(),
      text: text,
    },
  });

  console.log(`${response.data.uri} ${response.data.cid}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});