function response = mockTransport(request, client)
response.status = 200;
response.raw = '';
response.body = [];
url = request.url;
if ~isempty(strfind(url, '/identity/v2/oauth2/token')) %#ok<STREMP>
  response.body.access_token = 'mock-token';
  response.body.token_type = 'Bearer';
  response.body.expires_in = 1799;
  response.body.scope = 'accounts';
  return;
end
if ~isempty(strfind(url, '/za/v1/cards')) %#ok<STREMP>
  response.status = 403;
  response.body = struct();
  return;
end
if ~isempty(strfind(url, '/pending-transactions')) %#ok<STREMP>
  id = between(url, '/accounts/', '/pending-transactions');
  entry = mapGet(vault.readJson(fullfile(client.fixtureDir, 'pending.json')), id);
  if isempty(entry) || ~isfield(entry, 'status') || entry.status >= 400
    response.status = 500;
    response.body = struct('title', 'An error occurred while processing your request.');
    return;
  end
  response.body = entry.body;
  return;
end
if ~isempty(strfind(url, '/transfermultiple')) %#ok<STREMP>
  response.body.data.TransferResponses.PaymentReferenceNumber = 'MOCK-APPROVED';
  response.body.data.TransferResponses.Status = 'Mock transfer accepted after approval';
  response.body.data.TransferResponses.BeneficiaryName = 'Savings Vault';
  response.body.data.TransferResponses.AuthorisationRequired = false;
  response.body.data.ErrorMessage = '';
  return;
end
if ~isempty(strfind(url, '/transactions?')) %#ok<STREMP>
  id = between(url, '/accounts/', '/transactions');
  response.body = filterTransactions(client.fixtureDir, id, queryValue(url, 'fromDate'), queryValue(url, 'toDate'));
  return;
end
if ~isempty(strfind(url, '/balance')) %#ok<STREMP>
  id = between(url, '/accounts/', '/balance');
  entry = mapGet(vault.readJson(fullfile(client.fixtureDir, 'balances.json')), id);
  response.body = entry;
  return;
end
if ~isempty(strfind(url, '/za/pb/v1/accounts')) %#ok<STREMP>
  response.body = vault.readJson(fullfile(client.fixtureDir, 'accounts.json'));
  return;
end
response.status = 404;
response.body = struct('title', 'No mock for this path');
end

function body = filterTransactions(fixtureDir, id, fromDate, toDate)
pba = vault.readJson(fullfile(fixtureDir, 'transactions.json'));
rows = pba.data.transactions;
if isempty(rows) || ~strcmp(char(rows(1).accountId), char(id))
  others = vault.readJson(fullfile(fixtureDir, 'other-transactions.json'));
  entry = mapGet(others, id);
  if isempty(entry) || ~isfield(entry, 'body')
    body.data.transactions = [];
    body.meta.totalPages = 1;
    return;
  end
  rows = entry.body.data.transactions;
end
kept = rows(false);
for i = 1:numel(rows)
  day = char(rows(i).transactionDate);
  afterFrom = isempty(fromDate) || vault.isoCmp(day, fromDate) >= 0;
  beforeTo = isempty(toDate) || vault.isoCmp(day, toDate) <= 0;
  if afterFrom && beforeTo
    if isempty(kept)
      kept = rows(i);
    else
      kept(end + 1) = rows(i); %#ok<AGROW>
    end
  end
end
body.data.transactions = kept;
body.meta.totalPages = 1;
end

function entry = mapGet(map, id)
name = ['x' char(id)];
if isstruct(map) && isfield(map, name)
  entry = map.(name);
  return;
end
entry = [];
end

function value = between(url, left, right)
a = strfind(url, left);
b = strfind(url, right);
if isempty(a) || isempty(b)
  value = '';
  return;
end
start = a(end) + numel(left);
stop = b(end) - 1;
if stop < start
  value = '';
  return;
end
value = url(start:stop);
end

function value = queryValue(url, name)
token = [name '='];
idx = strfind(url, token);
if isempty(idx)
  value = '';
  return;
end
rest = url(idx(1) + numel(token):end);
amp = strfind(rest, '&');
if isempty(amp)
  value = rest;
else
  value = rest(1:amp(1) - 1);
end
end

