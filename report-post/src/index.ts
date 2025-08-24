#!/usr/bin/env node

console.log("Flash Post Testing Scripts");
console.log("==========================");
console.log();
console.log("Creating posts:");
console.log("- ts-node src/create_flash_test_post.ts           # Normal text post");
console.log("- ts-node src/create_flash_test_post.ts --gtube   # GTUBE spam test post");
console.log("- ts-node src/create_flash_test_image_post.ts dog.jpg    # Safe image post");
console.log("- ts-node src/create_flash_test_image_post.ts kids.jpg   # CSAM test image post");
console.log();
console.log("Reporting and checking:");
console.log("- ts-node src/report_flash_post.ts <uri> <cid>    # Create moderation report");
console.log("- ts-node src/get_ozone_events.ts                 # Get last 50 events");
console.log("- ts-node src/get_ozone_events.ts --reports       # Get last 50 reports only");
console.log("- ts-node src/get_ozone_events.ts --id <id>       # Get specific event by ID");
console.log("- ts-node src/get_ozone_events.ts --subject <uri> # Get events for specific post");
console.log();
console.log("Examples:");
console.log("- ts-node src/get_ozone_events.ts --id 4523");
console.log("- ts-node src/get_ozone_events.ts --subject 'at://did:plc:abc/app.flashes.feed.post/123'");
