function [client, request] = authorizedRequest(client, method, path, jsonBody)
[client, token] = vault.getToken(client);
if nargin < 4
  request = vault.buildApiRequest(client.cfg, method, path);
else
  request = vault.buildApiRequest(client.cfg, method, path, jsonBody);
end
if ~strcmp(client.mode, 'mock')
  request.headers(end + 1, :) = {'Authorization', ['Bearer ' token]};
end
end
