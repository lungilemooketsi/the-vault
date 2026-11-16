'use strict';

// Investec programmable card code for The Vault.
// beforeTransaction has a 2 second limit and must not call MATLAB or the network.
// It reads the budget MATLAB wrote into env.json. afterTransaction has 15 seconds
// and posts a masked event for the floor to consume.
//
// The default merchant table mirrors shared/merchant-rules.json. A card test
// fails if the two drift. Longer phrases are listed before shorter ones.

const DEFAULT_MERCHANT_RULES = [
  ['city of kuruman', 'municipal'],
  ['monthly service charge', 'fees'],
  ['debit interest', 'fees'],
  ['credit interest', 'income'],
  ['discovery medical', 'health'],
  ['pick n pay', 'groceries'],
  ['uber eats', 'eating_out'],
  ['mr d food', 'eating_out'],
  ['seattle coffee', 'eating_out'],
  ['sandton lease', 'rent'],
  ['total glencairn', 'transport'],
  ['kuruman refund', 'income'],
  ['weekly paym', 'income'],
  ['superspar', 'groceries'],
  ['kwikspar', 'groceries'],
  ['woolworths', 'groceries'],
  ['shoprite', 'groceries'],
  ['checkers', 'groceries'],
  ['ok express', 'groceries'],
  ['takealot', 'shopping'],
  ['takealo', 'shopping'],
  ['netflix', 'subscriptions'],
  ['spotify', 'subscriptions'],
  ['showmax', 'subscriptions'],
  ['youtube', 'subscriptions'],
  ['vodacom', 'subscriptions'],
  ['afrihost', 'subscriptions'],
  ['cellc', 'airtime'],
  ['mommed', 'health'],
  ['clicks', 'health'],
  ['dischem', 'health'],
  ['amazon', 'shopping'],
  ['mrp home', 'shopping'],
  ['nandos', 'eating_out'],
  ['kauai', 'eating_out'],
  ['sasol', 'transport'],
  ['engen', 'transport'],
  ['shell', 'transport'],
  ['caltex', 'transport'],
  ['uber trip', 'transport'],
  ['bolt trip', 'transport'],
  ['stansal', 'income'],
  ['stancom', 'income'],
  ['salary', 'income'],
  ['levy hoa', 'housing'],
  ['fnb h loan', 'housing'],
  ['nedbhl', 'housing'],
  ['aon sa', 'insurance'],
  ['momentum', 'insurance'],
  ['spar', 'groceries'],
  ['pnp', 'groceries'],
  ['cltx', 'transport'],
];

const DEFAULT_CATEGORY_KEYS = {
  bakeries: 'eating_out',
  groceries: 'groceries',
  eating_places_restaurants: 'eating_out',
  service_stations: 'transport'
};

function rulesFromEnv() {
  const raw = process.env.VAULT_MERCHANT_RULES;
  if (!raw || !String(raw).trim()) return sortRules(DEFAULT_MERCHANT_RULES);
  const parsed = String(raw).split('|').map((pair) => {
    const idx = pair.indexOf(':');
    if (idx <= 0) return null;
    const match = pair.slice(0, idx).trim().toLowerCase();
    const category = pair.slice(idx + 1).trim().toLowerCase();
    if (!match || !category) return null;
    return [match, category];
  }).filter(Boolean);
  return sortRules(parsed);
}

function sortRules(rules) {
  return rules.slice().sort((a, b) => b[0].length - a[0].length);
}

function categoryKeysFromEnv() {
  const raw = process.env.VAULT_CATEGORY_KEYS;
  if (!raw || !String(raw).trim()) return DEFAULT_CATEGORY_KEYS;
  const out = {};
  String(raw).split('|').forEach((pair) => {
    const idx = pair.indexOf(':');
    if (idx <= 0) return;
    const key = pair.slice(0, idx).trim().toLowerCase();
    const category = pair.slice(idx + 1).trim().toLowerCase();
    if (key && category) out[key] = category;
  });
  return out;
}

function budgetMap() {
  const raw = process.env.VAULT_BUDGET_JSON;
  if (!raw || !String(raw).trim()) return null;
  try {
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') return null;
    return parsed;
  } catch (err) {
    return null;
  }
}

function resolveCategory(authorization) {
  const merchant = authorization && authorization.merchant ? authorization.merchant : {};
  const category = merchant.category || {};
  const key = category.key ? String(category.key).toLowerCase() : '';
  const keys = categoryKeysFromEnv();
  if (key && Object.prototype.hasOwnProperty.call(keys, key)) return keys[key];
  const name = String(merchant.name || (authorization && authorization.description) || '').toLowerCase();
  const rules = rulesFromEnv();
  for (let i = 0; i < rules.length; i += 1) {
    if (name.indexOf(rules[i][0]) !== -1) return rules[i][1];
  }
  // A programmable-card authorisation is a card purchase. Unmatched
  // merchants use the coach's `card` bucket rather than a network lookup.
  return 'card';
}

function remainingCents(category) {
  const map = budgetMap();
  if (!map || !Object.prototype.hasOwnProperty.call(map, category)) return null;
  const n = Number(map[category]);
  if (!Number.isFinite(n)) return null;
  return n;
}

function fallbackLimitCents() {
  const n = Number(process.env.VAULT_FALLBACK_TX_LIMIT_CENTS || 50000);
  return Number.isFinite(n) ? n : 50000;
}

const beforeTransaction = async (authorization) => {
  const cents = Number(authorization && authorization.centsAmount);
  if (!Number.isFinite(cents) || cents < 0) return false;
  const category = resolveCategory(authorization || {});
  const remaining = remainingCents(category);
  if (remaining === null) return cents <= fallbackLimitCents();
  return cents <= remaining;
};

function maskAccount(value) {
  const s = String(value == null ? '' : value).replace(/\s+/g, '');
  if (s.length <= 4) return '****';
  return `****${s.slice(-4)}`;
}

function eventBody(hook, authorization, approved) {
  const merchant = authorization && authorization.merchant ? authorization.merchant : {};
  return {
    source: 'investec-card',
    hook,
    approved: Boolean(approved),
    centsAmount: Number(authorization && authorization.centsAmount),
    currencyCode: String((authorization && authorization.currencyCode) || 'zar').toLowerCase(),
    category: resolveCategory(authorization || {}),
    merchantName: merchant.name ? String(merchant.name) : '',
    reference: authorization && authorization.reference ? String(authorization.reference) : '',
    accountMasked: maskAccount(authorization && authorization.accountNumber)
  };
}

async function postEvent(hook, authorization, approved) {
  const payload = eventBody(hook, authorization, approved);
  console.log(JSON.stringify(payload));
  const url = process.env.VAULT_WEBHOOK_URL;
  if (!url) return payload;
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json'
      },
      body: JSON.stringify(payload)
    });
    console.log(JSON.stringify({ delivered: true, status: response.status }));
  } catch (err) {
    console.log(JSON.stringify({
      delivered: false,
      error: String(err && err.message ? err.message : err)
    }));
  }
  return payload;
}

const afterTransaction = async (transaction) => postEvent('afterTransaction', transaction, true);

const afterDecline = async (transaction) => postEvent('afterDecline', transaction, false);

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    beforeTransaction,
    afterTransaction,
    afterDecline,
    resolveCategory,
    remainingCents,
    maskAccount,
    eventBody,
    DEFAULT_MERCHANT_RULES,
    DEFAULT_CATEGORY_KEYS
  };
}
