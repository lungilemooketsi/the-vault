function client = createClient(cfg)
if nargin < 1 || isempty(cfg)
  cfg = vault.loadConfig();
end
if strcmp(cfg.mode, 'sandbox')
  if isempty(cfg.clientId) || isempty(cfg.clientSecret) || isempty(cfg.apiKey)
    error('vault:config:credentials', ['Sandbox mode needs INVESTEC_CLIENT_ID, INVESTEC_CLIENT_SECRET and INVESTEC_API_KEY. ' ...
      'Copy the public sandbox values from the Private Bank API docs. Nothing was sent.']);
  end
end
client.cfg = cfg;
client.mode = cfg.mode;
client.calls = {};
client.token = struct('accessToken', '', 'expiresAt', 0);
client.fixtureDir = cfg.fixtureDir;
client.allowLiveTransfer = cfg.allowLiveTransfer;
if strcmp(cfg.mode, 'mock')
  client.transport = @vault.mockTransport;
else
  client.transport = @vault.liveTransport;
end
end
