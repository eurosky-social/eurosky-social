// Using built-in fetch in modern Node.js

import { execSync } from 'child_process';

const output = execSync('docker compose port pds.internal 80').toString().trim();
const port = output.split(':').pop();
const PDS_URL = `http://localhost:${port}`;

async function createAccount(handle, password, email) {
  const response = await fetch(`${PDS_URL}/xrpc/com.atproto.server.createAccount`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      handle,
      password,
      email,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`Failed to create account ${handle}:`, error);
    return null;
  }

  const data = await response.json();
  console.log(`✅ Created account: ${handle}`);
  return data;
}

async function createSession(handle, password) {
  const response = await fetch(`${PDS_URL}/xrpc/com.atproto.server.createSession`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      identifier: handle,
      password,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`Failed to create session for ${handle}:`, error);
    return null;
  }

  const data = await response.json();
  console.log(`🔑 Created session for: ${handle}`);
  return data;
}

async function createPost(accessJwt, did, text) {
  const response = await fetch(`${PDS_URL}/xrpc/com.atproto.repo.createRecord`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessJwt}`,
    },
    body: JSON.stringify({
      repo: did,
      collection: 'app.bsky.feed.post',
      record: {
        text,
        createdAt: new Date().toISOString(),
        $type: 'app.bsky.feed.post',
      },
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`Failed to create post:`, error);
    return null;
  }

  const data = await response.json();
  console.log(`📝 Created post: "${text}"`);
  return data;
}

async function main() {
  console.log('🚀 Testing PDS with fresh users...\n');

  const id = Math.floor(Math.random() * 1000);

  // Create new test users with unique handles
  const alice = await createAccount(`alice${id}.test`, 'password123', `alice${id}@example.com`);
  if (!alice) return;

  const bob = await createAccount(`bob${id}.test`, 'password123', `bob${id}@example.com`);
  if (!bob) return;

  console.log('\n📱 Creating sessions...\n');

  // Create sessions
  const aliceSession = await createSession(`alice${id}.test`, 'password123');
  if (!aliceSession) return;

  const bobSession = await createSession(`bob${id}.test`, 'password123');
  if (!bobSession) return;

  console.log('\n✍️ Creating posts to test relay integration...\n');

  // Create posts that should appear in the relay firehose
  const posts = [
    { user: 'alice', text: `🎯 Fresh test post from Alice at ${new Date().toISOString()}` },
    { user: 'bob', text: `🔥 Bob testing the relay firehose at ${new Date().toISOString()}` },
    { user: 'alice', text: '🚀 Testing AT Protocol local development environment!' },
    { user: 'bob', text: '📡 Can the relay see this message from the PDS?' },
    { user: 'alice', text: '⚡ Real-time data flowing through the AT Protocol stack!' },
    { user: 'bob', text: '🌊 Firehose should be streaming these posts now!' },
  ];

  for (const post of posts) {
    const session = post.user === 'alice' ? aliceSession : bobSession;
    const did = post.user === 'alice' ? alice.did : bob.did;

    await createPost(session.accessJwt, did, post.text);

    // Small delay between posts for better relay processing
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  console.log('\n🎉 Test completed successfully!');
  console.log('\n📊 New users created:');
  console.log(`- alice${id}.test (${alice.did})`);
  console.log(`- bob${id}.test (${bob.did})`);

  console.log('\n🔥 These posts should now be flowing through the relay!');
  console.log(`🎯 Check relay at: http://localhost:65458/_health`);
  console.log(`📡 Firehose endpoint: ws://localhost:61717/xrpc/com.atproto.sync.subscribeRepos`);
}

main().catch(console.error);