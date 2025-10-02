
# Ozone Flashes Toolkit

A TypeScript CLI toolkit for testing the integration of Flashes events on the AT Protocol (Bluesky) and Ozone moderation service.

## Features

- **Create test posts:**
  - Normal text, GTUBE spam, or image-based posts (see `dog.jpg`, `kids.jpg`).
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

All commands use `npm exec ts-node` to run TypeScript files directly without requiring a global installation.

### Create posts

- Normal:
    ```bash
    npm exec ts-node src/create_flash_post.ts
    ```
- GTUBE spam:
    ```bash
    npm exec ts-node src/create_flash_post.ts -- --gtube
    ```
- Safe image:
    ```bash
    npm exec ts-node src/create_flash_post.ts -- --image dog.jpg
    ```
- CSAM test image:
    ```bash
    npm exec ts-node src/create_flash_post.ts -- --image kids.jpg
    ```
- Custom text:
    ```bash
    npm exec ts-node src/create_flash_post.ts -- --text "Custom text"
    ```

### Report a post

```bash
npm exec ts-node src/report_flash_post.ts -- <uri> <cid> --reasonType <type> [--reason "description"]
```

- `<uri>`: AT URI of the post (e.g., `at://did:plc:.../app.bsky.feed.post/abc123`)
- `<cid>`: Content ID of the post
- `<type>`: Reason type (see below)

### Query moderation events

- Last 50 events:
    ```bash
    npm exec ts-node src/get_ozone_events.ts
    ```
- Only reports:
    ```bash
    npm exec ts-node src/get_ozone_events.ts -- --reports
    ```
- By event ID:
    ```bash
    npm exec ts-node src/get_ozone_events.ts -- --id <id>
    ```
- By subject URI:
    ```bash
    npm exec ts-node src/get_ozone_events.ts -- --subject <uri>
    ```

### Query labels

Query labels from Ozone using the `com.atproto.label.queryLabels` API:

```bash
npm exec ts-node src/query_labels.ts -- --uriPatterns <pattern1> [<pattern2> ...]
```

- `--uriPatterns`: One or more URI patterns to query (e.g., `at://did:plc:*/app.flashes.feed.post/*`)
- `--sources` (optional): Filter by label source DIDs
- `--limit` (optional): Maximum number of labels to return

**Example:**

```bash
npm exec ts-node src/query_labels.ts -- --uriPatterns "at://did:plc:autcqcg4hsvgdf3hwt4cvci3/*"
```

### Subscribe to label stream

Subscribe to real-time label events using WebSocket connection to `com.atproto.label.subscribeLabels`:

```bash
npm exec ts-node src/subscribe_labels.ts -- [--cursor <cursor>]
```

- `--cursor` (optional): Start from specific cursor position (default: 0)

The script will maintain a WebSocket connection and print all label events as they arrive.

**Example:**

```bash
npm exec ts-node src/subscribe_labels.ts -- --cursor 0
```

### Fetch and hash a flash post's image blob

Use the `get_flash_post.ts` script to fetch a flash post by DID and rkey, validate its structure, extract the image blob, and print its SHA256 hash.

```bash
npm exec ts-node src/get_flash_post.ts -- --did <did> --rkey <rkey>
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
npm exec ts-node src/get_flash_post.ts -- --did did:plc:autcqcg4hsvgdf3hwt4cvci3 --rkey 3lx5ilffuul24
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

## Finding Post URIs

Post URIs follow the format: `at://[author-did]/app.bsky.feed.post/[post-rkey]`

You can find these in:

- Bluesky web URLs (convert from `https://bsky.app/profile/handle/post/rkey`)
- API responses
- Firehose data streams
