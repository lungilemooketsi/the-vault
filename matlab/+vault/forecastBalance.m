function forecast = forecastBalance(habits, balance, asOf, options)
% 30-day balance fan. Payday credits and recurring debits come from habits.
% Runway is the first day the P50 balance drops below the buffer.
if nargin < 4
  options = struct();
end
nPaths = opt(options, 'nPaths', 400);
seed = opt(options, 'seed', 20261116);
horizon = opt(options, 'horizon', 30);
buffer = opt(options, 'runwayBuffer', 2000);
threshold = opt(options, 'prestageThreshold', 1500);
rng(seed + 17);
asOfDn = vault.parseDate(asOf);
paths = zeros(nPaths, horizon);
daily = zeros(nPaths, horizon);
dates = asOfDn + (1:horizon);
for p = 1:nPaths
  bal = balance;
  for d = 1:horizon
    dn = dates(d);
    dom = datevec(dn);
    dom = dom(3);
    spend = 0;
    income = 0;
    if ~isempty(habits.recurring)
      for i = 1:numel(habits.recurring)
        item = habits.recurring(i);
        if item.dayOfMonth ~= dom
          continue;
        end
        if strcmp(item.direction, 'debit')
          spend = spend + item.medianAmount;
        elseif strcmp(item.direction, 'credit')
          income = income + item.medianAmount;
        end
      end
    end
    if vault.isWeekend(dn)
      pool = habits.weekendPool;
    else
      pool = habits.weekdayPool;
    end
    if ~isempty(pool)
      factor = 1;
      if numel(habits.domFactor) >= dom
        factor = habits.domFactor(dom);
      end
      spend = spend + max(0, pool(randi(numel(pool))) * factor);
    end
    net = income - spend;
    bal = bal + net;
    paths(p, d) = bal;
    daily(p, d) = spend;
  end
end
forecast.dates = dates;
forecast.p10 = zeros(1, horizon);
forecast.p50 = zeros(1, horizon);
forecast.p90 = zeros(1, horizon);
forecast.spendP50 = zeros(1, horizon);
for d = 1:horizon
  forecast.p10(d) = vault.percentile(paths(:, d), 10);
  forecast.p50(d) = vault.percentile(paths(:, d), 50);
  forecast.p90(d) = vault.percentile(paths(:, d), 90);
  forecast.spendP50(d) = vault.percentile(daily(:, d), 50);
end
forecast.runwayDays = horizon;
forecast.runwayShort = false;
for d = 1:horizon
  if forecast.p50(d) < buffer
    forecast.runwayDays = d;
    break;
  end
end
forecast.runwayShort = forecast.runwayDays < opt(options, 'runwayWarnDays', 7);
forecast.prestage = false;
forecast.prestageDate = [];
for d = 1:min(7, horizon)
  if forecast.spendP50(d) >= threshold
    forecast.prestage = true;
    forecast.prestageDate = dates(d);
    break;
  end
end
forecast.balance = balance;
forecast.buffer = buffer;
forecast.beacon = 'off';
if forecast.runwayShort
  forecast.beacon = 'amber';
end
end

function value = opt(options, name, fallback)
if isstruct(options) && isfield(options, name) && ~isempty(options.(name))
  value = options.(name);
else
  value = fallback;
end
end
