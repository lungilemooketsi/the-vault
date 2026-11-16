function [txns, info] = backfillHistory(txns, asOf, enabled, targetBaseline, seed)
%backfillHistory  Clone complete real months backward when history is short.
% Synthetic rows are perturbed card/payment spend. Salary, debit orders,
% fees and VAS amounts are copied so fuzzy recurrence still matches.
% Set enabled false to learn from the sandbox months only.
if nargin < 4 || isempty(targetBaseline)
  targetBaseline = 6;
end
if nargin < 5 || isempty(seed)
  seed = 20261116;
end
info = blankInfo();
info.enabled = logical(enabled);
if isempty(txns)
  return;
end
asOfDn = vault.parseDate(asOf);
current = vault.monthKey(asOfDn);
facts = monthFacts(txns);
info.realMonths = facts.real;
info.partialMonths = facts.partial;
info.inProgress = current;
complete = {};
for i = 1:numel(facts.real)
  key = facts.real{i};
  if vault.isoCmp(key, current) == 0 || ismemberKey(key, facts.partial)
    continue;
  end
  if vault.isoCmp(key, current) < 0
    complete{end + 1} = key; %#ok<AGROW>
  end
end
info.templateMonths = complete;
if ~enabled || numel(complete) == 0 || numel(complete) >= targetBaseline
  info.note = 'Synthetic back-fill is off or not needed.';
  return;
end
needed = targetBaseline - numel(complete);
earliest = facts.real{1};
cursor = vault.addMonths(vault.parseDate([earliest '-01']), -1);
rng(seed);
clones = txns(false);
for k = 1:needed
  templateKey = complete{numel(complete) - mod(k - 1, numel(complete))};
  targetKey = vault.monthKey(cursor);
  info.syntheticMonths{end + 1} = targetKey; %#ok<AGROW>
  delta = monthDelta(templateKey, targetKey);
  for i = 1:numel(txns)
    if ~strcmp(txns(i).month, templateKey) || ~strcmp(txns(i).origin, 'sandbox')
      continue;
    end
    clone = txns(i);
    clone.dn = vault.addMonths(txns(i).dn, delta);
    dv = datevec(clone.dn);
    clone.dom = dv(3);
    clone.month = vault.monthKey(clone.dn);
    clone.origin = 'synthetic';
    if perturb(clone.transactionType)
      factor = 0.92 + 0.16 * rand();
      clone.amount = round(clone.amount * factor * 100) / 100;
    end
    if isempty(clones)
      clones = clone;
    else
      clones(end + 1) = clone; %#ok<AGROW>
    end
  end
  cursor = vault.addMonths(cursor, -1);
end
info.syntheticMonths = sort(info.syntheticMonths);
if ~isempty(clones)
  txns = [clones txns];
end
[~, order] = sort([txns.dn]);
txns = txns(order);
info.note = 'Synthetic months clone the real complete months with perturbed card spend.';
end

function info = blankInfo()
info.enabled = false;
info.realMonths = {};
info.partialMonths = {};
info.syntheticMonths = {};
info.templateMonths = {};
info.inProgress = '';
info.note = '';
end

function facts = monthFacts(txns)
keys = {};
for i = 1:numel(txns)
  if ~ismemberKey(txns(i).month, keys)
    keys{end + 1} = txns(i).month; %#ok<AGROW>
  end
end
keys = sort(keys);
real = {};
partial = {};
for i = 1:numel(keys)
  key = keys{i};
  doms = [];
  realMonth = false;
  for j = 1:numel(txns)
    if strcmp(txns(j).month, key)
      doms(end + 1) = txns(j).dom; %#ok<AGROW>
      if strcmp(txns(j).origin, 'sandbox')
        realMonth = true;
      end
    end
  end
  if realMonth
    real{end + 1} = key; %#ok<AGROW>
  end
  if ~isempty(doms) && (min(doms) > 1 || max(doms) < 28)
    partial{end + 1} = key; %#ok<AGROW>
  end
end
facts.real = real;
facts.partial = partial;
end

function tf = ismemberKey(key, list)
tf = false;
for i = 1:numel(list)
  if strcmp(list{i}, key)
    tf = true;
    return;
  end
end
end

function delta = monthDelta(fromKey, toKey)
fromDn = vault.parseDate([fromKey '-01']);
toDn = vault.parseDate([toKey '-01']);
fv = datevec(fromDn);
tv = datevec(toDn);
delta = (tv(1) - fv(1)) * 12 + (tv(2) - fv(2));
end

function tf = perturb(transactionType)
tf = strcmp(transactionType, 'CardPurchases') || strcmp(transactionType, 'ATMWithdrawals') ...
  || strcmp(transactionType, 'OnlineBankingPayments') || strcmp(transactionType, 'FasterPay');
end
