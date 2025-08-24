#!/usr/bin/env node

// Ozone Flashes Toolkit entrypoint
// See README.md for available scripts.

console.log("Flash Post Testing Scripts");
console.log("==========================");
console.log();
console.log("Creating posts:");
console.log("- ts-node src/create_flash_post.ts                # Normal text post");
console.log("- ts-node src/create_flash_post.ts --gtube        # GTUBE spam test post");
console.log("- ts-node src/create_flash_post.ts --image dog.jpg # Safe image post");
console.log("- ts-node src/create_flash_post.ts --image kids.jpg # CSAM test image post");
console.log("- ts-node src/create_flash_post.ts --text 'Custom text' --gtube # Custom text with GTUBE");
console.log();
console.log("Reporting and checking:");
console.log("- ts-node src/report_flash_post.ts <uri> <cid>    # Create moderation report");
console.log("- ts-node src/get_ozone_events.ts                 # Get last 50 events");
console.log("- ts-node src/get_ozone_events.ts --reports       # Get last 50 reports only");
console.log("- ts-node src/get_ozone_events.ts --id <id>       # Get specific event by ID");
console.log("- ts-node src/get_ozone_events.ts --subject <uri> # Get events for specific post");
console.log();
console.log("Fetching and hashing a flash post's image blob:");
console.log("- ts-node src/get_flash_post.ts --did <did> --rkey <rkey> # Fetch and hash image blob");
console.log();
console.log("Examples:");
console.log("- ts-node src/get_ozone_events.ts --id 4523");
console.log("- ts-node src/get_ozone_events.ts --subject 'at://did:plc:abc/app.flashes.feed.post/123'");
console.log("- ts-node src/get_flash_post.ts --did did:plc:autcqcg4hsvgdf3hwt4cvci3 --rkey 3lx5ilffuul24");
