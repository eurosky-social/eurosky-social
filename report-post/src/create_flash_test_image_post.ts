#!/usr/bin/env node

import { createAuthenticatedAgent } from "./auth";
import * as fs from "fs";
import * as path from "path";

async function main(): Promise<void> {
  const imageName = process.argv[2];
  if (!imageName) {
    console.error("Usage: ts-node src/create_flash_test_image_post.ts <image-filename>");
    console.error("Available images: dog.jpg, kids.jpg");
    process.exit(1);
  }

  const agent = await createAuthenticatedAgent();

  // Load image from the current directory
  const imagePath = path.join(__dirname, "..", imageName);
  const imageData = fs.readFileSync(imagePath);

  // Upload the blob
  const blobResponse = await agent.com.atproto.repo.uploadBlob(imageData, {
    encoding: imageName.endsWith('.jpg') ? 'image/jpeg' : 'image/png',
  });

  // Create flash post with image embed
  const response = await agent.com.atproto.repo.createRecord({
    repo: agent.session?.did!,
    collection: "app.flashes.feed.post", 
    record: {
      $type: "app.flashes.feed.post",
      createdAt: new Date().toISOString(),
      text: `Test flash post with ${imageName}`,
      embed: {
        $type: "app.flashes.feed.post#embedImages",
        images: [
          {
            image: blobResponse.data.blob,
            alt: `Test image: ${imageName}`,
          },
        ],
      },
    },
  });

  console.log(`${response.data.uri} ${response.data.cid}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});