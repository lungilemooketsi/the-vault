'use strict';

const fs = require('fs');

function loadEnvFile(filePath) {
  const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  Object.keys(raw).forEach((key) => {
    const value = raw[key];
    process.env[key] = typeof value === 'string' ? value : JSON.stringify(value);
  });
  return raw;
}

module.exports = { loadEnvFile };
