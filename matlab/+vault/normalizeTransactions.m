function txns = normalizeTransactions(raw, rules)
%normalizeTransactions  API rows -> struct array used by the coach.
% Habits use transactionDate. actionDate on the sandbox is the snapshot day
% for every row, so it is ignored. PENDING and postedOrder 0 are dropped.
if isfield(raw, 'data') && isfield(raw.data, 'transactions')
  rows = raw.data.transactions;
else
  rows = raw;
end
blank = emptyTxn();
if isempty(rows)
  txns = blank;
  return;
end
kept = blank;
for i = 1:numel(rows)
  row = rows(i);
  status = fieldOr(row, 'status', 'POSTED');
  if strcmpi(char(status), 'PENDING')
    continue;
  end
  posted = fieldOr(row, 'postedOrder', 1);
  if isnumeric(posted) && posted == 0
    continue;
  end
  dateText = fieldOr(row, 'transactionDate', '');
  if isempty(dateText)
    dateText = fieldOr(row, 'postingDate', '');
  end
  if isempty(dateText)
    continue;
  end
  direction = upper(char(fieldOr(row, 'type', '')));
  amount = fieldOr(row, 'amount', 0);
  amount = double(amount);
  if isempty(direction)
    if amount < 0
      direction = 'DEBIT';
    else
      direction = 'CREDIT';
    end
  end
  if strcmp(direction, 'DEBIT')
    flow = 'debit';
  else
    flow = 'credit';
  end
  description = char(fieldOr(row, 'description', ''));
  transactionType = char(fieldOr(row, 'transactionType', ''));
  item = blank;
  item(1).dn = vault.parseDate(dateText);
  item.dom = datevec(item.dn);
  item.dom = item.dom(3);
  item.month = vault.monthKey(item.dn);
  item.amount = abs(amount);
  item.direction = flow;
  item.transactionType = transactionType;
  item.description = description;
  item.stem = vault.merchantStem(description);
  item.category = vault.classifyTransaction(description, transactionType, rules);
  item.origin = char(fieldOr(row, 'origin', 'sandbox'));
  item.status = char(status);
  item.accountId = char(fieldOr(row, 'accountId', ''));
  if isempty(kept)
    kept = item;
  else
    kept(end + 1) = item; %#ok<AGROW>
  end
end
txns = kept;
end

function item = emptyTxn()
item = struct( ...
  'dn', {}, 'dom', {}, 'month', {}, 'amount', {}, 'direction', {}, ...
  'transactionType', {}, 'description', {}, 'stem', {}, 'category', {}, ...
  'origin', {}, 'status', {}, 'accountId', {});
end

function value = fieldOr(row, name, fallback)
if isfield(row, name) && ~isempty(row.(name))
  value = row.(name);
else
  value = fallback;
end
end
