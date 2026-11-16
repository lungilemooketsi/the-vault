function lines = formatAccountSummary(accounts)
lines = cell(1, numel(accounts));
for i = 1:numel(accounts)
  account = accounts(i);
  product = char(account.productName);
  masked = vault.maskAccount(account.accountNumber);
  lines{i} = sprintf('%s  %s', product, masked);
end
end
