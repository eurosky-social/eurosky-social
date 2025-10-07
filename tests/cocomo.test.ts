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
