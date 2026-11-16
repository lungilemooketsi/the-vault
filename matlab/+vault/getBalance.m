function [client, balance] = getBalance(client, accountId)
path = ['/za/pb/v1/accounts/' char(accountId) '/balance'];
[client, request] = vault.authorizedRequest(client, 'GET', path);
[client, response] = vault.dispatch(client, request);
payload = vault.payloadOf(response);
balance = payload.data;
balance.accountId = char(accountId);
end
