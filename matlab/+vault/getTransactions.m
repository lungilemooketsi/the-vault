function [client, payload] = getTransactions(client, accountId, fromDate, toDate)
if nargin < 4 || isempty(fromDate) || isempty(toDate)
  error('vault:dates:required', ['fromDate and toDate are required. Omitting fromDate makes the sandbox ' ...
    'apply its default lookback and drops the 2026-08-11 card purchase.']);
end
path = sprintf('/za/pb/v1/accounts/%s/transactions?fromDate=%s&toDate=%s', char(accountId), fromDate, toDate);
[client, request] = vault.authorizedRequest(client, 'GET', path);
[client, response] = vault.dispatch(client, request);
payload = vault.payloadOf(response);
end
