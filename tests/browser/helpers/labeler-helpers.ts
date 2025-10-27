import { AtpAgent } from "@atproto/api";

export interface LabelerSubscriptionConfig {
  handle: string;
  password: string;
  pdsUrl: string;
  labelerDid: string;
}

/**
 * Subscribe a user to a labeler service via API.
 * This is necessary for the user to be able to send reports to that labeler.
 */
export async function subscribeToLabeler(config: LabelerSubscriptionConfig): Promise<void> {
  const agent = new AtpAgent({ service: config.pdsUrl });

  await agent.login({
    identifier: config.handle,
    password: config.password,
  });

  // Add the labeler to the user's preferences
  await agent.addLabeler(config.labelerDid);

  console.log(`User ${config.handle} subscribed to labeler ${config.labelerDid}`);
}
