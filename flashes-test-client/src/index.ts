import 'dotenv/config';
import { FlashesTestClient } from './client';

async function main() {
  // Load environment variables
  const pdsUrl = process.env.PDS_URL;
  const identifier = process.env.IDENTIFIER;
  const password = process.env.PASSWORD;
  const testMessage = process.env.TEST_MESSAGE;
  
  // E2E Testing variables
  const ozoneServiceUrl = process.env.OZONE_SERVICE_URL;
  const ozoneAdminHandle = process.env.OZONE_ADMIN_HANDLE;
  const ozoneAdminPassword = process.env.OZONE_ADMIN_PASSWORD;
  const enableE2ETesting = process.env.ENABLE_E2E_TESTING?.toLowerCase() === 'true';
  const expectedLabel = process.env.EXPECTED_LABEL || 'spam';
  const moderationTimeoutMs = parseInt(process.env.MODERATION_TIMEOUT_MS || '30000');

  if (!pdsUrl || !identifier || !password) {
    console.error('❌ Missing required environment variables:');
    console.error('   - PDS_URL: AT Protocol PDS endpoint');
    console.error('   - IDENTIFIER: Your handle or DID');
    console.error('   - PASSWORD: Your app password');
    console.error('');
    console.error('💡 Copy .env.example to .env and fill in your credentials');
    process.exit(1);
  }

  // Check E2E testing requirements
  if (enableE2ETesting) {
    if (!ozoneServiceUrl || !ozoneAdminHandle || !ozoneAdminPassword) {
      console.error('❌ E2E testing enabled but missing Ozone configuration:');
      console.error('   - OZONE_SERVICE_URL: Your Ozone instance URL');
      console.error('   - OZONE_ADMIN_HANDLE: Admin/moderator handle');
      console.error('   - OZONE_ADMIN_PASSWORD: Admin/moderator app password');
      console.error('');
      console.error('💡 Either disable E2E testing or provide Ozone credentials');
      process.exit(1);
    }
  }

  try {
    console.log('🚀 Starting Flashes Test Client...');
    console.log(`🌐 PDS URL: ${pdsUrl}`);
    console.log(`👤 User: ${identifier}`);
    if (enableE2ETesting) {
      console.log(`🔍 E2E Testing: ENABLED with Ozone at ${ozoneServiceUrl}`);
      console.log(`🏷️  Expected label: ${expectedLabel}`);
      console.log(`⏰ Timeout: ${moderationTimeoutMs}ms`);
    } else {
      console.log('🔍 E2E Testing: DISABLED (basic posting only)');
    }
    console.log('');

    // Initialize client
    const client = new FlashesTestClient(pdsUrl, ozoneServiceUrl);
    
    // Login to PDS
    await client.login(identifier, password);
    
    // Login to Ozone if E2E testing is enabled
    if (enableE2ETesting && ozoneAdminHandle && ozoneAdminPassword) {
      await client.loginToOzone(ozoneAdminHandle, ozoneAdminPassword);
    }
    
    console.log('');

    if (enableE2ETesting && client.hasOzoneConfigured() && client.isOzoneAuthenticated()) {
      // Run complete E2E test with Ozone verification
      console.log('🚀 Running E2E test with Ozone verification...');
      
      try {
        const verification = await client.testGtubeE2E(testMessage, expectedLabel, moderationTimeoutMs);
        
        // Display detailed E2E results
        console.log('');
        console.log('📊 E2E Test Results:');
        console.log('====================');
        console.log(`🎯 Test Result: ${verification.success ? 'PASSED ✅' : 'FAILED ❌'}`);
        console.log(`🏷️  Applied Labels: ${verification.labels.join(', ') || 'None'}`);
        console.log(`📈 Moderation Events: ${verification.events.length}`);
        console.log(`📋 Review State: ${verification.reviewState || 'Unknown'}`);
        console.log('');
        
        if (verification.events.length > 0) {
          console.log('📝 Recent Moderation Events:');
          verification.events.slice(0, 3).forEach((event, i) => {
            console.log(`   ${i + 1}. ${event.action || 'Unknown'} - ${event.createdBy || 'System'} (${new Date(event.createdAt).toLocaleString()})`);
          });
          console.log('');
        }
        
      } catch (error) {
        console.error('❌ E2E test failed:', error instanceof Error ? error.message : error);
        console.log('');
        console.log('🔧 Troubleshooting:');
        console.log('==================');
        console.log('1. Check Ozone credentials and permissions');
        console.log('2. Verify automod is running and processing messages');
        console.log('3. Ensure GTUBE rule is configured correctly');
        console.log('4. Check network connectivity to Ozone instance');
      }
      
    } else {
      // Run basic test (original behavior)
      console.log('🚀 Running basic GTUBE test (no Ozone verification)...');
      
      const result = await client.testGtubeModeration(testMessage);
      console.log('');

      // Display basic results
      console.log('📊 Basic Test Results:');
      console.log('======================');
      console.log(`✅ Post created successfully`);
      console.log(`🔗 URI: ${result.uri}`);
      console.log(`🆔 CID: ${result.cid}`);
      console.log('');
      
      console.log('🔍 Manual Verification Steps:');
      console.log('=============================');
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
      
      console.log('');
      console.log('💡 To enable automatic verification, set ENABLE_E2E_TESTING=true and provide Ozone credentials.');
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