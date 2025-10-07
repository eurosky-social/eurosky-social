import "dotenv/config";
import { AtpAgent } from "@atproto/api";

// Environment validation
const DOMAIN = process.env.DOMAIN;
if (!DOMAIN) {
  throw new Error("DOMAIN env var is required");
}
const PARTITION = process.env.PARTITION;
if (!PARTITION) {
  throw new Error("PARTITION env var is required");
}

const PDS_DOMAIN = `pds.${PARTITION}.${DOMAIN}`;

jest.setTimeout(60000);

describe("Account Creation", () => {
  it("create_account_and_return_valid_did_when_given_valid_credentials", async () => {
    // Arrange
    const agent = new AtpAgent({ service: `https://${PDS_DOMAIN}` });
    const username = `test${Math.floor(Math.random() * 10000)}`;
    const handle = `${username}.${PDS_DOMAIN}`;
    const email = `${username}@mail.com`;
    const password = "abc123";

    // Act
    await agent.createAccount({
      email,
      password,
      handle,
    });

    const did = agent.session?.did;

    // Assert
    expect(did).toBeDefined();
    expect(did).toMatch(/^did:/);
  });

  it("fail_when_handle_already_exists", async () => {
    // Arrange
    const agent = new AtpAgent({ service: `https://${PDS_DOMAIN}` });
    const username = `test${Math.floor(Math.random() * 10000)}`;
    const handle = `${username}.${PDS_DOMAIN}`;
    const firstEmail = `${username}@mail.com`;
    const secondEmail = `${username}-different@mail.com`;
    const password = "abc123";

    await agent.createAccount({
      email: firstEmail,
      password,
      handle,
    });

    // Act & Assert
    await expect(
      agent.createAccount({
        email: secondEmail,
        password,
        handle,
      })
    ).rejects.toThrow();
  });
});

describe("Email Integration", () => {
  it("send_verification_email_when_confirmation_requested", async () => {
    // Arrange
    const agent = new AtpAgent({ service: `https://${PDS_DOMAIN}` });
    const username = `test${Math.floor(Math.random() * 10000)}`;
    const handle = `${username}.${PDS_DOMAIN}`;
    const email = `${username}@mail.com`;
    const password = "abc123";

    await agent.createAccount({
      email,
      password,
      handle,
    });

    // Clear maildev emails before test
    await fetch("https://maildev.eurosky.u-at-proto.work/email/all", {
      method: "DELETE",
    });

    // Act
    await agent.com.atproto.server.requestEmailConfirmation();

    // Wait for email delivery
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Assert
    const response = await fetch("https://maildev.eurosky.u-at-proto.work/email");
    const emails = (await response.json()) as Array<unknown>;
    expect(emails.length).toBeGreaterThan(0);
  });

  it("confirm_email_when_valid_token_provided", async () => {
    // Arrange
    const agent = new AtpAgent({ service: `https://${PDS_DOMAIN}` });
    const username = `test${Math.floor(Math.random() * 10000)}`;
    const handle = `${username}.${PDS_DOMAIN}`;
    const email = `${username}@mail.com`;
    const password = "abc123";

    await agent.createAccount({
      email,
      password,
      handle,
    });

    await fetch("https://maildev.eurosky.u-at-proto.work/email/all", {
      method: "DELETE",
    });

    await agent.com.atproto.server.requestEmailConfirmation();

    await new Promise((resolve) => setTimeout(resolve, 2000));

    const response = await fetch("https://maildev.eurosky.u-at-proto.work/email");
    const emails = (await response.json()) as Array<{ html: string }>;
    const tokenMatch = emails[0].html.match(/>([a-z0-9]{5}-[a-z0-9]{5})</i);
    const token = tokenMatch![1];

    // Act
    await agent.com.atproto.server.confirmEmail({ email, token });

    const session = await agent.com.atproto.server.getSession();

    // Assert
    expect(session.data.emailConfirmed).toBe(true);
  });
});
