function report = runDemo(varargin)
%runDemo  Scripted vault slice. Sandbox when credentials are set, otherwise
% the offline snapshot. Transfers are approved on screen in this script and
% are not posted to the shared sandbox unless VAULT_ALLOW_LIVE_TRANSFER=1.
opts = parseOpts(varargin{:});
cfg = vault.loadConfig();
if ~isempty(opts.mode)
  cfg.mode = opts.mode;
end
if opts.backfillSet
  cfg.backfill = opts.backfill;
end
client = vault.createClient(cfg);
rules = vault.loadMerchantRules(cfg.rulesPath);
user = vault.readJson(cfg.budgetPath);
[fromDate, toDate] = vault.sandboxWindow(cfg.asOf);
[client, accounts] = vault.getAccounts(client);
summary = vault.formatAccountSummary(accounts);
current = vault.selectPrivateBank(accounts);
savings = vault.selectSavings(accounts, current.profileId);
[client, balance] = vault.getBalance(client, current.accountId);
[client, txPayload] = vault.getTransactions(client, current.accountId, fromDate, toDate);
[client, pending, pendingInfo] = vault.getPending(client, current.accountId);
[client, ~, cardInfo] = vault.getCards(client);
txns = vault.normalizeTransactions(txPayload, rules);
[txns, provenance] = vault.backfillHistory(txns, cfg.asOf, cfg.backfill, 6, 20261116);
habitOpts.minRecurringMonths = 2;
habitOpts.recurringDayRange = 7;
habitOpts.recurringAmountTolerance = 0.15;
habits = vault.extractHabits(txns, cfg.asOf, habitOpts);
budget = vault.generateBudget(habits, user);
projection = vault.projectMonth(habits, txns, budget, cfg.asOf, struct('nPaths', opts.nPaths, 'seed', 20261116));
verdict = vault.budgetVerdict(projection, budget);
forecast = vault.forecastBalance(habits, balance.currentBalance, cfg.asOf, struct( ...
  'nPaths', opts.nPaths, 'seed', 20261116, 'runwayBuffer', user.runwayBuffer, ...
  'prestageThreshold', user.prestageThreshold, 'runwayWarnDays', user.runwayWarnDays));
verdictLine = vault.formatVerdict(verdict);
provenanceLine = vault.formatProvenance(provenance);
envPath = fullfile(cfg.root, 'card-code', 'env.json');
vault.writeCardEnv(envPath, budget, projection.mtd, rules, cfg.webhookUrl);
scene = vault.buildScene(fullfile(cfg.fixtureDir, 'scene.json'));
state.floor = verdict.light;
state.counter = 'off';
state.arm = 'home';
state.robot = scene.robotStart;
state.path = zeros(0, 2);
state.prestage = forecast.prestage;
if forecast.prestage
  planned = vault.planPath(scene.occupancy, state.robot, scene.landmarks.stage);
  state.path = planned.path;
  if planned.ok
    state.robot = planned.path(end, :);
  end
end
remaining = remainingMap(budget, projection.mtd);
[approveCents, approveMerchant, declineCents, declineMerchant] = chooseSwipes(remaining);
[approved, approveCat] = vault.evaluateSwipe(approveCents, approveMerchant, rules, remaining, 50000);
[declined, declineCat] = vault.evaluateSwipe(declineCents, declineMerchant, rules, remaining, 50000);
declineState = state;
declineState.arm = 'lock';
declineState.counter = 'red';
declineState.locked = true;
approveState = state;
approveState.arm = 'place';
approveState.counter = 'green';
approveState.locked = false;
approvePlan = vault.planPath(scene.occupancy, approveState.robot, scene.landmarks.exit);
approveState.path = approvePlan.path;
if approvePlan.ok
  approveState.robot = approvePlan.path(end, :);
end
proposal = vault.proposeTransfer(current, savings, 250, 'Vault floor', 'Savings vault');
review = formatReview(proposal);
decision = vault.decideApproval(proposal, 'APPROVE', 'scripted on-screen review');
[client, transfer] = vault.transferMultiple(client, proposal, decision);
transferPlan = vault.planPath(scene.occupancy, scene.landmarks.current, scene.landmarks.savings);
if opts.plots
  outDir = fullfile(cfg.root, 'matlab', 'output');
  if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
  end
  safePlot(@() vault.plotBudget(projection, verdict, fullfile(outDir, 'budget.png'), provenanceLine));
  safePlot(@() vault.plotForecast(forecast, fullfile(outDir, 'forecast.png'), provenanceLine));
  safePlot(@() vault.renderScene(scene, declineState, fullfile(outDir, 'declined-swipe.png')));
  safePlot(@() vault.renderScene(scene, approveState, fullfile(outDir, 'approved-swipe.png')));
  shown = approveState;
  shown.path = transferPlan.path;
  shown.floor = verdict.light;
  safePlot(@() vault.renderScene(scene, shown, fullfile(outDir, 'transfer.png')));
