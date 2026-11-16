function proposal = proposeTransfer(fromAccount, toAccount, amount, myReference, theirReference)
if amount <= 0
  error('vault:transfer:amount', 'Transfer amount must be positive.');
end
proposal.id = ['tr_' vault.fnv32(sprintf('%s|%s|%.2f|%s', char(fromAccount.accountId), char(toAccount.accountId), amount, myReference))];
proposal.fromAccountId = char(fromAccount.accountId);
proposal.toAccountId = char(toAccount.accountId);
proposal.fromMasked = vault.maskAccount(fromAccount.accountNumber);
proposal.toMasked = vault.maskAccount(toAccount.accountNumber);
proposal.profileId = '';
if isfield(fromAccount, 'profileId')
  proposal.profileId = char(fromAccount.profileId);
end
proposal.amount = sprintf('%.2f', amount);
proposal.amountNumber = amount;
proposal.myReference = char(myReference);
proposal.theirReference = char(theirReference);
proposal.fingerprint = vault.fnv32(canonical(proposal));
proposal.status = 'pending';
end

function text = canonical(proposal)
text = sprintf('%s|%s|%s|%s|%s', proposal.fromAccountId, proposal.toAccountId, ...
  proposal.amount, proposal.myReference, proposal.theirReference);
end
