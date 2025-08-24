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
console.log("- ts-node src/check_ozone_reports.ts <id|--all>   # Check reports by ID or list all");
console.log("- ts-node src/check_moderation_events.ts <uri|--all> # Check events for post or list all");
console.log();
console.log("Examples:");
console.log("- ts-node src/check_ozone_reports.ts 4523");
console.log("- ts-node src/check_moderation_events.ts 'at://did:plc:abc/app.flashes.feed.post/123'");
