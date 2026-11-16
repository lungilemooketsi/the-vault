function test_habits_and_budget()
rules = vault.loadMerchantRules(fullfile(vault.repoRoot(), 'shared', 'merchant-rules.json'));
cfg = vault.loadConfig();
cfg.mode = 'mock';
client = vault.createClient(cfg);
[fromDate, toDate] = vault.sandboxWindow('2026-11-16');
[client, accounts] = vault.getAccounts(client);
current = vault.selectPrivateBank(accounts);
[~, payload] = vault.getTransactions(client, current.accountId, fromDate, toDate);
txns = vault.normalizeTransactions(payload, rules);
[withFill, info] = vault.backfillHistory(txns, '2026-11-16', true, 6, 1);
[noFill, infoOff] = vault.backfillHistory(txns, '2026-11-16', false, 6, 1);
check(info.enabled && numel(info.syntheticMonths) >= 1, 'back-fill adds synthetic months');
check(numel(noFill) == numel(txns) && isempty(infoOff.syntheticMonths), 'back-fill flag off keeps the sandbox months');
check(~isempty(strfind(vault.formatProvenance(info), 'Synthetic back-fill')), 'report names synthetic months'); %#ok<STREMP>
check(~isempty(strfind(vault.formatProvenance(info), '2026-08')), 'report names the real August month'); %#ok<STREMP>
origins = {withFill.origin};
check(any(strcmp(origins, 'sandbox')) && any(strcmp(origins, 'synthetic')), 'rows are labelled');
habits = vault.extractHabits(withFill, '2026-11-16', struct('minRecurringMonths', 2, 'recurringDayRange', 7));
check(habits.payday.found, 'salary-like credit is detected');
check(habits.payday.medianAmount > 20000, 'payday amount is the large STANCOM credit');
check(habits.weekendMultiplier > 0, 'weekend multiplier is learned');
weekend = syntheticWeekend();
check(weekend.weekendMultiplier > 1.5, 'a weekend-heavy history raises the multiplier');
foundVodacom = false;
for i = 1:numel(habits.recurring)
  if strcmp(habits.recurring(i).stem, 'vodacom') && strcmp(habits.recurring(i).direction, 'debit')
    foundVodacom = true;
  end
end
check(foundVodacom, 'vodacom debit orders group across changing refs');
user = vault.readJson(cfg.budgetPath);
user.limits.groceries = 1234;
budget = vault.generateBudget(habits, user);
check(budget.limits.groceries == 1234 && strcmp(budget.sources.groceries, 'user'), 'user limit overrides the suggestion');
check(budget.total >= budget.limits.groceries, 'total includes the override');
projection = vault.projectMonth(habits, withFill, budget, '2026-11-16', struct('nPaths', 80, 'seed', 3));
check(projection.p10 <= projection.p50 && projection.p50 <= projection.p90, 'fan is ordered');
verdict = vault.budgetVerdict(projection, budget);
check(any(strcmp(verdict.code, {'ON', 'UNDER', 'OVER'})), 'verdict is one of the three');
line = vault.formatVerdict(verdict);
check(strncmp(line, ['BUDGET ' verdict.code], 7 + numel(verdict.code)), 'verdict line leads with the code');
under.p10 = 7000; under.p50 = 8000; under.p90 = 9000; under.crossoverDate = [];
under.categories = struct();
b.total = 10000; b.underThresholdAbs = 100; b.underThresholdRatio = 0.05; b.limits = struct();
v = vault.budgetVerdict(under, b);
check(strcmp(v.code, 'UNDER') && abs(v.amount - 2000) < 1e-6, 'under amount is the P50 gap');
check(abs(v.sweep - 1000) < 1e-6 && strcmp(v.light, 'green'), 'sweep keeps P90 inside and the light is green');
over = under;
over.p50 = 12000; over.p90 = 13000; over.p10 = 11000;
over.categories.shopping.p50 = 4000; over.categories.shopping.limit = 900;
b.limits.shopping = 900; b.total = 10000;
v = vault.budgetVerdict(over, b);
check(strcmp(v.code, 'OVER') && strcmp(v.light, 'red'), 'over is red');
check(strcmp(v.drivers(1).category, 'shopping'), 'shopping drives the overshoot');
on = under; on.p50 = 9700; on.p90 = 9900; on.p10 = 9000; on.categories = struct();
b.total = 10000; b.limits = struct();
v = vault.budgetVerdict(on, b);
check(strcmp(v.code, 'ON') && strcmp(v.light, 'amber'), 'small surplus is ON / amber');
forecast = vault.forecastBalance(habits, 3000, '2026-11-16', struct('nPaths', 40, 'seed', 2, 'runwayBuffer', 2000, 'prestageThreshold', 1500));
check(forecast.p10(end) <= forecast.p50(end) && forecast.p50(end) <= forecast.p90(end), 'balance fan is ordered');
end

function habits = syntheticWeekend()
rules = vault.loadMerchantRules(fullfile(vault.repoRoot(), 'shared', 'merchant-rules.json'));
rows = struct('accountId', {}, 'type', {}, 'transactionType', {}, 'status', {}, 'description', {}, ...
  'postedOrder', {}, 'postingDate', {}, 'transactionDate', {}, 'amount', {}, 'origin', {});
% June-August 2026 are complete. Weekdays R100, Saturdays and Sundays R400.
for month = 6:8
  dim = datenum(2026, month + 1, 1) - datenum(2026, month, 1);
  for day = 1:dim
    dn = datenum(2026, month, day);
    w = weekday(dn);
    amount = 100;
    if w == 1 || w == 7
      amount = 400;
    end
    date = datestr(dn, 'yyyy-mm-dd');
    rows(end + 1).accountId = '1'; %#ok<AGROW>
    rows(end).type = 'DEBIT';
    rows(end).transactionType = 'CardPurchases';
    rows(end).status = 'POSTED';
    rows(end).description = 'CORNER CAFE';
    rows(end).postedOrder = 1;
    rows(end).postingDate = date;
    rows(end).transactionDate = date;
    rows(end).amount = amount;
    rows(end).origin = 'sandbox';
  end
end
txns = vault.normalizeTransactions(rows, rules);
habits = vault.extractHabits(txns, '2026-09-15', struct('minRecurringMonths', 2));
end