end
report.mode = client.mode;
report.usingSandboxCredentials = strcmp(client.mode, 'sandbox');
report.asOf = cfg.asOf;
report.fromDate = fromDate;
report.toDate = toDate;
report.accounts = summary;
report.balance = balance.currentBalance;
report.pendingCount = numel(pending);
report.pendingWarning = pendingInfo.warning;
report.cardsAvailable = cardInfo.available;
report.cardsWarning = cardInfo.warning;
report.provenanceLine = provenanceLine;
report.verdictLine = verdictLine;
report.verdict = verdict;
report.forecast = forecast;
report.weekendMultiplier = habits.weekendMultiplier;
report.review = review;
report.transfer = transfer;
report.approvedSwipe = struct('merchant', approveMerchant, 'cents', approveCents, 'approved', approved, 'category', approveCat, 'pathOk', approvePlan.ok);
report.declinedSwipe = struct('merchant', declineMerchant, 'cents', declineCents, 'approved', declined, 'category', declineCat);
report.transferPathOk = transferPlan.ok;
report.arm = vault.armPose('place');
report.calls = numel(client.calls);
if opts.stress
  report.stress = stressReplay(txns, remaining, rules);
end
printReport(report);
end

function opts = parseOpts(varargin)
opts.mode = '';
opts.backfill = true;
opts.backfillSet = false;
opts.plots = true;
opts.nPaths = 300;
opts.stress = false;
i = 1;
while i <= numel(varargin)
  key = varargin{i};
  if strcmp(key, 'mode')
    opts.mode = varargin{i + 1};
    i = i + 2;
  elseif strcmp(key, 'backfill')
    opts.backfill = logical(varargin{i + 1});
    opts.backfillSet = true;
    i = i + 2;
  elseif strcmp(key, 'plots')
    opts.plots = logical(varargin{i + 1});
    i = i + 2;
  elseif strcmp(key, 'nPaths')
    opts.nPaths = varargin{i + 1};
    i = i + 2;
  elseif strcmp(key, 'stress')
    opts.stress = logical(varargin{i + 1});
    i = i + 2;
  else
    i = i + 1;
  end
end
end

function remaining = remainingMap(budget, mtd)
remaining = struct();
cats = fieldnames(budget.limits);
for i = 1:numel(cats)
  spent = 0;
  if isfield(mtd, cats{i})
    spent = mtd.(cats{i});
  end
  remaining.(cats{i}) = max(0, round((budget.limits.(cats{i}) - spent) * 100));
end
end

function [approveCents, approveMerchant, declineCents, declineMerchant] = chooseSwipes(remaining)
approveCents = 20000;
approveMerchant = 'Woolworths Sandton';
declineCents = 250000;
declineMerchant = 'Takealot';
if isfield(remaining, 'groceries') && remaining.groceries >= approveCents
  approveMerchant = 'Woolworths Sandton';
elseif isfield(remaining, 'card') && remaining.card >= approveCents
  approveMerchant = 'Corner Cafe';
end
if isfield(remaining, 'shopping') && remaining.shopping < declineCents
  declineMerchant = 'Takealot';
else
  declineCents = 9000000;
  declineMerchant = 'Corner Cafe';
end
end

function text = formatReview(proposal)
text = sprintf('TRANSFER REVIEW\nFrom %s\nTo %s\nAmount %s\nReference %s\nNothing has been sent. APPROVE is required before transfermultiple.', ...
  proposal.fromMasked, proposal.toMasked, vault.formatRand(proposal.amountNumber), proposal.myReference);
end

function summary = stressReplay(txns, remaining, rules)
rng(20261116);
approved = 0;
declined = 0;
descriptions = {};
for i = 1:numel(txns)
  if strcmp(txns(i).transactionType, 'CardPurchases')
    descriptions{end + 1} = txns(i).description; %#ok<AGROW>
  end
end
if isempty(descriptions)
  descriptions = {'Woolworths Sandton'};
end
for n = 1:40
  desc = descriptions{randi(numel(descriptions))};
  cents = randi([1500, 80000]);
  ok = vault.evaluateSwipe(cents, desc, rules, remaining, 50000);
  if ok
    approved = approved + 1;
  else
    declined = declined + 1;
  end
end
summary.approved = approved;
summary.declined = declined;
summary.events = approved + declined;
end

function printReport(report)
fprintf('\nThe Vault  (%s, as of %s)\n', report.mode, report.asOf);
if ~report.usingSandboxCredentials
  fprintf('Sandbox credentials are not set, so this run used the offline snapshot of the public sandbox.\n');
  fprintf('To pull live: export INVESTEC_CLIENT_ID, INVESTEC_CLIENT_SECRET and INVESTEC_API_KEY from the Private Bank API docs.\n');
end
fprintf('%s\n', report.provenanceLine);
fprintf('%s\n', report.verdictLine);
fprintf('Balance used for the fan: %s. Runway %d day(s). Beacon %s. Pre-stage %d. Weekend/weekday spend ratio %.2f.\n', ...
  vault.formatRand(report.balance), report.forecast.runwayDays, report.forecast.beacon, report.forecast.prestage, report.weekendMultiplier);
fprintf('Pending rows: %d. %s\n', report.pendingCount, report.pendingWarning);
fprintf('Cards API: %s\n', report.cardsWarning);
fprintf('%s\n', report.review);
fprintf('Transfer status: %s\n', report.transfer.message);
fprintf('Approved swipe %s (%s) -> %d. Declined swipe %s -> %d.\n', ...
  report.approvedSwipe.merchant, report.approvedSwipe.category, report.approvedSwipe.approved, ...
  report.declinedSwipe.merchant, report.declinedSwipe.approved);
end

function safePlot(fn)
try
  fn();
catch err
  fprintf('Figure skipped: %s\n', vault.scrubSecrets(err.message));
end
end
