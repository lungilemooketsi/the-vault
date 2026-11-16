function [client, cards, info] = getCards(client)
% Optional. The sandbox token has no cards scope and GET /za/v1/cards
% returns 403. Card rules are exercised by the Node harness and the IDE.
info.available = false;
info.warning = '';
cards = struct('CardKey', {}, 'CardNumber', {});
try
  [client, request] = vault.authorizedRequest(client, 'GET', '/za/v1/cards');
  [client, response] = vault.dispatch(client, request);
catch
  info.warning = 'Card API is not available with this token. Use the local card harness or the Investec IDE simulator.';
  return;
end
if ~isfield(response, 'status') || response.status >= 400
  info.warning = 'Card API refused the token (sandbox tokens have no cards scope).';
  return;
end
payload = vault.payloadOf(response);
if isfield(payload, 'data') && isfield(payload.data, 'cards')
  cards = payload.data.cards;
  info.available = true;
end
end
