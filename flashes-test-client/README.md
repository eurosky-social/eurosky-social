# Flashes Test Client

A TypeScript client to test the `app.flashes.*` GTUBE moderation rule in your deployed eurosky automod instance.

## Overview

This client supports two testing modes:

### Basic Testing (Default)
1. Logs into a PDS (Personal Data Server)
2. Posts a message containing the GTUBE test string to the `app.flashes.feed.post` collection
3. Allows you to manually verify that your deployed hepa + automod + ozone stack correctly labels the message

### E2E Testing (With Ozone Integration)
1. Posts a GTUBE test message (same as basic mode)
2. **Automatically connects to Ozone** to verify moderation actions
3. **Polls for applied labels** and moderation events
4. **Provides instant feedback** on whether the GTUBE rule worked
5. **Shows detailed moderation history** and applied labels

## GTUBE Moderation Rule

The client tests the `GtubeFlashRule` defined in `indigo/automod/rules/gtube.go`:

- **Rule**: Detects GTUBE strings in `app.flashes.*` collections
- **GTUBE String**: `XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X`
- **Expected Actions**:
  - Adds record label: `"spam"`
  - Sends notification: `"slack"`
  - Adds record tag: `"gtube-flash"`

## Setup

1. **Install dependencies**:
   ```bash
   cd flashes-test-client
   npm install
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

   **Required for Basic Testing:**
   - `PDS_URL`: Your PDS endpoint (e.g., `https://your-pds.com`)
   - `IDENTIFIER`: Your handle (e.g., `alice.bsky.social`) or DID
   - `PASSWORD`: Your app password (create one in your PDS settings)

   **Additional for E2E Testing:**
   - `ENABLE_E2E_TESTING=true`: Enable automatic Ozone verification
   - `OZONE_SERVICE_URL`: Your Ozone instance endpoint
   - `OZONE_ADMIN_HANDLE`: Admin/moderator handle for Ozone
   - `OZONE_ADMIN_PASSWORD`: Admin/moderator app password

3. **Optional configuration**:
   - `TEST_MESSAGE`: Custom message (defaults to GTUBE test string)
   - `EXPECTED_LABEL`: Expected moderation label (defaults to `spam`)
   - `MODERATION_TIMEOUT_MS`: How long to wait for moderation (defaults to `30000`)

## Usage

### Basic Testing (Default)

Run without E2E verification:
```bash
npm run dev
```

### E2E Testing (Recommended)

1. **Enable E2E testing** in your `.env`:
   ```bash
   ENABLE_E2E_TESTING=true
   OZONE_SERVICE_URL=https://your-ozone.com
   OZONE_ADMIN_HANDLE=admin.handle
   OZONE_ADMIN_PASSWORD=admin-app-password
   ```

2. **Run the test**:
   ```bash
   npm run dev
   ```

### Alternative Commands

Build and run:
```bash
npm run build
npm start
```

Or use the test command:
```bash
npm test
```

## What to Expect

### Basic Testing Mode

1. **Client Output**:
   - Login confirmation
   - Post creation with URI and CID
   - Instructions for manual verification

2. **In Your Deployed Stack**:
   - **Automod logs**: Should show GTUBE rule triggering
   - **Ozone**: Record should appear with spam label
   - **Hepa**: Message should be processed through the pipeline
   - **Slack**: Notification should be sent (if configured)

### E2E Testing Mode

1. **Client Output**:
   - Login confirmation for both PDS and Ozone
   - Post creation with URI and CID
   - **Automatic verification polling**
   - **Test result: PASSED/FAILED**
   - **Applied labels and moderation events**
   - **Detailed moderation history**

2. **Verification Process**:
   - Polls Ozone every 2 seconds for up to 30 seconds (configurable)
   - Checks for expected labels (default: "spam")
   - Retrieves and displays moderation events
   - Shows review state and full moderation history

## Manual Verification Steps

1. **Check automod logs** for the GTUBE rule triggering
2. **Check Ozone interface** for the labeled record
3. **Check Slack notifications** (if configured)
4. **Verify record tags** include "gtube-flash"
5. **Confirm spam label** is applied

## Troubleshooting

### Authentication Issues
- **PDS**: Ensure your PDS URL is correct
- **PDS**: Use an app password, not your main account password
- **PDS**: Verify your handle/DID is correct
- **Ozone**: Ensure Ozone admin credentials have moderator permissions
- **Ozone**: Verify Ozone service URL is accessible

