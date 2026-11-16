function account = selectSavings(accounts, profileId)
account = [];
for i = 1:numel(accounts)
  product = char(accounts(i).productName);
  sameProfile = true;
  if nargin > 1 && ~isempty(profileId) && isfield(accounts(i), 'profileId')
    sameProfile = strcmp(char(accounts(i).profileId), char(profileId));
  end
  if sameProfile && ~isempty(strfind(lower(product), 'primesaver')) %#ok<STREMP>
    account = accounts(i);
    account.accountId = char(account.accountId);
    account.accountNumber = char(account.accountNumber);
    if isfield(account, 'profileId')
      account.profileId = char(account.profileId);
    end
    return;
  end
end
error('vault:account', 'No PrimeSaver on the same profile was returned.');
end
