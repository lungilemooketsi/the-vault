function report = projectMonth(habits, txns, budget, asOf, options)
%projectMonth  Monte Carlo the rest of the month from habits + actuals.
if nargin < 5
  options = struct();
end
nPaths = opt(options, 'nPaths', 400);
seed = opt(options, 'seed', 20261116);
rng(seed);
asOfDn = vault.parseDate(asOf);
current = vault.monthKey(asOfDn);
dv = datevec(asOfDn);
eom = datenum(dv(1), dv(2) + 1, 1) - 1;
mtd = mtdSpend(txns, current, asOfDn);
seenStems = stemsSeen(txns, current, asOfDn);
future = (asOfDn + 1):eom;
nDays = numel(future);
cats = budget.categories;
pathTotal = zeros(nPaths, 1);
pathCat = struct();
for i = 1:numel(cats)
  pathCat.(cats{i}) = zeros(nPaths, 1);
end
pathDaily = zeros(nPaths, max(nDays, 1));
upcoming = upcomingDebits(habits, seenStems);
for p = 1:nPaths
  catSpend = struct();
  for i = 1:numel(cats)
    catSpend.(cats{i}) = mtdOf(mtd, cats{i});
  end
  for d = 1:nDays
    dn = future(d);
    dom = datevec(dn);
    dom = dom(3);
    daySpend = 0;
    for u = 1:numel(upcoming)
      if upcoming(u).dayOfMonth ~= dom
        continue;
      end
      amt = upcoming(u).medianAmount;
      daySpend = daySpend + amt;
      catSpend = addCat(catSpend, upcoming(u).category, amt, cats);
    end
    disc = sampleDiscretionary(habits, dn, dom);
    daySpend = daySpend + disc;
    catSpend = spread(catSpend, habits.discretionaryShare, disc, cats);
    pathDaily(p, d) = daySpend;
  end
  total = 0;
  for i = 1:numel(cats)
    pathCat.(cats{i})(p) = catSpend.(cats{i});
    total = total + catSpend.(cats{i});
  end
  pathTotal(p) = total;
end
report.mtd = mtd;
report.futureDates = future;
report.total.p10 = vault.percentile(pathTotal, 10);
report.total.p50 = vault.percentile(pathTotal, 50);
report.total.p90 = vault.percentile(pathTotal, 90);
report.categories = struct();
for i = 1:numel(cats)
  cat = cats{i};
  entry.p10 = vault.percentile(pathCat.(cat), 10);
  entry.p50 = vault.percentile(pathCat.(cat), 50);
  entry.p90 = vault.percentile(pathCat.(cat), 90);
  entry.limit = budget.limits.(cat);
  entry.mtd = mtdOf(mtd, cat);
  report.categories.(cat) = entry;
end
report.budgetTotal = budget.total;
report.p10 = report.total.p10;
report.p50 = report.total.p50;
report.p90 = report.total.p90;
report.crossoverDate = crossover(txns, current, asOfDn, budget.total, future, pathDaily);
report.underThresholdAbs = budget.underThresholdAbs;
report.underThresholdRatio = budget.underThresholdRatio;
report.nPaths = nPaths;
report.seed = seed;
end

function mtd = mtdSpend(txns, current, asOfDn)
mtd = struct();
mtd.total = 0;
for i = 1:numel(txns)
  item = txns(i);
  if ~strcmp(item.month, current) || item.dn > asOfDn || ~strcmp(item.direction, 'debit')
    continue;
  end
  if ~isfield(mtd, item.category)
    mtd.(item.category) = 0;
  end
  mtd.(item.category) = mtd.(item.category) + item.amount;
  mtd.total = mtd.total + item.amount;
end
end

function seen = stemsSeen(txns, current, asOfDn)
seen = {};
for i = 1:numel(txns)
  item = txns(i);
  if strcmp(item.month, current) && item.dn <= asOfDn && strcmp(item.direction, 'debit')
    if ~isempty(item.stem) && ~isKey(item.stem, seen)
      seen{end + 1} = item.stem; %#ok<AGROW>
    end
  end
end
end

function rows = upcomingDebits(habits, seen)
rows = habits.recurring(false);
if isempty(habits.recurring)
  return;
end
for i = 1:numel(habits.recurring)
  item = habits.recurring(i);
  if ~strcmp(item.direction, 'debit') || isKey(item.stem, seen)
    continue;
  end
  if isempty(rows)
    rows = item;
  else
    rows(end + 1) = item; %#ok<AGROW>
  end
end
end

function value = mtdOf(mtd, cat)
if isfield(mtd, cat)
  value = mtd.(cat);
else
  value = 0;
end
end

function spend = addCat(spend, cat, amt, cats)
if ~isfield(spend, cat)
  % Category was not in the budget (for example a new income misfile). Ignore.
  return;
end
if ~isKey(cat, cats)
  return;
end
spend.(cat) = spend.(cat) + amt;
end

function spend = spread(spend, shares, disc, cats)
if disc <= 0 || ~isstruct(shares)
  return;
end
names = fieldnames(shares);
for i = 1:numel(names)
  cat = names{i};
  if isfield(spend, cat)
    spend.(cat) = spend.(cat) + disc * shares.(cat);
  end
end
end

function amount = sampleDiscretionary(habits, dn, dom)
if vault.isWeekend(dn)
  pool = habits.weekendPool;
else
  pool = habits.weekdayPool;
end
if isempty(pool)
  base = 0;
else
  base = pool(randi(numel(pool)));
end
factor = 1;
if numel(habits.domFactor) >= dom
  factor = habits.domFactor(dom);
end
amount = max(0, base * factor);
end

function dn = crossover(txns, current, asOfDn, budgetTotal, future, pathDaily)
dn = [];
cum = 0;
days = [];
for i = 1:numel(txns)
  item = txns(i);
  if strcmp(item.month, current) && item.dn <= asOfDn && strcmp(item.direction, 'debit')
    days(end + 1) = item.dn; %#ok<AGROW>
  end
end
days = unique(days);
for i = 1:numel(days)
  for j = 1:numel(txns)
    if txns(j).dn == days(i) && strcmp(txns(j).direction, 'debit')
      cum = cum + txns(j).amount;
    end
  end
  if cum > budgetTotal
    dn = days(i);
    return;
  end
end
for d = 1:numel(future)
  if isempty(pathDaily)
    break;
  end
  cum = cum + vault.percentile(pathDaily(:, d), 50);
  if cum > budgetTotal
    dn = future(d);
    return;
  end
end
end

function value = opt(options, name, fallback)
if isstruct(options) && isfield(options, name) && ~isempty(options.(name))
  value = options.(name);
else
  value = fallback;
end
end

function tf = isKey(key, list)
tf = false;
for i = 1:numel(list)
  if strcmp(list{i}, key)
    tf = true;
    return;
  end
end
end