### Post Creation Issues
- Check that your PDS supports the `app.flashes.feed.post` collection
- Verify the lexicon schema is properly registered
- Ensure you have write permissions

### E2E Testing Issues
- **Permissions**: Ozone credentials must have moderator/admin role
- **Network**: Ensure Ozone instance is accessible from your client
- **Timing**: Increase `MODERATION_TIMEOUT_MS` if automod is slow
- **Labels**: Check `EXPECTED_LABEL` matches your GTUBE rule configuration
- **API Errors**: Review Ozone API errors for permission or configuration issues

### Moderation Not Working
- Confirm your automod instance is processing the firehose
- Check that the GtubeFlashRule is enabled in your ruleset
- Verify the collection prefix matching in the rule
- Ensure automod has proper Ozone connectivity for labeling

## Example Output

### Basic Testing Mode

```
🚀 Starting Flashes Test Client...
🌐 PDS URL: https://your-pds.com
👤 User: alice.bsky.social
🔍 E2E Testing: DISABLED (basic posting only)

🔐 Logging in as alice.bsky.social...
✅ Successfully logged in!

🚀 Running basic GTUBE test (no Ozone verification)...
🧪 Testing GTUBE moderation rule...
📋 Message contains GTUBE test string: XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
📝 Creating flash post with text: "Testing automod with GTUBE string: XJS*C4JDBQADN1..."
✅ Flash post created successfully!
   URI: at://did:plc:abc123/app.flashes.feed.post/3l2uygozqt522
   CID: bafyreif5uqxwm7hdpliinzwba4lh2cp2edvitrlmrwb3qxcbqlyb4ua6my

📊 Basic Test Results:
======================
✅ Post created successfully
🔗 URI: at://did:plc:abc123/app.flashes.feed.post/3l2uygozqt522
🆔 CID: bafyreif5uqxwm7hdpliinzwba4lh2cp2edvitrlmrwb3qxcbqlyb4ua6my

💡 To enable automatic verification, set ENABLE_E2E_TESTING=true and provide Ozone credentials.
```

### E2E Testing Mode

```
🚀 Starting Flashes Test Client...
🌐 PDS URL: https://your-pds.com
👤 User: alice.bsky.social
🔍 E2E Testing: ENABLED with Ozone at https://your-ozone.com
🏷️  Expected label: spam
⏰ Timeout: 30000ms

🔐 Logging in as alice.bsky.social...
✅ Successfully logged in!
🔐 Logging into Ozone as admin.handle...
✅ Successfully logged into Ozone!

🚀 Running E2E test with Ozone verification...
🧪 Starting complete E2E GTUBE test...
🧪 Testing GTUBE moderation rule...
📋 Message contains GTUBE test string: XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
📝 Creating flash post with text: "Testing automod with GTUBE string: XJS*C4JDBQADN1..."
✅ Flash post created successfully!
   URI: at://did:plc:abc123/app.flashes.feed.post/3l2uygozqt522
   CID: bafyreif5uqxwm7hdpliinzwba4lh2cp2edvitrlmrwb3qxcbqlyb4ua6my
✅ Message posted: at://did:plc:abc123/app.flashes.feed.post/3l2uygozqt522

🔍 Verifying moderation action for: at://did:plc:abc123/app.flashes.feed.post/3l2uygozqt522
⏰ Timeout: 30000ms, Expected label: spam
⏳ Polling for moderation status...
📊 Found 1 labels: spam
📈 Found 2 moderation events
🎯 Expected label "spam" found: true
🎉 E2E Test PASSED!
🏷️  Applied labels: spam
📊 Moderation events: 2
🔍 Review state: open

📊 E2E Test Results:
====================
🎯 Test Result: PASSED ✅
🏷️  Applied Labels: spam
📈 Moderation Events: 2
📋 Review State: open

📝 Recent Moderation Events:
   1. tools.ozone.moderation.defs#modEventLabel - automod (8/1/2025, 3:29:42 PM)
   2. tools.ozone.moderation.defs#modEventReport - automod (8/1/2025, 3:29:41 PM)
```

## Related Files

- **Lexicon**: `atproto/lexicons/app/flashes/feed/post.json`
- **Go API**: `indigo/api/flashes/feedpost.go`
- **GTUBE Rule**: `indigo/automod/rules/gtube.go`
- **Lexgen Config**: `indigo/cmd/lexgen/flashes.json`