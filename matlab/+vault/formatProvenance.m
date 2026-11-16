function line = formatProvenance(info)
realBits = cell(1, numel(info.realMonths));
for i = 1:numel(info.realMonths)
  key = info.realMonths{i};
  label = key;
  if isKey(key, info.partialMonths)
    label = [key ' (partial)'];
  end
  if isfield(info, 'inProgress') && strcmp(key, info.inProgress)
    label = [key ' (in progress)'];
  end
  realBits{i} = label;
end
if isempty(realBits)
  realText = 'none';
else
  realText = vault.joinWith(realBits, ', ');
end
if info.enabled && ~isempty(info.syntheticMonths)
  syntheticText = vault.joinWith(info.syntheticMonths, ', ');
else
  syntheticText = 'none';
end
line = sprintf('HISTORY real: %s. Synthetic back-fill: %s.', realText, syntheticText);
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
