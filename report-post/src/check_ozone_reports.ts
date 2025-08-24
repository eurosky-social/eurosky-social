#!/usr/bin/env node

import { createOzoneAdminAgent } from "./auth";

async function main(): Promise<void> {
  const reportId = process.argv[2];
  const showAll = process.argv.includes('--all');
  
  if (!reportId && !showAll) {
    console.error("Usage:");
    console.error("  ts-node src/check_ozone_reports.ts <report-id>");
    console.error("  ts-node src/check_ozone_reports.ts --all");
    console.error("");
    console.error("Examples:");
    console.error("  ts-node src/check_ozone_reports.ts 4523");
    console.error("  ts-node src/check_ozone_reports.ts --all");
    process.exit(1);
  }

  const agent = await createOzoneAdminAgent();

  if (showAll) {
    const response = await agent.api.tools.ozone.moderation.queryEvents({
      limit: 20,
      types: ['tools.ozone.moderation.defs#modEventReport'],
    });
    
    console.log(JSON.stringify(response.data.events, null, 2));
    
  } else {
    try {
      // Try to get the specific event by ID
      const response = await agent.api.tools.ozone.moderation.getEvent({
        id: parseInt(reportId),
      });
      
      console.log(JSON.stringify(response.data, null, 2));
    } catch (error: any) {
      if (error.status === 404) {
        console.log(JSON.stringify({ error: `Report ${reportId} not found` }, null, 2));
      } else {
        console.log(JSON.stringify({ error: `Failed to fetch report ${reportId}: ${error.message}` }, null, 2));
      }
      process.exit(1);
    }
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});