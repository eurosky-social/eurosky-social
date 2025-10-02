#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { z } from "zod";
import { WebSocket } from "ws";
import * as dotenv from "dotenv";
import { cborDecodeMulti } from "@atproto/common";

dotenv.config();

const ArgsSchema = z.object({
  cursor: z.number().int().nonnegative().optional(),
});

async function main(): Promise<void> {
  const argv = await yargs(hideBin(process.argv))
    .option('cursor', {
      type: 'number',
      description: 'Cursor position to start from',
      default: 0
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
  const ozoneUrl = process.env.OZONE_SERVICE_URL;
  if (!ozoneUrl) {
    throw new Error("Missing required environment variable: OZONE_SERVICE_URL");
  }

  const wsUrl = ozoneUrl.replace(/^https?:/, 'wss:');
  const url = `${wsUrl}/xrpc/com.atproto.label.subscribeLabels?cursor=${args.cursor ?? 0}`;

  console.log('Subscribing to label stream...');
  console.log(`Connecting to: ${url}`);

  const ws = new WebSocket(url);

  ws.on('open', () => {
    console.log('Connected to label stream');
  });

  ws.on('message', (data: Buffer) => {
    try {
      const [header, body] = cborDecodeMulti(new Uint8Array(data));
      console.log(JSON.stringify({ header, body }, null, 2));
    } catch (e) {
      console.error('Failed to decode message:', e);
    }
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });

  ws.on('close', () => {
    console.log('Connection closed');
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
