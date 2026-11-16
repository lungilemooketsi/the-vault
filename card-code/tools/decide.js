'use strict';

const path = require('path');
const { beforeTransaction, resolveCategory, remainingCents } = require('../main');
const { loadEnvFile } = require('./envfile');

function arg(name, fallback) {
  const idx = process.argv.indexOf(name);
  if (idx === -1 || idx + 1 >= process.argv.length) return fallback;
  return process.argv[idx + 1];
}

async function main() {
  const envPath = arg('--env', path.join(__dirname, '..', 'env.example.json'));
  loadEnvFile(envPath);
  const cents = Number(arg('--cents', '0'));
  const merchant = arg('--merchant', '');
  const categoryKey = arg('--category-key', '');
  const authorization = {
    centsAmount: cents,
    currencyCode: 'zar',
    reference: 'simulation',
    merchant: {
      name: merchant,
      category: categoryKey ? { key: categoryKey, code: '', name: categoryKey } : undefined
    }
  };
  const approved = await beforeTransaction(authorization);
  const category = resolveCategory(authorization);
  const result = {
    approved: Boolean(approved),
    category,
    remainingCents: remainingCents(category),
    centsAmount: cents
  };
  process.stdout.write(`${JSON.stringify(result)}\n`);
  process.exit(approved ? 0 : 2);
}

main().catch((err) => {
  process.stderr.write(`${err && err.stack ? err.stack : err}\n`);
  process.exit(1);
});
