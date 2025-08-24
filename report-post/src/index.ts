#!/usr/bin/env node

console.log("Available scripts:");
console.log("- ts-node src/create_flash_test_post.ts [--gtube]");
console.log("- ts-node src/create_flash_test_image_post.ts <image-filename>");
console.log("- ts-node src/report_flash_post.ts <uri> <cid>");
console.log();
console.log("Examples:");
console.log("- ts-node src/create_flash_test_post.ts           # Normal post");
console.log("- ts-node src/create_flash_test_post.ts --gtube   # GTUBE test post");
console.log("- ts-node src/create_flash_test_image_post.ts dog.jpg");
console.log("- ts-node src/create_flash_test_image_post.ts kids.jpg");
