#!/usr/bin/env ts-node

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { z } from "zod";
import * as https from "https";
import * as http from "http";
import * as crypto from "crypto";
import { createAuthenticatedAgent } from "./auth";

const ArgsSchema = z.object({
  did: z.string().startsWith("did:plc:"),
  rkey: z.string().min(1),
});

const ValueSchema = z.object({
  embed: z.object({
    images: z.array(
      z.object({
        image: z.object({
          ref: z.object({
            $link: z.string(),
          }),
        }),
      })
    ),
  }),
});

async function main() {
  const argv = await yargs(hideBin(process.argv))
    .usage("Usage: $0 --did <did> --rkey <rkey>")
    .option("did", {
      type: "string",
      demandOption: true,
      describe: "DID of the user",
    })
    .option("rkey", {
      type: "string",
      demandOption: true,
      describe: "Record key (rkey)",
    })
    .help()
    .parse();

  const parsed = ArgsSchema.safeParse(argv);
  if (!parsed.success) {
    console.error("Invalid arguments:");
    parsed.error.issues.forEach((issue) => {
      console.error(`  ${issue.path.join(".")}: ${issue.message}`);
    });
    process.exit(1);
  }
  const { did, rkey } = parsed.data;

  const agent = await createAuthenticatedAgent();
  const res = await agent.com.atproto.repo.getRecord({
    repo: did,
    collection: "app.flashes.feed.post",
    rkey,
  });

  const value = JSON.stringify(res.data.value, null, 2);
  console.log("\n=== Flash Post Record ===\n", value);

  const parsedValue = ValueSchema.safeParse(JSON.parse(value));
  if (!parsedValue.success) {
    console.error("\n[ERROR] Value payload does not match expected schema:");
    parsedValue.error.issues.forEach((issue) => {
      console.error(`  ${issue.path.join(".")}: ${issue.message}`);
    });
    process.exit(2);
  }
  // Extract blob CID from validated value
  const images = parsedValue.data.embed.images;
  if (images.length === 0) {
    console.error(
      "\n[ERROR] No images found in embed.\nEmbed structure:",
      JSON.stringify(parsedValue.data.embed, null, 2)
    );
    process.exit(2);
  }

  const cid = images[0].image.ref["$link"];
  if (!cid) {
    console.error(
      "\n[ERROR] Could not extract blob CID from embed.\nEmbed structure:",
      JSON.stringify(parsedValue.data.embed, null, 2)
    );
    process.exit(2);
  }

  const pdsUrl = process.env.PDS_URL || "https://bsky.social";
  const blobUrl = `${pdsUrl}/xrpc/com.atproto.sync.getBlob?did=${did}&cid=${cid}`;
  console.log(`\nFetching blob from: ${blobUrl}`);

  await fetchAndHash(blobUrl);
}

function fetchAndHash(url: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const fetch = url.startsWith("https") ? https.get : http.get;
    fetch(url, (resp) => {
      if (resp.statusCode === 302 && resp.headers.location) {
        console.log(`Redirected to: ${resp.headers.location}`);
        resp.resume();
        fetchAndHash(resp.headers.location).then(resolve, reject);
        return;
      }
      if (resp.statusCode !== 200) {
        console.error(
          `[ERROR] Failed to fetch blob: status ${resp.statusCode}`
        );
        resp.resume();
        reject(new Error(`Failed to fetch blob: status ${resp.statusCode}`));
        return;
      }
      const hash = crypto.createHash("sha256");
      resp.on("data", (chunk) => hash.update(chunk));
      resp.on("end", () => {
        const digest = hash.digest("hex");
        console.log(`SHA256 of blob: ${digest}`);
        resolve();
      });
    }).on("error", (e) => {
      console.error(`[ERROR] Error fetching blob: ${e.message}`);
      reject(e);
    });
  });
}

main().catch((e) => {
  console.error("[FATAL]", e);
  process.exit(1);
});
