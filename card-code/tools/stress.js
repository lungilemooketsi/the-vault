'use strict';

const fs = require('fs');
const path = require('path');
const { beforeTransaction, afterTransaction, afterDecline } = require('../main');
const { loadEnvFile } = require('./envfile');

const MERCHANTS = [
  ['Woolworths Sandton', 18000, 65000],
  ['Checkers Hyper', 15000, 50000],
  ['Nandos Sandton', 8000, 35000],
  ['Uber Eats', 6000, 25000],
  ['Kauai', 4000, 12000],
  ['Shell Sandton', 8000, 25000],
  ['Uber Trip', 4500, 18000],
  ['Takealot', 15000, 250000],
  ['Netflix.com', 19900, 19900],
  ['Clicks Pharmacy', 5000, 30000],
  ['Seattle Coffee', 3500, 7000],
  ['Corner Cafe', 2000, 8000]
];

function mulberry32(seed) {
  let a = seed >>> 0;
  return function next() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function arg(name, fallback) {
  const idx = process.argv.indexOf(name);
  if (idx === -1 || idx + 1 >= process.argv.length) return fallback;
  return process.argv[idx + 1];
}

async function runStress(options) {
  const opts = options || {};
  const rand = mulberry32(opts.seed == null ? 20261116 : opts.seed);
  const days = opts.days || 30;
  const swipesPerDay = opts.swipesPerDay || 3;
  const events = [];
  let approvedCount = 0;
  let declinedCount = 0;
  for (let day = 1; day <= days; day += 1) {
    for (let s = 0; s < swipesPerDay; s += 1) {
      const pick = MERCHANTS[Math.floor(rand() * MERCHANTS.length)];
      const cents = Math.round(pick[1] + rand() * (pick[2] - pick[1]));
      const authorization = {
        accountNumber: '10010020001',
        centsAmount: cents,
        currencyCode: 'zar',
        reference: 'simulation',
        merchant: { name: pick[0] }
      };
      const approved = await beforeTransaction(authorization);
      const payload = approved
        ? await afterTransaction(authorization)
        : await afterDecline(authorization);
      if (approved) approvedCount += 1;
      else declinedCount += 1;
      events.push(Object.assign({ day }, payload));
    }
  }
  return { seed: opts.seed == null ? 20261116 : opts.seed, days, approvedCount, declinedCount, events };
}

async function main() {
  const envPath = arg('--env', path.join(__dirname, '..', 'env.example.json'));
  loadEnvFile(envPath);
  const result = await runStress({
    seed: Number(arg('--seed', '20261116')),
    days: Number(arg('--days', '30')),
    swipesPerDay: Number(arg('--per-day', '3'))
  });
  const repoRoot = path.join(__dirname, '..', '..');
  const outDir = path.join(repoRoot, 'runtime');
  fs.mkdirSync(outDir, { recursive: true });
  const outPath = path.join(outDir, 'stress-events.json');
  fs.writeFileSync(outPath, JSON.stringify(result, null, 2));
  process.stdout.write(`${JSON.stringify({
    approvedCount: result.approvedCount,
    declinedCount: result.declinedCount,
    events: result.events.length,
    outPath
  })}\n`);
}

if (require.main === module) {
  main().catch((err) => {
    process.stderr.write(`${err && err.stack ? err.stack : err}\n`);
    process.exit(1);
  });
}

module.exports = { runStress };
