function budget = generateBudget(habits, user)
%generateBudget  Suggested limits from baseline medians, with user overrides.
if nargin < 2 || isempty(user)
  user = struct();
end
buffer = opt(user, 'buffer', 0.10);
roundTo = opt(user, 'roundTo', 50);
limits = struct();
suggested = struct();
sources = struct();
cats = fieldnames(habits.categoryMonthlyMedian);
for i = 1:numel(cats)
  cat = cats{i};
  if strcmp(cat, 'income')
    continue;
  end
  med = habits.categoryMonthlyMedian.(cat);
  raw = med * (1 + buffer);
  if roundTo > 0
    suggestedLimit = ceil((raw - 1e-9) / roundTo) * roundTo;
  else
    suggestedLimit = raw;
  end
  suggested.(cat) = suggestedLimit;
  if isfield(user, 'limits') && isfield(user.limits, cat) && isnumeric(user.limits.(cat))
    limits.(cat) = double(user.limits.(cat));
    sources.(cat) = 'user';
  else
    limits.(cat) = suggestedLimit;
    sources.(cat) = 'suggested';
  end
end
if isfield(user, 'limits')
  extra = fieldnames(user.limits);
  for i = 1:numel(extra)
    cat = extra{i};
    if ~isfield(limits, cat)
      limits.(cat) = double(user.limits.(cat));
      suggested.(cat) = double(user.limits.(cat));
      sources.(cat) = 'user';
    end
  end
end
total = 0;
names = fieldnames(limits);
for i = 1:numel(names)
  total = total + limits.(names{i});
end
budget.limits = limits;
budget.suggested = suggested;
budget.sources = sources;
budget.total = total;
budget.currency = opt(user, 'currency', 'ZAR');
budget.buffer = buffer;
budget.roundTo = roundTo;
budget.underThresholdAbs = opt(user, 'underThresholdAbs', 100);
budget.underThresholdRatio = opt(user, 'underThresholdRatio', 0.05);
budget.categories = names;
end

function value = opt(s, name, fallback)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
  value = s.(name);
else
  value = fallback;
end
end
