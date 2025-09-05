import { Firehose } from "@skyware/firehose";

const relay = process.argv[2];
if (!relay) {
	console.error("Usage: node index.mjs <relay-url>");
	process.exit(1);
}

const firehose = new Firehose({ relay  });

const events = [
	"open",
	"close",
	"reconnect",
	"error",
	"websocketError",
	"commit",
	"sync",
	"account",
	"identity",
	"info",
	"unknown"
];

for (const event of events) {
	firehose.on(event, (message) => {
		console.log(JSON.stringify({ event, message }));
	});
}

firehose.start();