function [client, token] = getToken(client)
if strcmp(client.mode, 'mock')
  client.token.accessToken = 'mock-token';
  client.token.expiresAt = now + 1;
  token = client.token.accessToken;
  return;
end
if ~isempty(client.token.accessToken) && now < client.token.expiresAt
  token = client.token.accessToken;
  return;
end
request = vault.buildTokenRequest(client.cfg);
[client, response] = vault.dispatch(client, request);
body = vault.payloadOf(response);
if ~isfield(body, 'access_token')
  error('vault:auth', 'The token response did not include access_token. The body was not logged.');
end
client.token.accessToken = char(body.access_token);
expiresIn = 1799;
if isfield(body, 'expires_in')
  expiresIn = double(body.expires_in);
end
client.token.expiresAt = now + max(30, expiresIn - 60) / 86400;
token = client.token.accessToken;
end
