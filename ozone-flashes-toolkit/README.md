
# Ozone Flashes Toolkit

A TypeScript CLI toolkit for testing the integration of Flashes events on the AT Protocol (Bluesky) and Ozone moderation service.

## Features

- **Create test posts:**  
  - Normal text, GTUBE spam, or image-based posts (see `dog.jpg`, `kids.jpg`).
- **Report posts:**  
  - File moderation reports with specific reasons.
- **Query moderation events:**  
  - Fetch and filter recent moderation/reporting events from Ozone.

## Setup

1. **Install dependencies:**

    ```bash
    npm install
    ```

2. **Configure environment:**

    ```bash
    cp .env.example .env
    ```

    Edit `.env` with your credentials and service URLs.

## Usage

All commands use `ts-node` for development. Example commands:

- **Create posts:**
  - Normal:  
      `ts-node src/create_flash_post.ts`
  - GTUBE spam:  
      `ts-node src/create_flash_post.ts --gtube`
  - Safe image:  
      `ts-node src/create_flash_post.ts --image dog.jpg`
  - CSAM test image:  
      `ts-node src/create_flash_post.ts --image kids.jpg`
  - Custom text:  
      `ts-node src/create_flash_post.ts --text "Custom text"`

- **Report a post:**

   ```bash
   ts-node src/report_flash_post.ts <uri> <cid> --reasonType <type> [--reason "description"]
   ```

  - `<uri>`: AT URI of the post (e.g., `at://did:plc:.../app.bsky.feed.post/abc123`)
  - `<cid>`: Content ID of the post
  - `<type>`: Reason type (see below)

- **Query moderation events:**
  - Last 50 events:  
      `ts-node src/get_ozone_events.ts`
  - Only reports:  
      `ts-node src/get_ozone_events.ts --reports`
  - By event ID:  
      `ts-node src/get_ozone_events.ts --id <id>`
  - By subject URI:  
      `ts-node src/get_ozone_events.ts --subject <uri>`

## Reason Types

- `com.atproto.moderation.defs#reasonSpam` - Spam content
- `com.atproto.moderation.defs#reasonViolation` - Community guideline violation
- `com.atproto.moderation.defs#reasonMisleading` - Misleading information
- `com.atproto.moderation.defs#reasonSexual` - Unwanted sexual content
- `com.atproto.moderation.defs#reasonRude` - Rude or harassing behavior
- `com.atproto.moderation.defs#reasonOther` - Other issues

## Requirements

- Node.js
- TypeScript
- AT Protocol/Bluesky account with app password
- Access to an Ozone moderation service

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
