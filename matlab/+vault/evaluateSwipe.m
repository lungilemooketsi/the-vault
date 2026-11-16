function [approved, category] = evaluateSwipe(cents, description, rules, remaining, fallback)
% Mirrors card-code beforeTransaction: keywords, otherwise the card bucket.
category = vault.classifyTransaction(description, 'CardPurchases', rules);
if isstruct(remaining) && isfield(remaining, category)
  approved = double(cents) <= double(remaining.(category));
else
  approved = double(cents) <= double(fallback);
end
end
