function account = selectPrivateBank(accounts)
for i = 1:numel(accounts)
  if strcmpi(strtrim(char(accounts(i).productName)), 'Private Bank Account')
    account = accounts(i);
    account.accountId = char(account.accountId);
    account.accountNumber = char(account.accountNumber);
    if isfield(account, 'profileId')
      account.profileId = char(account.profileId);
    end
    return;
  end
end
error('vault:account', 'No Private Bank Account was returned.');
end
