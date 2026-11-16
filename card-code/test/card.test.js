'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const {
  beforeTransaction,
  afterTransaction,
  afterDecline,
  resolveCategory,
  maskAccount,
  DEFAULT_MERCHANT_RULES
} = require('../main');
const { runStress } = require('../tools/stress');

const rulesPath = path.join(__dirname, '..', '..', 'shared', 'merchant-rules.json');
const exampleEnvPath = path.join(__dirname, '..', 'env.example.json');

function setBudget(map, extra) {
  process.env.VAULT_BUDGET_JSON = JSON.stringify(map);
  process.env.VAULT_MERCHANT_RULES = '';
  process.env.VAULT_CATEGORY_KEYS = '';
  process.env.VAULT_FALLBACK_TX_LIMIT_CENTS = '50000';
  delete process.env.VAULT_WEBHOOK_URL;
  if (extra) Object.assign(process.env, extra);
}

test('default merchant rules match shared/merchant-rules.json', () => {
  const shared = JSON.parse(fs.readFileSync(rulesPath, 'utf8'));
  assert.deepEqual(
    DEFAULT_MERCHANT_RULES,
    shared.keywords.map((row) => [row.match, row.category])
  );
});

test('beforeTransaction does not call fetch', async () => {
  setBudget({ groceries: 50000, shopping: 0 });
  let called = false;
  global.fetch = async () => {
    called = true;
    throw new Error('fetch must not run inside beforeTransaction');
  };
  const approved = await beforeTransaction({
    centsAmount: 20000,
    merchant: { name: 'Woolworths Sandton' }
  });
  assert.equal(approved, true);
  assert.equal(called, false);
});

test('beforeTransaction source does not reference the network', () => {
  const src = fs.readFileSync(path.join(__dirname, '..', 'main.js'), 'utf8');
  const start = src.indexOf('const beforeTransaction');
  const end = src.indexOf('function maskAccount');
  const body = src.slice(start, end);
  assert.equal(body.includes('fetch'), false);
  assert.equal(body.includes('http'), false);
  assert.equal(body.includes('require('), false);
});

test('approves a grocery swipe inside the remaining budget', async () => {
  setBudget({ groceries: 40000, shopping: 0 });
  const approved = await beforeTransaction({
    centsAmount: '25000',
    merchant: { name: 'Checkers Hyper' }
  });
  assert.equal(approved, true);
});

test('declines a category that has no remaining budget', async () => {
  setBudget({ groceries: 40000, shopping: 0, eating_out: 10000 });
  const declined = await beforeTransaction({
    centsAmount: 15000,
    merchant: { name: 'Nandos Sandton' }
  });
  assert.equal(declined, false);
  const stillOpen = await beforeTransaction({
    centsAmount: 8000,
    merchant: { name: 'Kauai' }
  });
  assert.equal(stillOpen, true);
});

test('sandbox description shapes map through the shared table', () => {
  setBudget({});
  assert.equal(resolveCategory({ merchant: { name: 'VODACOM 0401' } }), 'subscriptions');
  assert.equal(resolveCategory({ merchant: { name: 'TAKEALO*T CAPE TOWN ZA' } }), 'shopping');
  assert.equal(resolveCategory({ merchant: { name: 'SUPERSPAR KURUMAN' } }), 'groceries');
  assert.equal(resolveCategory({ merchant: { name: 'STANCOM 352Kjoe.smith' } }), 'income');
});

test('uber eats is eating out and does not match the trip rule', () => {
  setBudget({});
  assert.equal(resolveCategory({ merchant: { name: 'Uber Eats' } }), 'eating_out');
  assert.equal(resolveCategory({ merchant: { name: 'Uber Trip' } }), 'transport');
});

test('merchant category key from the authorisation wins over the name', () => {
  setBudget({});
  assert.equal(resolveCategory({
    merchant: { name: 'The Coders Bakery', category: { key: 'bakeries' } }
  }), 'eating_out');
});

test('unknown merchants use the fallback per-swipe cap', async () => {
  setBudget({ groceries: 10 });
  const small = await beforeTransaction({
    centsAmount: 40000,
    merchant: { name: 'Corner Cafe' }
  });
  const large = await beforeTransaction({
    centsAmount: 60000,
    merchant: { name: 'Corner Cafe' }
  });
  assert.equal(small, true);
  assert.equal(large, false);
});

