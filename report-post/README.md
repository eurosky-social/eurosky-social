# Post Reporter for Ozone

A TypeScript script to report specific posts to an Ozone moderation service.

## Setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Create environment configuration:

   ```bash
   cp .env.example .env
   ```

3. Edit `.env` file with your configuration:
   - `OZONE_URL` - Your Ozone instance URL
   - `USERNAME` - Your AT Protocol handle  
   - `PASSWORD` - Your app password (not main password)
   - `POST_URI` - AT-URI of the post to report (e.g., `at://did:plc:example/app.bsky.feed.post/abc123`)
   - `POST_CID` - Optional: specific version CID
   - `REASON_TYPE` - Violation reason (see available types below)
   - `REASON_TEXT` - Description of the issue

## Available Reason Types

- `com.atproto.moderation.defs#reasonSpam` - Spam content
- `com.atproto.moderation.defs#reasonViolation` - Community guideline violation
- `com.atproto.moderation.defs#reasonMisleading` - Misleading information
- `com.atproto.moderation.defs#reasonSexual` - Unwanted sexual content
- `com.atproto.moderation.defs#reasonRude` - Rude or harassing behavior
- `com.atproto.moderation.defs#reasonOther` - Other issues
- `com.atproto.moderation.defs#reasonAppeal` - Appeal a moderation decision

## Usage

### Development (with ts-node):
```bash
npm run dev
```

### Production build:
```bash
npm run build
npm start
```

## Finding Post URIs

Post URIs follow the format: `at://[author-did]/app.bsky.feed.post/[post-rkey]`

You can find these in:
- Bluesky web URLs (convert from `https://bsky.app/profile/handle/post/rkey`)
- API responses
- Firehose data streams