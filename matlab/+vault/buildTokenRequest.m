function request = buildTokenRequest(cfg)
request.method = 'POST';
request.url = [stripSlash(cfg.baseUrl) '/identity/v2/oauth2/token'];
basic = vault.base64Encode([cfg.clientId ':' cfg.clientSecret]);
request.headers = {
  'Authorization', ['Basic ' basic]
  'x-api-key', cfg.apiKey
  'Accept', 'application/json'
  'Content-Type', 'application/x-www-form-urlencoded'
};
request.bodyKind = 'form';
request.form = {'grant_type', 'client_credentials'};
request.json = [];
end

function url = stripSlash(url)
if ~isempty(url) && url(end) == '/'
  url = url(1:end-1);
end
end
