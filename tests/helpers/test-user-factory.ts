import { AtpAgent } from "@atproto/api";

const DEFAULT_PASSWORD = "abc123";
const USERNAME_RANDOM_RANGE = 10000;

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

  return { agent, username, handle, email, password };
}
