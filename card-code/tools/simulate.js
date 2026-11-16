'use strict';

const fs = require('fs');
const path = require('path');
const { beforeTransaction, afterTransaction, afterDecline } = require('../main');
const { loadEnvFile } = require('./envfile');

function arg(name, fallback) {
  const idx = process.argv.indexOf(name);
  if (idx === -1 || idx + 1 >= process.argv.length) return fallback;
  return process.argv[idx + 1];
}

async function main() {
  const repoRoot = path.join(__dirname, '..', '..');
  const envPath = arg('--env', path.join(__dirname, '..', 'env.example.json'));
  loadEnvFile(envPath);
  const cents = Number(arg('--cents', '20000'));
  const merchant = arg('--merchant', 'Woolworths Sandton');
  const accountNumber = arg('--account', '10010020001');
  const authorization = {
    accountNumber,
    centsAmount: cents,
    currencyCode: 'zar',
    reference: 'simulation',
    dateTime: new Date().toISOString(),
    merchant: { name: merchant, city: 'Johannesburg', category: { key: '', code: '', name: '' } }
  };
  const approved = await beforeTransaction(authorization);
  const payload = approved
    ? await afterTransaction(authorization)
    : await afterDecline(authorization);
  const inboxDir = path.join(repoRoot, 'runtime');
  fs.mkdirSync(inboxDir, { recursive: true });
  fs.appendFileSync(path.join(inboxDir, 'inbox.jsonl'), `${JSON.stringify(payload)}\n`);
  process.stdout.write(`${JSON.stringify({ approved: Boolean(approved), event: payload })}\n`);
}

main().catch((err) => {
  process.stderr.write(`${err && err.stack ? err.stack : err}\n`);
  process.exit(1);
});
