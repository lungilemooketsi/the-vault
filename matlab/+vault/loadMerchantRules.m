function rules = loadMerchantRules(path)
raw = vault.readJson(path);
rules.keywords = raw.keywords;
rules.transactionTypes = raw.transactionTypes;
if isfield(raw, 'categoryKeys')
  rules.categoryKeys = raw.categoryKeys;
else
  rules.categoryKeys = struct('key', {}, 'category', {});
end
if isempty(rules.keywords)
  return;
end
lens = zeros(1, numel(rules.keywords));
for i = 1:numel(rules.keywords)
  lens(i) = numel(rules.keywords(i).match);
end
[~, order] = sort(lens, 'descend');
rules.keywords = rules.keywords(order);
end
