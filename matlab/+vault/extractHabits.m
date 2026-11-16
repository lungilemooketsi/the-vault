function habits = extractHabits(txns, asOf, options)
%extractHabits  Recurring stems, payday, weekend spike, day-of-month factors.
% The in-progress month and partial months (August starts on the 11th) are
% excluded from the baseline. minMonths defaults to 2 because the sandbox
% only has two complete real months before back-fill.
if nargin < 3
  options = struct();
end
minMonths = opt(options, 'minRecurringMonths', 2);
dayRange = opt(options, 'recurringDayRange', 7);
amountTol = opt(options, 'recurringAmountTolerance', 0.15);
asOfDn = vault.parseDate(asOf);
current = vault.monthKey(asOfDn);
[baseline, baselineMonths, partialMonths] = selectBaseline(txns, current);
habits.baselineMonths = baselineMonths;
habits.partialMonths = partialMonths;
habits.currentMonth = current;
habits.recurring = emptyRecurring();
habits.payday = emptyPayday();
habits.weekendMultiplier = 1;
habits.domFactor = ones(1, 31);
habits.categoryMonthlyMedian = struct();
habits.discretionaryShare = struct();
habits.weekdayPool = [];
habits.weekendPool = [];
habits.dailyDom = cell(1, 31);
if isempty(baseline)
  return;
end
habits.recurring = findRecurring(baseline, minMonths, dayRange, amountTol);
if ~isempty(habits.recurring)
  creditIdx = [];
  for i = 1:numel(habits.recurring)
    if strcmp(habits.recurring(i).direction, 'credit')
      creditIdx(end + 1) = i; %#ok<AGROW>
    end
  end
  if ~isempty(creditIdx)
    amounts = zeros(1, numel(creditIdx));
    for i = 1:numel(creditIdx)
      amounts(i) = habits.recurring(creditIdx(i)).medianAmount;
    end
    [~, best] = max(amounts);
    chosen = habits.recurring(creditIdx(best));
    habits.payday.stem = chosen.stem;
    habits.payday.dayOfMonth = chosen.dayOfMonth;
    habits.payday.medianAmount = chosen.medianAmount;
    habits.payday.months = chosen.months;
    habits.payday.found = true;
  end
end
recurringDebitStems = {};
for i = 1:numel(habits.recurring)
  if strcmp(habits.recurring(i).direction, 'debit')
    recurringDebitStems{end + 1} = habits.recurring(i).stem; %#ok<AGROW>
  end
end
[habits.weekdayPool, habits.weekendPool, habits.dailyDom, habits.weekendMultiplier, habits.domFactor] = ...
  dailyProfile(baseline, recurringDebitStems);
habits.categoryMonthlyMedian = categoryMedians(baseline, baselineMonths);
habits.discretionaryShare = categoryShares(baseline, recurringDebitStems);
habits.recurringDebitStems = recurringDebitStems;
end

function [baseline, months, partial] = selectBaseline(txns, current)
groups = {};
for i = 1:numel(txns)
  key = txns(i).month;
  found = 0;
  for g = 1:numel(groups)
    if strcmp(groups{g}.key, key)
      groups{g}.doms(end + 1) = txns(i).dom; %#ok<AGROW>
      found = 1;
      break;
    end
  end
  if ~found
    groups{end + 1} = struct('key', key, 'doms', txns(i).dom); %#ok<AGROW>
  end
end
months = {};
partial = {};
use = {};
for i = 1:numel(groups)
  key = groups{i}.key;
  if vault.isoCmp(key, current) >= 0
    continue;
  end
  isPartial = min(groups{i}.doms) > 1 || max(groups{i}.doms) < 28;
  if isPartial
    partial{end + 1} = key; %#ok<AGROW>
    continue;
  end
  months{end + 1} = key; %#ok<AGROW>
  use{end + 1} = key; %#ok<AGROW>
end
months = sort(months);
partial = sort(partial);
if isempty(use)
  % Fall back to every month before the in-progress one, partial included.
  for i = 1:numel(groups)
    if vault.isoCmp(groups{i}.key, current) < 0
      use{end + 1} = groups{i}.key; %#ok<AGROW>
    end
  end
end
baseline = txns(false);
for i = 1:numel(txns)
  if isKey(txns(i).month, use)
    if isempty(baseline)
      baseline = txns(i);
    else
      baseline(end + 1) = txns(i); %#ok<AGROW>
    end
  end
end
end

function rows = findRecurring(baseline, minMonths, dayRange, amountTol)
rows = emptyRecurring();
groups = groupStemDirection(baseline);
for i = 1:numel(groups)
  idx = groups(i).idx;
  months = {};
  amounts = [];
  days = [];
  for j = 1:numel(idx)
    item = baseline(idx(j));
    amounts(end + 1) = item.amount; %#ok<AGROW>
    days(end + 1) = item.dom; %#ok<AGROW>
    if ~isKey(item.month, months)
      months{end + 1} = item.month; %#ok<AGROW>
    end
  end
  if numel(months) < minMonths
    continue;
  end
  med = median(amounts);
  tol = max(5, amountTol * med);
  if any(abs(amounts - med) > tol + 1e-6)
    continue;
  end
  if max(days) - min(days) > dayRange
    continue;
  end
  row = struct();
  row.stem = groups(i).stem;
  row.direction = groups(i).direction;
  row.category = baseline(idx(1)).category;
  row.medianAmount = med;
  row.dayOfMonth = round(median(days));
  row.dayMin = min(days);
  row.dayMax = max(days);
  row.months = numel(months);
  row.description = baseline(idx(1)).description;
  if isempty(rows)
    rows = row;
  else
    rows(end + 1) = row; %#ok<AGROW>
  end
