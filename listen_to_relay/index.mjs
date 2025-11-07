import { Firehose } from "@skyware/firehose";

const relay = process.argv[2];
if (!relay) {
	console.error("Usage: node index.mjs <relay-url>");
	process.exit(1);
}

const firehose = new Firehose({ relay  });

firehose.on("commit", (commit) => {
	for (const op of commit.ops) {
		if (op.action === "create" && op.path.includes("app.bsky.feed.post")) {
			console.log("\n🆕 New Post:");
			console.log("  Author:", commit.repo);
			console.log("  Text:", op.record.text);
			console.log("  Time:", commit.time);
			if (op.record.reply) {
				console.log("  💬 Reply to:", op.record.reply.parent.uri);
			}
		} else if (op.action === "create" && op.path.includes("app.bsky.feed.like")) {
			console.log("\n❤️  Like:", commit.repo, "→", op.record.subject.uri);
		} else if (op.action === "create" && op.path.includes("app.bsky.graph.follow")) {
			console.log("\n👤 Follow:", commit.repo, "→", op.record.subject);
		}
	}
});

firehose.on("open", () => console.log("✅ Connected to relay"));
firehose.on("error", ({ error }) => console.error("❌ Error:", error.message));

firehose.start();