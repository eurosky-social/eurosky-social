#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { z } from "zod";
import { createAuthenticatedAgent } from "./auth";
import * as fs from "fs";
import AtpAgent from "@atproto/api";

const defaultText = "Test flashes story";

const ArgsSchema = z.object({
  text: z.string().optional(),
  image: z.string({
    required_error: "Image is required for flashes stories",
    invalid_type_error: "Image path must be a string",
  }),
});

async function main(): Promise<void> {
  const argv = await yargs(hideBin(process.argv))
    .option("text", {
      type: "string",
      description: "Custom text for the post (optional)",
    })
    .option("image", {
      type: "string",
      description: "Image filename to use (required)",
      demandOption: true,
    })
    .help()
    .parse();

  const validation = ArgsSchema.safeParse(argv);
  if (!validation.success) {
    console.error("Invalid arguments:");
    validation.error.issues.forEach((issue) => {
      console.error(`  ${issue.path.join(".")}: ${issue.message}`);
    });
    process.exit(1);
  }

  const args = validation.data;
  const agent = await createAuthenticatedAgent();

  const response = await agent.com.atproto.repo.createRecord({
    repo: agent.session?.did!,
    collection: "app.flashes.story",
    record: {
      $type: "app.flashes.story",
      createdAt: new Date().toISOString(),
      text: args.text ?? defaultText,
      embed: {
        $type: "app.flashes.story#image",
        images: [
          {
            image: (await uploadBlob(agent, args.image)).data.blob,
            alt: args.text ?? defaultText,
          },
        ],
      },
    },
  });

  console.log(JSON.stringify(response.data, null, 2));
}

function uploadBlob(agent: AtpAgent, imagePath: string) {
  const data = fs.readFileSync(imagePath);
  return agent.com.atproto.repo.uploadBlob(data, {
    encoding: imagePath.endsWith(".jpg") ? "image/jpeg" : "image/png",
  });
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
