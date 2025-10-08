import "dotenv/config";
import { AtpAgent, ComAtprotoModerationDefs, ComAtprotoRepoStrongRef } from "@atproto/api";
import { cborDecodeMulti } from "@atproto/common";
import { createTestUser, createOzoneModeratorAgent } from "./helpers/test-user-factory";
import { MaildevClient } from "./helpers/maildev-client";
import { waitForCondition, EventBuffer } from "./helpers/wait-helpers";
import { WebSocket } from "ws";
import * as fs from "fs";
import * as path from "path";

// Environment validation
const DOMAIN = process.env.DOMAIN;
if (!DOMAIN) {
  throw new Error("DOMAIN env var is required");
}
const PARTITION = process.env.PARTITION;
if (!PARTITION) {
  throw new Error("PARTITION env var is required");
}

// Read Ozone DID from shared volume file
const ozoneDidPath = path.join(__dirname, "data", "ozone-admin-did.txt");
if (!fs.existsSync(ozoneDidPath)) {
  throw new Error(`Ozone DID file not found at ${ozoneDidPath}. Run setup-ozone first.`);
}
const OZONE_SERVER_DID = fs.readFileSync(ozoneDidPath, "utf-8").trim();

const PDS_URL = `https://pds.${PARTITION}.${DOMAIN}`;
const MAILDEV_URL = `https://maildev.${PARTITION}.${DOMAIN}`;
const OZONE_WS_URL = `wss://ozone.${PARTITION}.${DOMAIN}/xrpc/com.atproto.label.subscribeLabels`;
const TEST_TIMEOUT_MS = 60000;
const HEPA_PROCESSING_TIMEOUT_MS = 10000; // 10 seconds for async spam detection
const GTUBE_TEST_STRING = "XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X";

jest.setTimeout(TEST_TIMEOUT_MS);

describe("Account Creation", () => {
  it("create_account_and_return_valid_did_when_given_valid_credentials", async () => {
    // Arrange & Act
    const { agent } = await createTestUser(PDS_URL);

    const did = agent.session?.did;

    // Assert
    expect(did).toBeDefined();
    expect(did).toMatch(/^did:/);
  });

  it("fail_when_handle_already_exists", async () => {
    // Arrange
    const { handle } = await createTestUser(PDS_URL);

    const agent = new AtpAgent({ service: PDS_URL });

    // Act & Assert
    await expect(
      agent.createAccount({
        email: "different@mail.com",
        password: "abc123",
        handle,
      })
    ).rejects.toThrow();
  });
});

describe("Email Integration", () => {
  let maildevClient: MaildevClient;

  beforeAll(() => {
    maildevClient = new MaildevClient(MAILDEV_URL);
  });

  it("send_verification_email_when_confirmation_requested", async () => {
    // Arrange
    const { agent } = await createTestUser(PDS_URL);
    await maildevClient.clearAllEmails();

    // Act
    await agent.com.atproto.server.requestEmailConfirmation();
    await maildevClient.waitForDelivery();

    // Assert
    const emails = await maildevClient.getEmails();
    expect(emails.length).toBeGreaterThan(0);
  });

  it("confirm_email_when_valid_token_provided", async () => {
    // Arrange
    const { agent, email } = await createTestUser(PDS_URL);
    await maildevClient.clearAllEmails();

    await agent.com.atproto.server.requestEmailConfirmation();
    await maildevClient.waitForDelivery();

    const emails = await maildevClient.getEmails();
    const token = maildevClient.extractTokenFromEmail(emails[0]);

    // Act
    await agent.com.atproto.server.confirmEmail({ email, token: token! });

    const session = await agent.com.atproto.server.getSession();

    // Assert
    expect(session.data.emailConfirmed).toBe(true);
  });
});

