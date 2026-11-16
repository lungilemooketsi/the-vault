function [client, accounts] = getAccounts(client)
[client, request] = vault.authorizedRequest(client, 'GET', '/za/pb/v1/accounts');
[client, response] = vault.dispatch(client, request);
payload = vault.payloadOf(response);
accounts = payload.data.accounts;
end
