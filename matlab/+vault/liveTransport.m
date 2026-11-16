function response = liveTransport(request, client) %#ok<INUSD>
% Text responses so 25-digit account ids are not rounded by jsondecode.
headerFields = request.headers;
try
  if strcmp(request.method, 'GET')
    opts = weboptions('HeaderFields', headerFields, 'Timeout', 30, 'ContentType', 'text');
    raw = webread(request.url, opts);
  elseif strcmp(request.bodyKind, 'form')
    opts = weboptions('HeaderFields', headerFields, ...
      'MediaType', 'application/x-www-form-urlencoded', 'ContentType', 'text', 'Timeout', 30);
    raw = webwrite(request.url, 'grant_type', 'client_credentials', opts);
  else
    opts = weboptions('HeaderFields', headerFields, ...
      'MediaType', 'application/json', 'ContentType', 'text', 'Timeout', 30);
    raw = webwrite(request.url, request.json, opts);
  end
catch err
  error('vault:http', '%s', vault.scrubSecrets(err.message));
end
response.status = 200;
response.raw = char(raw);
response.body = [];
end
