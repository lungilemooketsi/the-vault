function category = classifyTransaction(description, transactionType, rules)
% Keyword match wins over the transactionType fallback. The sandbox feed
% has no category field.
desc = lower(char(description));
for i = 1:numel(rules.keywords)
  match = lower(rules.keywords(i).match);
  if ~isempty(match) && ~isempty(strfind(desc, match)) %#ok<STREMP>
    category = rules.keywords(i).category;
    return;
  end
end
tt = char(transactionType);
for i = 1:numel(rules.transactionTypes)
  if strcmpi(tt, rules.transactionTypes(i).type)
    category = rules.transactionTypes(i).category;
    return;
  end
end
category = 'other';
end
