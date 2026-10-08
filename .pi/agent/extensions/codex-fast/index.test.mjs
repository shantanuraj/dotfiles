import assert from 'node:assert/strict';
import test from 'node:test';
import register from './index.ts';

function harness() {
  const handlers = new Map();
  const commands = new Map();
  const entries = [];
  const notifications = [];
  const statuses = new Map();
  const ctx = {
    hasUI: true,
    model: {
      provider: 'openai-codex',
      api: 'openai-codex-responses',
      id: 'test-codex',
    },
    sessionManager: { getBranch: () => entries },
    ui: {
      setStatus: (key, value) => statuses.set(key, value),
      notify: (message, level) => notifications.push({ message, level }),
    },
  };
  const pi = {
    on: (name, handler) => handlers.set(name, handler),
    registerCommand: (name, command) => commands.set(name, command),
    appendEntry: (customType, data) =>
      entries.push({ type: 'custom', customType, data }),
  };
  register(pi);
  return {
    ctx,
    entries,
    notifications,
    statuses,
    reload: () => register(pi),
    emit: (name, event = {}) => handlers.get(name)(event, ctx),
    command: (args) => commands.get('fast').handler(args, ctx),
    request: (payload = { model: ctx.model?.id }) =>
      handlers.get('before_provider_request')({ payload }, ctx),
  };
}

test('starts off and status does not change the session', async () => {
  const h = harness();
  h.emit('session_start');
  assert.equal(h.request(), undefined);
  await h.command('status');
  assert.equal(h.entries.length, 0);
  assert.equal(h.notifications.at(-1).message, 'Fast mode off.');
});

test('toggles priority without mutating other request fields', async () => {
  const h = harness();
  const payload = Object.freeze({
    model: h.ctx.model.id,
    input: [{ role: 'user', content: 'hello' }],
    reasoning: { effort: 'xhigh' },
    prompt_cache_key: 'cache-key',
    service_tier: 'default',
  });
  await h.command('');
  assert.deepEqual(h.request(payload), {
    ...payload,
    service_tier: 'priority',
  });
  assert.equal(payload.service_tier, 'default');
  assert.equal(h.statuses.get('codex-fast'), 'fast: on');
  assert.match(h.notifications.at(-1).message, /higher cost or quota/);
  await h.command('');
  assert.equal(h.request(payload), undefined);
  assert.equal(h.statuses.get('codex-fast'), undefined);
});

test('on and off are idempotent and validate arguments', async () => {
  const h = harness();
  await h.command(' ON ');
  await h.command('on');
  await h.command('status');
  assert.equal(h.entries.length, 1);
  await h.command('invalid');
  assert.equal(h.notifications.at(-1).level, 'error');
  assert.equal(h.entries.length, 1);
  assert.equal(h.request().service_tier, 'priority');
  await h.command('off');
  await h.command('off');
  assert.equal(h.entries.length, 2);
  assert.equal(h.request(), undefined);
});

test('restores branch state on reload and resets for a new session', async () => {
  const h = harness();
  await h.command('on');
  h.reload();
  h.emit('session_start', { reason: 'reload' });
  assert.equal(h.request().service_tier, 'priority');
  await h.command('off');
  h.emit('session_start', { reason: 'resume' });
  assert.equal(h.request(), undefined);
  h.entries.pop();
  h.emit('session_tree');
  assert.equal(h.request().service_tier, 'priority');
  h.entries.push({ type: 'custom', customType: 'codex-fast', data: 'invalid' });
  h.entries.push({ type: 'custom', customType: 'unrelated', data: false });
  h.emit('session_start', { reason: 'fork' });
  assert.equal(h.request().service_tier, 'priority');
  h.entries.length = 0;
  h.emit('session_start', { reason: 'new' });
  assert.equal(h.request(), undefined);
});

test('pauses for other providers and allows disabling there', async () => {
  const h = harness();
  await h.command('on');
  h.ctx.model.provider = 'anthropic';
  h.emit('model_select');
  assert.equal(h.request(), undefined);
  assert.equal(h.statuses.get('codex-fast'), 'fast: paused');
  await h.command('status');
  assert.match(h.notifications.at(-1).message, /paused/);
  h.ctx.model.provider = 'openai-codex';
  h.emit('model_select');
  assert.equal(h.request().service_tier, 'priority');
  h.ctx.model.provider = 'openai';
  await h.command('off');
  assert.equal(h.statuses.get('codex-fast'), undefined);
  await h.command('on');
  assert.equal(h.notifications.at(-1).level, 'error');
  assert.equal(h.entries.length, 2);
});

test('ignores unsupported APIs, absent models and unrelated payloads', async () => {
  const h = harness();
  await h.command('on');
  for (const payload of [null, false, 42, 'text', [], {}, { model: 'other' }]) {
    assert.equal(h.request(payload), undefined);
  }
  h.ctx.model.api = 'openai-completions';
  assert.equal(h.request(), undefined);
  await h.command('on');
  assert.equal(h.notifications.at(-1).level, 'error');
  h.ctx.model = undefined;
  assert.equal(h.request(), undefined);
});

test('does not require a terminal UI to rewrite requests', async () => {
  const h = harness();
  h.ctx.hasUI = false;
  h.ctx.ui.setStatus = () => assert.fail('No terminal status expected');
  h.emit('session_start');
  await h.command('on');
  assert.equal(h.request().service_tier, 'priority');
});