describe("Moderation Report", () => {
  it("create_spam_report_for_user_post", async () => {
    // Arrange
    const spammer = await createTestUser(PDS_URL);
    const reporter = await createTestUser(PDS_URL);

    const postResult = await spammer.agent.app.bsky.feed.post.create(
      { repo: spammer.agent.session!.did },
      {
        text: "This is spam content",
        createdAt: new Date().toISOString(),
      }
    );

    const reporterOzoneAgent = reporter.agent.withProxy("atproto_labeler", OZONE_SERVER_DID);

    // Act - Create report via Ozone moderation service
    const report = await reporterOzoneAgent.com.atproto.moderation.createReport({
      reasonType: ComAtprotoModerationDefs.REASONSPAM,
      subject: {
        $type: "com.atproto.repo.strongRef",
        uri: postResult.uri,
        cid: postResult.cid,
      },
      reason: "Spam content detected",
    });

    // Assert
    expect(report.data.id).toBeDefined();
    expect(report.data.reasonType).toBe(ComAtprotoModerationDefs.REASONSPAM);
    expect(report.data.subject).toMatchObject({
      $type: "com.atproto.repo.strongRef",
      uri: postResult.uri,
    });
    expect(report.data.reportedBy).toBe(reporter.agent.session!.did);

    // Verify report is queryable via Ozone internal API (using admin auth)
    const { ozoneAgent } = await createOzoneModeratorAgent(
      PDS_URL,
      PARTITION,
      DOMAIN,
      process.env.OZONE_ADMIN_PASSWORD
    );

    const events = await ozoneAgent.tools.ozone.moderation.queryEvents({
      subject: postResult.uri,
    });

    expect(events.data.events).toBeDefined();
    expect(events.data.events.length).toBeGreaterThan(0);

    const reportEvent = events.data.events.find(
      (e) => e.event.$type === "tools.ozone.moderation.defs#modEventReport"
    );
    expect(reportEvent).toBeDefined();
    expect((reportEvent!.event as any).reportType).toBe(ComAtprotoModerationDefs.REASONSPAM);
  });

  it("detect_gtube_spam_in_flash_posts_automatically", async () => {
    const { agent } = await createTestUser(PDS_URL);
    const flashPost = await agent.com.atproto.repo.createRecord({
      repo: agent.session!.did,
      collection: "app.flashes.feed.post",
      record: {
        $type: "app.flashes.feed.post",
        text: `Flash with GTUBE: ${GTUBE_TEST_STRING}`,
        createdAt: new Date().toISOString(),
      },
    });

    const { ozoneAgent } = await createOzoneModeratorAgent(
      PDS_URL,
      PARTITION,
      DOMAIN,
      process.env.OZONE_ADMIN_PASSWORD
    );

    const events = await waitForCondition(
      () => ozoneAgent.tools.ozone.moderation.queryEvents({
        collections: ["app.flashes.feed.post"],
        subject: flashPost.data.uri,
        limit: 10,
      }),
      (result) => result.data.events.length >= 2,
      { timeout: HEPA_PROCESSING_TIMEOUT_MS, interval: 500 }
    );

    expect(events.data.events.length).toBeGreaterThanOrEqual(2);

    const labelEvent = events.data.events.find(
      (e: any) => e.event.$type === "tools.ozone.moderation.defs#modEventLabel"
    );
    expect(labelEvent).toBeDefined();
    expect((labelEvent as any).event.createLabelVals).toContain("spam");

    const tagEvent = events.data.events.find(
      (e: any) => e.event.$type === "tools.ozone.moderation.defs#modEventTag"
    );
    expect(tagEvent).toBeDefined();
    expect((tagEvent as any).event.add).toContain("gtube-flash");
  });

  it("receive_spam_label_via_websocket_when_gtube_detected_in_flash", async () => {
    let ws: WebSocket | null = null;

    try {
      // Arrange
      const { agent } = await createTestUser(PDS_URL);

      // Establish WebSocket connection to Ozone label stream
      ws = new WebSocket(OZONE_WS_URL);

      await new Promise<void>((resolve, reject) => {
        ws!.on("open", () => resolve());
        ws!.on("error", (err) => reject(err));
        setTimeout(() => reject(new Error("WebSocket connection timeout")), 5000);
      });

      // Create event buffer to collect WebSocket messages
      const labelBuffer = new EventBuffer<any>();

      ws.on("message", (data: Buffer) => {
        try {
          // AT Protocol uses CBOR encoding for WebSocket messages
          const [header, body] = cborDecodeMulti(new Uint8Array(data));
          console.log("WebSocket message received:", JSON.stringify({ header, body }, null, 2));

          // Handle AT Protocol label subscription format
          // body should contain labels array
          const message = body as any;
          if (message && message.labels && Array.isArray(message.labels)) {
            message.labels.forEach((label: any) => labelBuffer.add(label));
          }
        } catch (err) {
          console.error("Error decoding WebSocket message:", err);
        }
      });

      ws.on("error", (err) => {
        // Error will be caught by waitFor timeout
        console.error("WebSocket error:", err);
      });

      // Act
      const flashPost = await agent.com.atproto.repo.createRecord({
        repo: agent.session!.did,
        collection: "app.flashes.feed.post",
        record: {
          $type: "app.flashes.feed.post",
          text: `Flash with GTUBE: ${GTUBE_TEST_STRING}`,
          createdAt: new Date().toISOString(),
        },
      });

      const flashPostUri = flashPost.data.uri;

      // Wait for spam label for this specific post
      const receivedLabel = await labelBuffer.waitFor(
        (label) => label.val === "spam" && label.uri === flashPostUri,
        HEPA_PROCESSING_TIMEOUT_MS
      );

      // Assert
      expect(receivedLabel).toBeDefined();
      expect(receivedLabel.val).toBe("spam");
      expect(receivedLabel.uri).toBe(flashPostUri);
      expect(receivedLabel.src).toBe(OZONE_SERVER_DID);
    } finally {
      // Cleanup
      if (ws) {
        ws.close();
      }
    }
  });
});
