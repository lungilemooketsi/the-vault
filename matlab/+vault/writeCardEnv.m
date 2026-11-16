function env = writeCardEnv(path, budget, mtd, rules, webhook)
cats = fieldnames(budget.limits);
remaining = struct();
for i = 1:numel(cats)
  spent = 0;
  if isstruct(mtd) && isfield(mtd, cats{i})
    spent = mtd.(cats{i});
  end
  remaining.(cats{i}) = max(0, round((budget.limits.(cats{i}) - spent) * 100));
end
parts = cell(1, numel(rules.keywords));
for i = 1:numel(rules.keywords)
  parts{i} = [rules.keywords(i).match ':' rules.keywords(i).category];
end
env.VAULT_BUDGET_JSON = jsonencode(remaining);
env.VAULT_MERCHANT_RULES = vault.joinWith(parts, '|');
env.VAULT_WEBHOOK_URL = char(webhook);
env.VAULT_FALLBACK_TX_LIMIT_CENTS = '50000';
env.VAULT_NOTE = 'Generated from the budget coach. No secrets.';
vault.writeJson(path, env);
end
