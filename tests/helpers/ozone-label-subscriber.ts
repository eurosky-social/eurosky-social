import { WebSocket } from "ws";
import { cborDecodeMulti } from "@atproto/common";
import { EventBuffer } from "./wait-helpers";

export interface Label {
  uri: string;
  val: string;
  src: string;
  cid?: string;
  cts?: string;
  sig?: any;
  ver?: number;
}

export class OzoneLabelSubscriber {
  private ws: WebSocket | null = null;
  private labelBuffer = new EventBuffer<Label>();

  constructor(private wsUrl: string) {}

  async connect(): Promise<void> {
    this.ws = new WebSocket(this.wsUrl);

    await new Promise<void>((resolve, reject) => {
      this.ws!.on("open", () => resolve());
      this.ws!.on("error", (err) => reject(err));
      setTimeout(() => reject(new Error("WebSocket connection timeout")), 5000);
    });

    this.ws.on("message", (data: Buffer) => {
      try {
        const [header, body] = cborDecodeMulti(new Uint8Array(data));
        const message = body as any;

        if (message?.labels && Array.isArray(message.labels)) {
          message.labels.forEach((label: Label) => this.labelBuffer.add(label));
        }
      } catch (err) {
        console.error("Error decoding WebSocket message:", err);
      }
    });

    this.ws.on("error", (err) => {
      console.error("WebSocket error:", err);
    });
  }

  async waitForLabel(
    predicate: (label: Label) => boolean,
    timeoutMs: number
  ): Promise<Label> {
    return this.labelBuffer.waitFor(predicate, timeoutMs);
  }

  close(): void {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}
