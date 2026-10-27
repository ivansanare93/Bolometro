// Node built-ins only. Fixed LOCAL demo endpoint; never uses app credentials.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const project = 'demo-bolometro-arsenal';
const root = `projects/${project}/databases/(default)/documents`;
const url = `http://127.0.0.1:8787/v1/${root}`;
function value(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, value(x)])) } };
}
function token(uid) {
  const encode = (v) => Buffer.from(JSON.stringify(v)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: `https://securetoken.google.com/${project}`, aud: project,
    sub: uid, user_id: uid, iat: now, exp: now + 3600, auth_time: now,
    firebase: { sign_in_provider: 'custom' },
  })}.`;
}
async function request(method, path, uid, data) {
  const response = await fetch(url + path, {
    method, headers: { 'Content-Type': 'application/json',
      ...(uid ? { Authorization: `Bearer ${token(uid)}` } : {}) },
    ...(data ? { body: JSON.stringify(data) } : {}), signal: AbortSignal.timeout(15000),
  });
  return { status: response.status, body: await response.json() };
}
function fixture() {
  const uid = `test-${randomUUID()}`;
  let parent = `users/${uid}/balls/ball`;
  let payload = { id: 'ball', name: 'Test ball', brand: null, weightLbs: 15,
    coverstock: null, finish: null, purchaseDate: null, isActive: true, notes: null,
    createdAt: '2026-01-01T00:00:00.000Z', updatedAt: '2026-01-01T00:00:00.000Z' };
  const envelope = (args = {}) => ({ id: 'ball', revision: 1, baseRevision: 0,
    operationId: 'one', kind: 'accepted', payload, ...args });
  const write = (path, data) => ({ update: { name: `${root}/${path}`,
    fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)])) },
    updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }] });
  const commit = (data = envelope(), user = uid, includeParent = true) =>
    request('POST', ':commit', user, { writes: [
      ...(includeParent ? [write(parent, data)] : []),
      write(`${parent}/revisions/${data.operationId}`, data),
    ] });
  const seed = async () => { const r = await commit(); assert.equal(r.status, 200, JSON.stringify(r.body)); };
  const maintenance = (ballId = 'ball') => {
    parent = `users/${uid}/ball_maintenance/ball`;
    payload = { id: 'ball', ballId, type: 'cleaning', date: '2026-01-01T00:00:00.000Z', notes: null };
  };
  return { uid, get parent() { return parent; }, get payload() { return payload; },
    envelope, write, commit, seed, maintenance };
}
test('owner creates, reads and updates with a new revision', async () => {
  const f = fixture(); await f.seed();
  assert.equal((await request('GET', `/${f.parent}`, f.uid)).status, 200);
  const r = await f.commit(f.envelope({ operationId: 'two', baseRevision: 1, revision: 2,
    payload: { ...f.payload, notes: 'Updated' } }));
  assert.equal(r.status, 200, JSON.stringify(r.body));
});
test('other account cannot read or write arsenal', async () => {
  const f = fixture(); await f.seed();
  assert.equal((await request('GET', `/${f.parent}`, 'other')).status, 403);
  assert.equal((await f.commit(f.envelope({ operationId: 'other', baseRevision: 1, revision: 2 }), 'other')).status, 403);
});
test('unauthenticated access denied', async () => {
  const f = fixture(); await f.seed();
  assert.equal((await request('GET', `/${f.parent}`)).status, 403);
});
test('history is private and immutable', async () => {
  const f = fixture(); await f.seed(); const path = `/${f.parent}/revisions/one`;
  assert.equal((await request('GET', path, 'other')).status, 403);
  assert.equal((await request('DELETE', path, f.uid)).status, 403);
  assert.equal((await f.commit()).status, 403);
});
test('canonical document cannot be deleted', async () => {
  const f = fixture(); await f.seed();
  assert.equal((await request('DELETE', `/${f.parent}`, f.uid)).status, 403);
});
test('stale revision cannot overwrite', async () => {
  const f = fixture(); await f.seed();
  assert.equal((await f.commit(f.envelope({ operationId: 'stale' }))).status, 403);
});
test('rejected conflict is retained without changing canonical payload', async () => {
  const f = fixture(); await f.seed();
  const before = (await request('GET', `/${f.parent}`, f.uid)).body;
  const r = await f.commit(f.envelope({ operationId: 'conflict', kind: 'conflict',
    payload: { ...f.payload, name: 'Offline variant' } }), f.uid, false);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.deepEqual((await request('GET', `/${f.parent}`, f.uid)).body, before);
});
test('canonical write requires matching immutable history', async () => {
  const f = fixture();
  const r = await request('POST', ':commit', f.uid, { writes: [f.write(f.parent, f.envelope())] });
  assert.equal(r.status, 403);
});
test('invalid payload rejected', async () => {
  const f = fixture();
  assert.equal((await f.commit(f.envelope({ payload: { ...f.payload, weightLbs: -1 } }))).status, 403);
});
test('maintenance requires ball in the same account', async () => {
  const f = fixture(); f.maintenance('missing');
  assert.equal((await f.commit()).status, 403);
});
test('owner can back up maintenance of an existing ball', async () => {
  const f = fixture(); await f.seed(); f.maintenance();
  const r = await f.commit(); assert.equal(r.status, 200, JSON.stringify(r.body));
});