end
end

function groups = groupStemDirection(txns)
groups = struct('stem', {}, 'direction', {}, 'idx', {});
for i = 1:numel(txns)
  if isempty(txns(i).stem)
    continue;
  end
  found = 0;
  for g = 1:numel(groups)
    if strcmp(groups(g).stem, txns(i).stem) && strcmp(groups(g).direction, txns(i).direction)
      groups(g).idx(end + 1) = i;
      found = 1;
      break;
    end
  end
  if ~found
    groups(end + 1).stem = txns(i).stem; %#ok<AGROW>
    groups(end).direction = txns(i).direction;
    groups(end).idx = i;
  end
end
end

function [weekdayPool, weekendPool, dailyDom, multiplier, domFactor] = dailyProfile(baseline, recurringStems)
totals = struct('dn', {}, 'amount', {}, 'dom', {}, 'weekend', {});
for i = 1:numel(baseline)
  item = baseline(i);
  if ~strcmp(item.direction, 'debit') || isKey(item.stem, recurringStems)
    continue;
  end
  found = 0;
  for t = 1:numel(totals)
    if totals(t).dn == item.dn
      totals(t).amount = totals(t).amount + item.amount;
      found = 1;
      break;
    end
  end
  if ~found
    totals(end + 1).dn = item.dn; %#ok<AGROW>
    totals(end).amount = item.amount;
    totals(end).dom = item.dom;
    totals(end).weekend = vault.isWeekend(item.dn);
  end
end
weekdayPool = [];
weekendPool = [];
dailyDom = cell(1, 31);
for i = 1:numel(totals)
  if totals(i).weekend
    weekendPool(end + 1) = totals(i).amount; %#ok<AGROW>
  else
    weekdayPool(end + 1) = totals(i).amount; %#ok<AGROW>
  end
  d = totals(i).dom;
  dailyDom{d}(end + 1) = totals(i).amount; %#ok<AGROW>
end
if isempty(weekdayPool)
  weekdayMean = 0;
else
  weekdayMean = mean(weekdayPool);
end
if isempty(weekendPool) || weekdayMean <= 0
  multiplier = 1;
else
  multiplier = mean(weekendPool) / weekdayMean;
end
allAmounts = [weekdayPool weekendPool];
if isempty(allAmounts)
  allMed = 0;
else
  allMed = median(allAmounts);
end
domFactor = ones(1, 31);
for d = 1:31
  samples = dailyDom{d};
  if numel(samples) < 3 || allMed <= 0
    continue;
  end
  raw = median(samples) / allMed;
  shrink = numel(samples) / (numel(samples) + 3);
  factor = 1 + (raw - 1) * shrink;
  domFactor(d) = min(3, max(0.25, factor));
end
end

function medians = categoryMedians(baseline, months)
medians = struct();
if isempty(months)
  return;
end
cats = {};
for i = 1:numel(baseline)
  if strcmp(baseline(i).direction, 'debit') && ~isKey(baseline(i).category, cats)
    cats{end + 1} = baseline(i).category; %#ok<AGROW>
  end
end
for c = 1:numel(cats)
  cat = cats{c};
  monthly = zeros(1, numel(months));
  for m = 1:numel(months)
    total = 0;
    for i = 1:numel(baseline)
      if strcmp(baseline(i).month, months{m}) && strcmp(baseline(i).category, cat) && strcmp(baseline(i).direction, 'debit')
        total = total + baseline(i).amount;
      end
    end
    monthly(m) = total;
  end
  medians.(cat) = median(monthly);
end
end

function shares = categoryShares(baseline, recurringStems)
totals = struct();
grand = 0;
for i = 1:numel(baseline)
  item = baseline(i);
  if ~strcmp(item.direction, 'debit') || isKey(item.stem, recurringStems)
    continue;
  end
  if ~isfield(totals, item.category)
    totals.(item.category) = 0;
  end
  totals.(item.category) = totals.(item.category) + item.amount;
  grand = grand + item.amount;
end
shares = struct();
if grand <= 0
  return;
end
cats = fieldnames(totals);
for i = 1:numel(cats)
  shares.(cats{i}) = totals.(cats{i}) / grand;
end
end

function rows = emptyRecurring()
rows = struct('stem', {}, 'direction', {}, 'category', {}, 'medianAmount', {}, ...
  'dayOfMonth', {}, 'dayMin', {}, 'dayMax', {}, 'months', {}, 'description', {});
end

function payday = emptyPayday()
payday.found = false;
payday.stem = '';
payday.dayOfMonth = 0;
payday.medianAmount = 0;
payday.months = 0;
end

function value = opt(options, name, fallback)
if isfield(options, name) && ~isempty(options.(name))
  value = options.(name);
else
  value = fallback;
end
end

function tf = isKey(key, list)
tf = false;
if iscell(list)
  for i = 1:numel(list)
    if strcmp(list{i}, key)
      tf = true;
      return;
    end
  end
end
end
