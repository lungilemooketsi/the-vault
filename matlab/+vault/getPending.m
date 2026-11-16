function [client, pending, info] = getPending(client, accountId)
% Fail soft. The sandbox returns HTTP 500 for every account except the
% Private Bank Account. Pending rows are not part of habit learning.
info.available = false;
info.warning = '';
pending = struct('accountId', {}, 'type', {}, 'status', {}, 'description', {}, 'transactionDate', {}, 'amount', {});
path = ['/za/pb/v1/accounts/' char(accountId) '/pending-transactions'];
try
  [client, request] = vault.authorizedRequest(client, 'GET', path);
  [client, response] = vault.dispatch(client, request);
catch
  info.warning = 'Pending transactions could not be loaded. On the sandbox this endpoint returns HTTP 500 except on the Private Bank Account.';
  return;
end
if ~isfield(response, 'status') || response.status >= 400 || response.status == 0
  info.warning = 'Pending transactions are not available for this account.';
  return;
end
payload = vault.payloadOf(response);
if ~isfield(payload, 'data') || ~isfield(payload.data, 'transactions')
  info.warning = 'Pending response had no transactions list.';
  return;
end
pending = payload.data.transactions;
info.available = true;
end
