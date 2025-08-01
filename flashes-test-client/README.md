# Flashes Test Client

A TypeScript client to test the `app.flashes.*` GTUBE moderation rule in your deployed eurosky automod instance.

## Overview

This client programmatically:
1. Logs into a PDS (Personal Data Server)
2. Posts a message containing the GTUBE test string to the `app.flashes.feed.post` collection
3. Allows you to manually verify that your deployed hepa + automod + ozone stack correctly labels the message

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
   # Edit .env with your PDS credentials
   ```

   Required environment variables:
   - `PDS_URL`: Your PDS endpoint (e.g., `https://your-pds.com`)
   - `IDENTIFIER`: Your handle (e.g., `alice.bsky.social`) or DID
   - `PASSWORD`: Your app password (create one in your PDS settings)

3. **Optional configuration**:
   - `TEST_MESSAGE`: Custom message (defaults to GTUBE test string)
   - `POST_COLLECTION`: Collection to post to (defaults to `app.flashes.feed.post`)

## Usage

### Run the test:
```bash
npm run dev
```

### Or build and run:
```bash
npm run build
npm start
```

### Or run the test command:
```bash
npm test
```

## What to Expect

1. **Client Output**:
   - Login confirmation
   - Post creation with URI and CID
   - Instructions for manual verification

2. **In Your Deployed Stack**:
   - **Automod logs**: Should show GTUBE rule triggering
   - **Ozone**: Record should appear with spam label
   - **Hepa**: Message should be processed through the pipeline
   - **Slack**: Notification should be sent (if configured)

## Manual Verification Steps

1. **Check automod logs** for the GTUBE rule triggering
2. **Check Ozone interface** for the labeled record
3. **Check Slack notifications** (if configured)
4. **Verify record tags** include "gtube-flash"
5. **Confirm spam label** is applied

## Troubleshooting

### Authentication Issues
- Ensure your PDS URL is correct
- Use an app password, not your main account password
- Verify your handle/DID is correct

### Post Creation Issues
- Check that your PDS supports the `app.flashes.feed.post` collection
- Verify the lexicon schema is properly registered
- Ensure you have write permissions

### Moderation Not Working
- Confirm your automod instance is processing the firehose
- Check that the GtubeFlashRule is enabled in your ruleset
- Verify the collection prefix matching in the rule

## Example Output

```
🚀 Starting Flashes Test Client...
🌐 PDS URL: https://your-pds.com
👤 User: alice.bsky.social

🔐 Logging in as alice.bsky.social...
✅ Successfully logged in!

🧪 Testing GTUBE moderation rule...
📋 Message contains GTUBE test string: XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
📝 Creating flash post with text: "Testing automod with GTUBE string: XJS*C4JDBQADN1..."
✅ Flash post created successfully!
   URI: at://did:plc:abc123/app.flashes.feed.post/3l2uygozqt522
   CID: bafyreif5uqxwm7hdpliinzwba4lh2cp2edvitrlmrwb3qxcbqlyb4ua6my

📊 Test Results:
================
✅ Post created successfully
🔗 URI: at://did:plc:abc123/app.flashes.feed.post/3l2uygozqt522
🆔 CID: bafyreif5uqxwm7hdpliinzwba4lh2cp2edvitrlmrwb3qxcbqlyb4ua6my

🔍 Next Steps:
==============
1. Check your deployed automod instance logs
2. Verify the message appears in hepa + ozone
3. Confirm the gtube-flash label is applied
4. Look for Slack notifications if configured
```

## Related Files

- **Lexicon**: `atproto/lexicons/app/flashes/feed/post.json`
- **Go API**: `indigo/api/flashes/feedpost.go`
- **GTUBE Rule**: `indigo/automod/rules/gtube.go`
- **Lexgen Config**: `indigo/cmd/lexgen/flashes.json`