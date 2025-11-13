
# Ozone Flashes Toolkit

A TypeScript CLI toolkit for testing the integration of Flashes events on the AT Protocol (Bluesky) and Ozone moderation service.

## Features

- **Create test posts:**
  - Image-based posts (stories must include images). Use `spam.jpg` for spam detection testing.
- **Test spam image detection:**
  - Perceptual hash-based spam image detection using reference image `spam.jpg`.
- **Report posts:**
  - File moderation reports with specific reasons.
- **Query moderation events:**
  - Fetch and filter recent moderation/reporting events from Ozone.
- **Query labels:**
  - Query labels using `com.atproto.label.queryLabels` API.
- **Subscribe to label stream:**
  - Real-time WebSocket subscription to label events using `com.atproto.label.subscribeLabels`.

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

All commands use `npm exec tsx` to run TypeScript files directly without requiring a global installation.

### Create posts

**Note:** Flashes stories must include an image - text-only stories are not supported.

- Spam test image (for perceptual hash detection):
    ```bash
    npm exec tsx src/create_flash_post.ts -- --image spam.jpg
    ```
- Custom text with image:
    ```bash
    npm exec tsx src/create_flash_post.ts -- --image spam.jpg --text "Custom text"
    ```

### Report a post

```bash
npm exec tsx src/report_flash_post.ts -- $uri $cid --reasonType $type [--reason "description"]
```

- `<uri>`: AT URI of the post (e.g., `at://did:plc:.../app.bsky.feed.post/abc123`)
- `<cid>`: Content ID of the post
- `<type>`: Reason type (see below)

### Query moderation events

- Last 50 events:
    ```bash
    npm exec tsx src/get_ozone_events.ts
    ```
- Only reports:
    ```bash
    npm exec tsx src/get_ozone_events.ts -- --reports
    ```
- By event ID:
    ```bash
    npm exec tsx src/get_ozone_events.ts -- --id <id>
    ```
- By subject URI:
    ```bash
    npm exec tsx src/get_ozone_events.ts -- --subject <uri>
    ```

### Query labels

Query labels from Ozone using the `com.atproto.label.queryLabels` API:

```bash
npm exec tsx src/query_labels.ts -- --uriPatterns <pattern1> [<pattern2> ...]
```

- `--uriPatterns`: One or more URI patterns to query (e.g., `at://did:plc:*/app.flashes.feed.post/*`)
- `--sources` (optional): Filter by label source DIDs
- `--limit` (optional): Maximum number of labels to return

**Example:**

```bash
npm exec tsx src/query_labels.ts -- --uriPatterns "at://did:plc:autcqcg4hsvgdf3hwt4cvci3/*"
```

### Subscribe to label stream

Subscribe to real-time label events using WebSocket connection to `com.atproto.label.subscribeLabels`:

```bash
npm exec tsx src/subscribe_labels.ts -- [--cursor <cursor>]
```

- `--cursor` (optional): Start from specific cursor position (default: 0)

The script will maintain a WebSocket connection and print all label events as they arrive.

**Example:**

```bash
npm exec tsx src/subscribe_labels.ts -- --cursor 0
```

### Fetch and hash a flash post's image blob

Use the `get_flash_post.ts` script to fetch a flash post by DID and rkey, validate its structure, extract the image blob, and print its SHA256 hash.

```bash
npm exec tsx src/get_flash_post.ts -- --did <did> --rkey <rkey>
```

- `--did`: The DID of the user (e.g., `did:plc:autcqcg4hsvgdf3hwt4cvci3`)
- `--rkey`: The record key of the post (e.g., `3lx5ilffuul24`)

The script will:
- Validate arguments and the post payload with zod
- Print the post record
- Extract and follow redirects to fetch the image blob
- Print the SHA256 hash of the blob

**Example:**

```bash
npm exec tsx src/get_flash_post.ts -- --did did:plc:autcqcg4hsvgdf3hwt4cvci3 --rkey 3lx5ilffuul24
```

If the post or blob is invalid, errors will be printed with details.

## Reason Types

- `com.atproto.moderation.defs#reasonSpam` - Spam content
- `com.atproto.moderation.defs#reasonViolation` - Community guideline violation
- `com.atproto.moderation.defs#reasonMisleading` - Misleading information
- `com.atproto.moderation.defs#reasonSexual` - Unwanted sexual content
- `com.atproto.moderation.defs#reasonRude` - Rude or harassing behavior
- `com.atproto.moderation.defs#reasonOther` - Other issues

## Requirements

- Node.js (v18 or higher recommended)
- AT Protocol/Bluesky account with app password
- Access to an Ozone moderation service

## Spam Image Detection

The toolkit includes `spam.jpg` as a reference image for testing perceptual hash-based spam detection in the HEPA automod service.

### How it works

- HEPA computes a perceptual hash (AverageHash) of the reference spam image (`spam.jpg`)
- Incoming images in `app.flashes.story` posts are hashed and compared using Hamming distance
- Images with hash distance ≤ threshold (default: 15 bits) are flagged as spam
- Detection triggers: spam label (`spam`), account tag (`spam-image-posted`), record tag (`spam-image-detected`), and moderation report

### Testing spam detection

1. Configure HEPA with spam image path (default in Docker: `/data/hepa/spam.jpg`):
   ```bash
   export HEPA_SPAM_IMAGE_PATH=/path/to/ozone-flashes-toolkit/spam.jpg
   export HEPA_SPAM_HASH_THRESHOLD=15
   ```

2. Post a story with the spam image:
   ```bash
   npm exec tsx src/create_flash_post.ts -- --image spam.jpg
   ```

3. Check for spam detection events in Ozone:
   ```bash
   npm exec tsx src/get_ozone_events.ts
   ```

### Test Images

- `spam.jpg` - Reference spam image (187K, hash: `a:ffd304008187cfcf`)

Additional test images for integration tests are located in `indigo/testing/`:

- `spam-also.jpg` - Matches reference (distance=12, should trigger detection)
- `spam-not.jpg` - Different image (distance=21, should NOT trigger detection)

## Finding Post URIs

Post URIs follow the format: `at://[author-did]/app.bsky.feed.post/[post-rkey]`

You can find these in:

- Bluesky web URLs (convert from `https://bsky.app/profile/handle/post/rkey`)
- API responses
- Firehose data streams
