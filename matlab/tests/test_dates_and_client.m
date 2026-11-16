function test_dates_and_client()
cfg = vault.loadConfig();
cfg.mode = 'mock';
cfg.allowLiveTransfer = false;
client = vault.createClient(cfg);
[fromDate, toDate] = vault.sandboxWindow('2026-11-16');
check(strcmp(fromDate, '2020-01-01') && strcmp(toDate, '2026-11-16'), 'explicit sandbox window');
threw = false;
try
  vault.getTransactions(client, '1', '', '');
catch
  threw = true;
end
check(threw, 'transactions require both dates');
[client, accounts] = vault.getAccounts(client);
summary = vault.formatAccountSummary(accounts);
joined = vault.joinWith(summary, ' ');
for i = 1:numel(accounts)
  number = char(accounts(i).accountNumber);
  if numel(number) > 4
    check(isempty(strfind(joined, number)), 'summary hides account numbers'); %#ok<STREMP>
  end
end
current = vault.selectPrivateBank(accounts);
savings = vault.selectSavings(accounts, current.profileId);
check(~strcmp(current.accountId, savings.accountId), 'savings is a different account');
[client, payload] = vault.getTransactions(client, current.accountId, fromDate, toDate);
check(numel(payload.data.transactions) == 264, 'wide window keeps all 264 posted rows');
[client, narrow] = vault.getTransactions(client, current.accountId, '2026-08-17', '2026-11-16');
check(numel(narrow.data.transactions) == 263, 'starting 17 Aug drops the 11 Aug purchase');
[client, emptyWindow] = vault.getTransactions(client, current.accountId, '2024-01-01', '2024-01-31');
check(isempty(emptyWindow.data.transactions), 'a 2024 window is empty');
url = client.calls{end}.url;
check(~isempty(strfind(url, 'fromDate=2024-01-01')), 'fromDate is on the request'); %#ok<STREMP>
check(~isempty(strfind(url, 'toDate=2024-01-31')), 'toDate is on the request'); %#ok<STREMP>
[client, ~, info] = vault.getPending(client, current.accountId);
check(info.available, 'PBA pending is available');
[client, ~, otherInfo] = vault.getPending(client, savings.accountId);
check(~otherInfo.available, 'non-PBA pending fails soft');
check(~isempty(otherInfo.warning), 'pending warning is kept');
[client, ~, cards] = vault.getCards(client);
check(~cards.available, 'cards API fails soft on the sandbox token');
[client, balance] = vault.getBalance(client, current.accountId);
check(abs(balance.currentBalance - 33607.16) < 0.001, 'PBA sandbox balance');
proposal = vault.proposeTransfer(current, savings, 250, 'Vault floor', 'Savings vault');
callsBefore = numel(client.calls);
denied = false;
try
  vault.transferMultiple(client, proposal, struct('approved', false));
catch
  denied = true;
end
check(denied && numel(client.calls) == callsBefore, 'denied transfer does not call the API');
decision = vault.decideApproval(proposal, 'APPROVE', 'test review');
[client, result] = vault.transferMultiple(client, proposal, decision);
check(result.sent, 'mock transfer is sent only after APPROVE');
check(strcmp(result.fromMasked, vault.maskAccount(current.accountNumber)), 'receipt is masked');
cfg.mode = 'sandbox';
cfg.allowLiveTransfer = false;
cfg.clientId = 'sandbox-client';
cfg.clientSecret = 'sandbox-secret';
cfg.apiKey = 'sandbox-key';
live = vault.createClient(cfg);
live.transport = @vault.mockTransport;
[live, held] = vault.transferMultiple(live, proposal, decision);
check(~held.sent, 'sandbox transfer is held unless live posts are enabled');
check(isempty(strfind(held.message, 'sandbox-secret')), 'hold message has no secret'); %#ok<STREMP>
end
