import 'dotenv/config';
import { FlashesTestClient } from './client';

async function main() {
  // Load environment variables
  const pdsUrl = process.env.PDS_URL;
  const identifier = process.env.IDENTIFIER;
  const password = process.env.PASSWORD;
  const testMessage = process.env.TEST_MESSAGE;

  if (!pdsUrl || !identifier || !password) {
    console.error('❌ Missing required environment variables:');
    console.error('   - PDS_URL: AT Protocol PDS endpoint');
    console.error('   - IDENTIFIER: Your handle or DID');
    console.error('   - PASSWORD: Your app password');
    console.error('');
    console.error('💡 Copy .env.example to .env and fill in your credentials');
    process.exit(1);
  }

  try {
    console.log('🚀 Starting Flashes Test Client...');
    console.log(`🌐 PDS URL: ${pdsUrl}`);
    console.log(`👤 User: ${identifier}`);
    console.log('');

    // Initialize client
    const client = new FlashesTestClient(pdsUrl);
    
    // Login
    await client.login(identifier, password);
    console.log('');

    // Test GTUBE moderation rule
    const result = await client.testGtubeModeration(testMessage);
    console.log('');

    // Display results
    console.log('📊 Test Results:');
    console.log('================');
    console.log(`✅ Post created successfully`);
    console.log(`🔗 URI: ${result.uri}`);
    console.log(`🆔 CID: ${result.cid}`);
    console.log('');
    
    console.log('🔍 Next Steps:');
    console.log('==============');
    console.log('1. Check your deployed automod instance logs');
    console.log('2. Verify the message appears in hepa + ozone');
    console.log('3. Confirm the gtube-flash label is applied');
    console.log('4. Look for Slack notifications if configured');
    console.log('');
    
    console.log('🧬 GTUBE Rule Details:');
    console.log('======================');
    console.log('- Rule: GtubeFlashRule in indigo/automod/rules/gtube.go');
    console.log('- Collection: app.flashes.*');
    console.log('- Expected Label: "spam"');
    console.log('- Expected Tag: "gtube-flash"');
    console.log('- Notification: "slack"');
    console.log('');

    // Wait a moment for processing
    console.log('⏳ Waiting 5 seconds for automod processing...');
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Fetch the record to see current state
    try {
      console.log('🔍 Fetching record to check current state...');
      const record = await client.getRecord(result.uri);
      console.log('📄 Record data:', JSON.stringify(record, null, 2));
    } catch (error) {
      console.log('⚠️ Could not fetch record (this is normal for some PDS configurations)');
    }

  } catch (error) {
    console.error('💥 Test failed:', error);
    process.exit(1);
  }
}

// Handle process termination gracefully
process.on('SIGINT', () => {
  console.log('\\n👋 Test client shutting down...');
  process.exit(0);
});

// Run the main function
main().catch((error) => {
  console.error('💥 Unhandled error:', error);
  process.exit(1);
});