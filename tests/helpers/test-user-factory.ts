import { AtpAgent } from "@atproto/api";

const DEFAULT_PASSWORD = "abc123";
const USERNAME_RANDOM_RANGE = 10000;
const DEFAULT_OZONE_ADMIN_PASSWORD = "admin123";
const OZONE_ADMIN_HANDLE_PREFIX = "ozone.pds";
const ATPROTO_LABELER_PROXY_TYPE = "atproto_labeler";

export interface TestUser {
  agent: AtpAgent;
  username: string;
  handle: string;
  email: string;
  password: string;
}

export async function createTestUser(
  pdsUrl: string,
  overrides?: Partial<Omit<TestUser, "agent">>
): Promise<TestUser> {
  const agent = new AtpAgent({ service: pdsUrl });
  const username =
    overrides?.username ?? `test${Math.floor(Math.random() * USERNAME_RANDOM_RANGE)}`;
  const handle = overrides?.handle ?? `${username}.${new URL(pdsUrl).hostname}`;
  const email = overrides?.email ?? `${username}@mail.com`;
  const password = overrides?.password ?? DEFAULT_PASSWORD;

  await agent.createAccount({ email, password, handle });

  // Create profile record (required for app.bsky.actor.getProfile to work)
  await agent.app.bsky.actor.profile.create(
    { repo: agent.session!.did },
    {
      displayName: username,
      createdAt: new Date().toISOString(),
    }
  );

  return { agent, username, handle, email, password };
}

export interface OzoneModeratorSession {
  pdsAgent: AtpAgent;
  ozoneAgent: AtpAgent;
  moderatorDid: string;
}

export async function createOzoneModeratorAgent(
  pdsUrl: string,
  partition: string,
  domain: string,
  password?: string
): Promise<OzoneModeratorSession> {
  // Login via PDS to get authenticated session
  const pdsAgent = new AtpAgent({ service: pdsUrl });
  const ozoneAdminPassword = password ?? DEFAULT_OZONE_ADMIN_PASSWORD;
  const ozoneAdminIdentifier = `${OZONE_ADMIN_HANDLE_PREFIX}.${partition}.${domain}`;

  await pdsAgent.login({
    identifier: ozoneAdminIdentifier,
    password: ozoneAdminPassword,
  });

  // Resolve Ozone admin DID
  const ozoneHandle = `${OZONE_ADMIN_HANDLE_PREFIX}.${partition}.${domain}`;
  const resolveResponse = await pdsAgent.resolveHandle({ handle: ozoneHandle });
  const ozoneDid = resolveResponse.data.did;

  // Create proxy agent for Ozone labeler
  const ozoneAgent = pdsAgent.withProxy(ATPROTO_LABELER_PROXY_TYPE, ozoneDid);

  return {
    pdsAgent,
    ozoneAgent,
    moderatorDid: pdsAgent.session!.did,
  };
}
