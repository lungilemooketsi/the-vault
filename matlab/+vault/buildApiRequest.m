function request = buildApiRequest(cfg, method, path, jsonBody)
request.method = method;
base = cfg.baseUrl;
if ~isempty(base) && base(end) == '/'
  base = base(1:end-1);
end
if isempty(path) || path(1) ~= '/'
  path = ['/' path];
end
request.url = [base path];
request.headers = {
  'Accept', 'application/json'
};
request.bodyKind = 'none';
request.form = {};
request.json = [];
if nargin >= 4 && ~isempty(jsonBody)
  request.bodyKind = 'json';
  request.json = jsonBody;
  request.headers(end + 1, :) = {'Content-Type', 'application/json'};
end
end
