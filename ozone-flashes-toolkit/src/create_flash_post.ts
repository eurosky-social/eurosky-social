#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { z } from "zod";
import { createAuthenticatedAgent } from "./auth";
import * as fs from "fs";
import AtpAgent from "@atproto/api";

const gtubeString =
  "XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X";
const imageText = "Some test image";

const ArgsSchema = z
  .object({
    gtube: z.boolean().optional(),
    text: z.string().optional(),
    image: z.string().optional(),
  })
  .refine(
    (data) => {
      // Only one of gtube, text, or image can be specified
      const specified = [data.gtube, data.text, data.image].filter(
        Boolean
      ).length;
      return specified <= 1;
    },
    {
      message: "Only one of --gtube, --text, or --image can be specified",
    }
  );

async function main(): Promise<void> {
  const argv = await yargs(hideBin(process.argv))
    .option("gtube", {
      type: "boolean",
      description: "Include GTUBE test string for spam detection testing",
    })
    .option("text", {
      type: "string",
      description: "Custom text for the post",
    })
    .option("image", {
      type: "string",
      description: "Image filename to use",
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
    collection: "app.flashes.feed.post",
    record: {
      $type: "app.flashes.feed.post",
      createdAt: new Date().toISOString(),
      text: args.text ?? args.gtube ? gtubeString : imageText,
      embed: args.image
        ? {
            $type: "app.flashes.feed.post#embedImages",
            images: [
              {
                image: (await uploadBlob(agent, args.image)).data.blob,
                alt: imageText,
              },
            ],
          }
        : undefined,
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
