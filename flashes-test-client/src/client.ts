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

export interface ModerationVerificationResult {
  success: boolean;
  labels: string[];
  events: any[];
  status: string;
  reviewState?: string;
}

export class FlashesTestClient {
  private agent: AtpAgent;
  private ozoneAgent?: AtpAgent;
  private isLoggedIn = false;
  private isOzoneLoggedIn = false;

  constructor(pdsUrl: string, private ozoneUrl?: string) {
    this.agent = new AtpAgent({
      service: pdsUrl,
    });
    
    if (ozoneUrl) {
      this.ozoneAgent = new AtpAgent({
        service: ozoneUrl,
      });
    }
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

  async loginToOzone(identifier: string, password: string): Promise<void> {
    if (!this.ozoneAgent) {
      throw new Error('Ozone URL not configured. Please provide ozoneUrl in constructor.');
    }

    try {
      console.log(`🔐 Logging into Ozone as ${identifier}...`);
      await this.ozoneAgent.login({
        identifier,
        password,
      });
      this.isOzoneLoggedIn = true;
      console.log('✅ Successfully logged into Ozone!');
    } catch (error) {
      console.error('❌ Ozone login failed:', error);
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

  async verifyModerationAction(
    uri: string, 
    expectedLabel: string = "spam",
    timeoutMs: number = 30000
  ): Promise<ModerationVerificationResult> {
    if (!this.ozoneAgent) {
      throw new Error('Ozone agent not configured. Please provide ozoneUrl and login to Ozone.');
    }
    
    if (!this.isOzoneLoggedIn) {
      throw new Error('Must be logged into Ozone to verify moderation actions.');
    }

    console.log(`🔍 Verifying moderation action for: ${uri}`);
    console.log(`⏰ Timeout: ${timeoutMs}ms, Expected label: ${expectedLabel}`);

    const startTime = Date.now();
    
    while (Date.now() - startTime < timeoutMs) {
      try {
        // Check subject status using Ozone API
        const statusResponse = await this.ozoneAgent.tools.ozone.moderation.queryStatuses({
          subject: uri,
          limit: 1
        });

        if (statusResponse.data.subjectStatuses.length > 0) {
          const subject = statusResponse.data.subjectStatuses[0];
          
          // Get moderation events for this subject  
          const eventsResponse = await this.ozoneAgent.tools.ozone.moderation.queryEvents({
            subject: uri,
            limit: 10
          });

          // Extract labels
          const labels = subject.labels?.map(label => label.val) || [];
          
          // Check for expected label
          const hasExpectedLabel = labels.includes(expectedLabel);

          console.log(`📊 Found ${labels.length} labels: ${labels.join(', ')}`);
          console.log(`📈 Found ${eventsResponse.data.events.length} moderation events`);
          console.log(`🎯 Expected label "${expectedLabel}" found: ${hasExpectedLabel}`);

          return {
            success: hasExpectedLabel,
            labels,
            events: eventsResponse.data.events,
            status: subject.reviewState || 'unknown',
            reviewState: subject.reviewState
          };
        }
      } catch (error) {
        if (error instanceof XRPCError) {
          console.log(`⏳ Polling for moderation status... (${error.status}: ${error.message})`);
        } else {
          console.log('⏳ Polling for moderation status...', error instanceof Error ? error.message : error);
        }
      }
      
      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
    
    throw new Error(`Timeout: No moderation action detected within ${timeoutMs}ms`);
  }

  async testGtubeModeration(customMessage?: string): Promise<{ uri: string; cid: string }> {
    const gtubeString = "XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X";
    const testMessage = customMessage || `Testing automod with GTUBE string: ${gtubeString}`;
    
    console.log('🧪 Testing GTUBE moderation rule...');
    console.log(`📋 Message contains GTUBE test string: ${gtubeString}`);
    
    return await this.postFlashMessage(testMessage, ['gtube-test', 'automod-test']);
  }

  async testGtubeE2E(
    customMessage?: string,
    expectedLabel: string = "spam",
    timeoutMs: number = 30000
  ): Promise<ModerationVerificationResult> {
    console.log('🧪 Starting complete E2E GTUBE test...');
    
    // 1. Post message with GTUBE string
    const result = await this.testGtubeModeration(customMessage);
    console.log(`✅ Message posted: ${result.uri}`);
    
    // 2. Wait and verify moderation action
    const verification = await this.verifyModerationAction(
      result.uri,
      expectedLabel,
      timeoutMs
    );
    
    if (verification.success) {
      console.log('🎉 E2E Test PASSED!');
      console.log(`🏷️  Applied labels: ${verification.labels.join(', ')}`);
      console.log(`📊 Moderation events: ${verification.events.length}`);
      console.log(`🔍 Review state: ${verification.status}`);
    } else {
      console.log('❌ E2E Test FAILED!');
      console.log(`🏷️  Found labels: ${verification.labels.join(', ')}`);
      console.log('🔍 Check your automod configuration');
    }
    
    return verification;
  }

  getSession() {
    return this.agent.session;
  }

  isAuthenticated(): boolean {
    return this.isLoggedIn && !!this.agent.session;
  }

  isOzoneAuthenticated(): boolean {
    return this.isOzoneLoggedIn && !!this.ozoneAgent?.session;
  }

  hasOzoneConfigured(): boolean {
    return !!this.ozoneAgent;
  }
}