function cfg = loadConfig()
root = vault.repoRoot();
cfg.root = root;
local = readLocal(fullfile(root, 'config', 'local.json'));
cfg.baseUrl = pick('INVESTEC_BASE_URL', local, 'baseUrl', 'https://openapisandbox.investec.com');
cfg.clientId = pick('INVESTEC_CLIENT_ID', local, 'clientId', '');
cfg.clientSecret = pick('INVESTEC_CLIENT_SECRET', local, 'clientSecret', '');
cfg.apiKey = pick('INVESTEC_API_KEY', local, 'apiKey', '');
cfg.webhookUrl = pick('VAULT_WEBHOOK_URL', local, 'webhookUrl', 'http://127.0.0.1:8787/vault/events');
cfg.fixtureDir = pick('VAULT_FIXTURE_DIR', local, 'fixtureDir', fullfile(root, 'matlab', 'fixtures'));
if ~isAbsolute(cfg.fixtureDir)
  cfg.fixtureDir = fullfile(root, cfg.fixtureDir);
end
cfg.allowLiveTransfer = strcmp(getenv('VAULT_ALLOW_LIVE_TRANSFER'), '1');
cfg.cachePath = fullfile(root, 'runtime', 'token-cache.json');
cfg.asOf = pick('VAULT_AS_OF', local, 'asOf', '2026-11-16');
cfg.backfill = ~strcmp(getenv('VAULT_BACKFILL'), '0');
cfg.rulesPath = fullfile(root, 'shared', 'merchant-rules.json');
cfg.budgetPath = fullfile(root, 'matlab', 'fixtures', 'budget.user.json');
cfg.mode = pick('VAULT_MODE', local, 'mode', '');
if isempty(cfg.mode)
  if credsPresent(cfg)
    cfg.mode = 'sandbox';
  else
    cfg.mode = 'mock';
  end
end
cfg.mode = lower(cfg.mode);
end

function local = readLocal(path)
local = struct();
if exist(path, 'file') ~= 2
  return;
end
local = vault.readJson(path);
end

function value = pick(envName, local, field, fallback)
envValue = getenv(envName);
if ~isempty(envValue)
  value = envValue;
  return;
end
if isstruct(local) && isfield(local, field) && ischar(local.(field)) && ~isempty(local.(field))
  value = local.(field);
  return;
end
value = fallback;
end

function value = envOr(name, fallback)
value = getenv(name);
if isempty(value)
  value = fallback;
end
end

function tf = credsPresent(cfg)
tf = ~isempty(cfg.clientId) && ~isempty(cfg.clientSecret) && ~isempty(cfg.apiKey);
end

function tf = isAbsolute(path)
tf = ~isempty(path) && (path(1) == '/' || (numel(path) > 2 && path(2) == ':'));
end
