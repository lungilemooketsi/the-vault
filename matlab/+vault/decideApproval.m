function decision = decideApproval(proposal, verb, note)
% The only constructor of an approval. verb must be APPROVE or DENY.
% A physical or simulated input must call this after the review is shown.
if ~strcmp(verb, 'APPROVE') && ~strcmp(verb, 'DENY')
  error('vault:approval:verb', 'Type APPROVE to move money, or DENY to cancel.');
end
if nargin < 3
  note = '';
end
decision.verb = verb;
decision.approved = strcmp(verb, 'APPROVE');
decision.proposalId = proposal.id;
decision.fingerprint = proposal.fingerprint;
decision.note = char(note);
decision.decidedAt = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end
