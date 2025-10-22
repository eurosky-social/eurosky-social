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

  let reconnectAttempts = 0;
  const maxReconnectDelay = 30_000;
  const initialReconnectDelay = 1_000;
  let pingIntervalMs = 300 * 1000;

  function connect() {
    console.log('Subscribing to label stream...');
    console.log(`Connecting to: ${url}`);

    const ws = new WebSocket(url);
    let pingInterval: NodeJS.Timeout | null = null;
    let isAlive = true;

    ws.on('open', () => {
      console.log('Connected to label stream');
      reconnectAttempts = 0; // Reset on successful connection

      isAlive = true;
      pingInterval = setInterval(() => {
        if (!isAlive) {
          console.log('Ping timeout, terminating connection');
          ws.terminate();
          return;
        }

        isAlive = false;
        ws.ping();
      }, pingIntervalMs);
    });

    ws.on('pong', () => {
      isAlive = true;
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
      if (pingInterval) {
        clearInterval(pingInterval);
        pingInterval = null;
      }

      pingIntervalMs = 30_000;


      // Reconnect with exponential backoff
      const delay = Math.min(
        initialReconnectDelay * Math.pow(2, reconnectAttempts),
        maxReconnectDelay
      );
      reconnectAttempts++;

      console.log(`Reconnecting in ${delay}ms (attempt ${reconnectAttempts})...`);
      setTimeout(connect, delay);
    });
  }

  connect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
