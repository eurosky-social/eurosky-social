import { AtpAgent } from "@atproto/api";

export interface ReportConfig {
  pdsUrl: string;
  username: string;
  password: string;
}

export async function reportPost(config: ReportConfig): Promise<any> {
  const agent = new AtpAgent({
    service: config.pdsUrl,
  });

  await agent.login({
    identifier: config.username,
    password: config.password,
  });

  const labelerIdentity = await agent.resolveHandle({handle: "eurosky-ozone.bsky.social"});

  const response = await agent
    .withProxy("atproto_labeler", labelerIdentity.data.did)
    .createModerationReport({
      subject: {
        $type: "com.atproto.repo.strongRef",
        uri: "at://did:plc:autcqcg4hsvgdf3hwt4cvci3/app.flashes.feed.post/3lwh4vvzc5o2w",
        cid: "bafyreicpq2zjczjm5o6l7dpvpftzz5vomfuljovdmb5ayiewtisvqfmvaq",
      },
      reasonType: "com.atproto.moderation.defs#reasonSpam",
      reason: "some spam 222",
    });

  return response;
}
