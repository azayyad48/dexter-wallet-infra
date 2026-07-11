const { test, before, after } = require("node:test");
const assert = require("node:assert");
const server = require("./server");

let baseUrl;

before(async () => {
  await new Promise((resolve) => server.listen(0, resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => server.close());

test("healthcheck returns 200", async () => {
  const res = await fetch(`${baseUrl}/healthz`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.status, "ok");
});

test("root returns service info", async () => {
  const res = await fetch(`${baseUrl}/`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.service, "wallet-api");
});

test("unknown route returns 404", async () => {
  const res = await fetch(`${baseUrl}/nope`);
  assert.strictEqual(res.status, 404);
});
