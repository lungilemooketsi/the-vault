function assertApproved(decision, proposal)
if ~isstruct(decision) || ~isfield(decision, 'approved') || ~decision.approved
  error('vault:approval:required', 'Transfer refused. Show the review and decide APPROVE before any transfer call.');
end
if ~isfield(decision, 'verb') || ~strcmp(decision.verb, 'APPROVE')
  error('vault:approval:required', 'Transfer refused. The decision verb is not APPROVE.');
end
if ~strcmp(decision.proposalId, proposal.id) || ~strcmp(decision.fingerprint, proposal.fingerprint)
  error('vault:approval:mismatch', 'Transfer refused. The approval does not match this transfer.');
end
end
