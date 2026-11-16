function verdict = budgetVerdict(report, budget)
% OVER when P50 spend exceeds the budget.
% UNDER when the P50 gap is at least the larger of R100 and 5% (configurable).
% ON for a smaller surplus. The sweep is budget minus P90 so the pessimistic
% path still lands inside the budget, and it is never executed here.
p50 = report.p50;
p10 = report.p10;
p90 = report.p90;
total = budget.total;
gap = total - p50;
threshold = max(budget.underThresholdAbs, budget.underThresholdRatio * total);
verdict.p10 = p10;
verdict.p50 = p50;
verdict.p90 = p90;
verdict.budgetTotal = total;
verdict.drivers = emptyDrivers();
verdict.crossoverDate = [];
verdict.crossoverLabel = '';
if isfield(report, 'crossoverDate') && ~isempty(report.crossoverDate)
  verdict.crossoverDate = report.crossoverDate;
  verdict.crossoverLabel = datestr(report.crossoverDate, 'dd mmm yyyy');
end
if p50 > total + 1e-6
  verdict.code = 'OVER';
  verdict.amount = p50 - total;
  verdict.sweep = 0;
  verdict.drivers = driversOf(report, budget);
elseif gap >= threshold
  verdict.code = 'UNDER';
  verdict.amount = gap;
  verdict.sweep = max(0, total - p90);
else
  verdict.code = 'ON';
  verdict.amount = max(0, gap);
  verdict.sweep = 0;
end
verdict.light = lightFor(verdict.code);
end

function light = lightFor(code)
if strcmp(code, 'UNDER')
  light = 'green';
elseif strcmp(code, 'OVER')
  light = 'red';
else
  light = 'amber';
end
end

function rows = driversOf(report, budget)
rows = emptyDrivers();
if ~isfield(report, 'categories')
  return;
end
cats = fieldnames(report.categories);
for i = 1:numel(cats)
  cat = cats{i};
  entry = report.categories.(cat);
  limit = 0;
  if isfield(budget.limits, cat)
    limit = budget.limits.(cat);
  elseif isfield(entry, 'limit')
    limit = entry.limit;
  end
  overshoot = entry.p50 - limit;
  if overshoot > 0.5
    row.category = cat;
    row.overshoot = overshoot;
    row.p50 = entry.p50;
    row.limit = limit;
    if isempty(rows)
      rows = row;
    else
      rows(end + 1) = row; %#ok<AGROW>
    end
  end
end
if numel(rows) > 1
  [~, order] = sort([rows.overshoot], 'descend');
  rows = rows(order);
end
end

function rows = emptyDrivers()
rows = struct('category', {}, 'overshoot', {}, 'p50', {}, 'limit', {});
end
