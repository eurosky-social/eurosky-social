import "dotenv/config";
import { AtpAgent } from "@atproto/api";
import { createTestUser } from "./helpers/test-user-factory";
import { MaildevClient } from "./helpers/maildev-client";

// Environment validation
const DOMAIN = process.env.DOMAIN;
if (!DOMAIN) {
  throw new Error("DOMAIN env var is required");
}
const PARTITION = process.env.PARTITION;
if (!PARTITION) {
  throw new Error("PARTITION env var is required");
}

const PDS_URL = `https://pds.${PARTITION}.${DOMAIN}`;
const MAILDEV_URL = `https://maildev.${PARTITION}.${DOMAIN}`;
const TEST_TIMEOUT_MS = 60000;

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
