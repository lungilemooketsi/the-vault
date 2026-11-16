function [client, result] = transferMultiple(client, proposal, decision)
% Posts transfermultiple only after an explicit APPROVE decision.
% Live sandbox posts also require VAULT_ALLOW_LIVE_TRANSFER=1 so a demo
% cannot mutate the shared public sandbox by accident.
vault.assertApproved(decision, proposal);
body.transferList = struct( ...
  'beneficiaryAccountId', proposal.toAccountId, ...
  'amount', proposal.amount, ...
  'myReference', proposal.myReference, ...
  'theirReference', proposal.theirReference);
if ~isempty(proposal.profileId)
  body.profileId = proposal.profileId;
end
path = ['/za/pb/v1/accounts/' proposal.fromAccountId '/transfermultiple'];
result.sent = false;
result.approved = true;
result.amount = proposal.amount;
result.fromMasked = proposal.fromMasked;
result.toMasked = proposal.toMasked;
if strcmp(client.mode, 'sandbox') && ~client.allowLiveTransfer
  result.status = 'approved-not-sent';
  result.message = 'Approval recorded. Set VAULT_ALLOW_LIVE_TRANSFER=1 to POST transfermultiple. Nothing was sent.';
  return;
end
[client, request] = vault.authorizedRequest(client, 'POST', path, body);
[client, response] = vault.dispatch(client, request);
result.sent = true;
result.status = 'sent';
result.response = vault.payloadOf(response);
result.message = 'Transfer request was sent after approval.';
end
