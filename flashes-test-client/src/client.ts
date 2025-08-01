import { AtpAgent, AtUri } from '@atproto/api';
import { XRPCError } from '@atproto/xrpc';

export interface FlashesPost {
  $type: 'app.flashes.feed.post';
  text: string;
  createdAt: string;
  langs?: string[];
  tags?: string[];
  reply?: {
    root: { uri: string; cid: string };
    parent: { uri: string; cid: string };
  };
  labels?: {
    $type: 'com.atproto.label.defs#selfLabels';
    values: Array<{ val: string }>;
  };
}

export class FlashesTestClient {
  private agent: AtpAgent;
  private isLoggedIn = false;

  constructor(pdsUrl: string) {
    this.agent = new AtpAgent({
      service: pdsUrl,
    });
  }

  async login(identifier: string, password: string): Promise<void> {
    try {
      console.log(`🔐 Logging in as ${identifier}...`);
      await this.agent.login({
        identifier,
        password,
      });
      this.isLoggedIn = true;
      console.log('✅ Successfully logged in!');
    } catch (error) {
      console.error('❌ Login failed:', error);
      throw error;
    }
  }

  async postFlashMessage(text: string, tags?: string[]): Promise<{ uri: string; cid: string }> {
    if (!this.isLoggedIn) {
      throw new Error('Must be logged in to post messages');
    }

    const record: FlashesPost = {
      $type: 'app.flashes.feed.post',
      text,
      createdAt: new Date().toISOString(),
    };

    if (tags && tags.length > 0) {
      record.tags = tags;
    }

    try {
      console.log(`📝 Creating flash post with text: "${text.substring(0, 50)}${text.length > 50 ? '...' : ''}"`);
      
      const response = await this.agent.com.atproto.repo.createRecord({
        repo: this.agent.session?.did || '',
        collection: 'app.flashes.feed.post',
        record,
      });

      console.log(`✅ Flash post created successfully!`);
      console.log(`   URI: ${response.data.uri}`);
      console.log(`   CID: ${response.data.cid}`);
      
      return {
        uri: response.data.uri,
        cid: response.data.cid,
      };
    } catch (error) {
      if (error instanceof XRPCError) {
        console.error('❌ XRPC Error creating flash post:', {
          status: error.status,
          error: error.error,
          message: error.message,
        });
      } else {
        console.error('❌ Error creating flash post:', error);
      }
      throw error;
    }
  }

  async getRecord(uri: string): Promise<any> {
    try {
      const atUri = new AtUri(uri);
      const response = await this.agent.com.atproto.repo.getRecord({
        repo: atUri.hostname,
        collection: atUri.collection,
        rkey: atUri.rkey,
      });
      
      return response.data;
    } catch (error) {
      console.error('❌ Error fetching record:', error);
      throw error;
    }
  }

  async testGtubeModeration(customMessage?: string): Promise<{ uri: string; cid: string }> {
    const gtubeString = "XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X";
    const testMessage = customMessage || `Testing automod with GTUBE string: ${gtubeString}`;
    
    console.log('🧪 Testing GTUBE moderation rule...');
    console.log(`📋 Message contains GTUBE test string: ${gtubeString}`);
    
    return await this.postFlashMessage(testMessage, ['gtube-test', 'automod-test']);
  }

  getSession() {
    return this.agent.session;
  }

  isAuthenticated(): boolean {
    return this.isLoggedIn && !!this.agent.session;
  }
}