test('a missing or broken budget fails closed above the fallback and open below it', async () => {
  process.env.VAULT_BUDGET_JSON = '{not json';
  process.env.VAULT_FALLBACK_TX_LIMIT_CENTS = '50000';
  assert.equal(await beforeTransaction({ centsAmount: 1000, merchant: { name: 'Woolworths' } }), true);
  assert.equal(await beforeTransaction({ centsAmount: 90000, merchant: { name: 'Woolworths' } }), false);
});

test('negative and non-numeric amounts are declined', async () => {
  setBudget({ groceries: 100000 });
  assert.equal(await beforeTransaction({ centsAmount: -5, merchant: { name: 'Woolworths' } }), false);
  assert.equal(await beforeTransaction({ centsAmount: 'nope', merchant: { name: 'Woolworths' } }), false);
});

test('env merchant rules override the built-in table', async () => {
  setBudget({ pets: 1000 }, { VAULT_MERCHANT_RULES: 'woolworths:pets' });
  assert.equal(resolveCategory({ merchant: { name: 'Woolworths' } }), 'pets');
  assert.equal(await beforeTransaction({ centsAmount: 500, merchant: { name: 'Woolworths' } }), true);
  assert.equal(await beforeTransaction({ centsAmount: 2000, merchant: { name: 'Woolworths' } }), false);
});

test('afterTransaction posts a masked payload and never the raw account number', async () => {
  setBudget({ groceries: 80000 });
  const calls = [];
  global.fetch = async (url, opts) => {
    calls.push({ url, body: JSON.parse(opts.body) });
    return { ok: true, status: 202 };
  };
  process.env.VAULT_WEBHOOK_URL = 'http://127.0.0.1:8787/vault/events';
  const payload = await afterTransaction({
    accountNumber: '10010020001',
    centsAmount: 22000,
    currencyCode: 'ZAR',
    reference: 'simulation',
    merchant: { name: 'Woolworths Sandton' }
  });
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, process.env.VAULT_WEBHOOK_URL);
  const encoded = JSON.stringify(calls[0].body);
  assert.equal(encoded.includes('10010020001'), false);
  assert.equal(payload.accountMasked, '****0001');
  assert.equal(payload.hook, 'afterTransaction');
  assert.equal(payload.approved, true);
  assert.equal(payload.category, 'groceries');
  assert.equal(maskAccount('10010020001'), '****0001');
});

test('afterDecline records the decline and survives a dead webhook', async () => {
  setBudget({ shopping: 0 });
  global.fetch = async () => {
    throw new Error('connection refused');
  };
  process.env.VAULT_WEBHOOK_URL = 'http://127.0.0.1:9/vault/events';
  const payload = await afterDecline({
    accountNumber: '10010020001',
    centsAmount: 90000,
    merchant: { name: 'Takealot' },
    reference: 'simulation'
  });
  assert.equal(payload.approved, false);
  assert.equal(payload.hook, 'afterDecline');
  assert.equal(payload.category, 'shopping');
});

test('example env has placeholders and no credential fields', () => {
  const env = JSON.parse(fs.readFileSync(exampleEnvPath, 'utf8'));
  assert.equal(env.VAULT_WEBHOOK_URL.startsWith('http://127.0.0.1'), true);
  assert.equal(Object.keys(env).some((key) => /secret|api[_-]?key|client/i.test(key)), false);
  const budget = JSON.parse(env.VAULT_BUDGET_JSON);
  assert.equal(budget.shopping, 0);
  assert.ok(budget.groceries > 0);
});

test('stress replay both approves and declines', async () => {
  const env = JSON.parse(fs.readFileSync(exampleEnvPath, 'utf8'));
  Object.keys(env).forEach((key) => {
    process.env[key] = env[key];
  });
  delete process.env.VAULT_WEBHOOK_URL;
  const result = await runStress({ seed: 7, days: 10, swipesPerDay: 2 });
  assert.equal(result.events.length, 20);
  assert.ok(result.approvedCount > 0);
  assert.ok(result.declinedCount > 0);
  assert.equal(JSON.stringify(result).includes('10010020001'), false);
});
