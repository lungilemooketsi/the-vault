function key = merchantStem(description)
%merchantStem  Fuzzy merchant key. Digits and one-letter tokens are dropped
% so VODACOM 0397 and VODACOM 0401 share a stem, while STANCOM salary and
% STANCOM weekly pay stay apart.
s = lower(char(description));
s = regexprep(s, '[0-9]+', ' ');
s = regexprep(s, '[^a-z ]', ' ');
s = regexprep(s, ' +', ' ');
s = strtrim(s);
if isempty(s)
  key = '';
  return;
end
parts = splitWords(s);
kept = {};
for i = 1:numel(parts)
  if numel(parts{i}) > 1
    kept{end + 1} = parts{i}; %#ok<AGROW>
  end
end
n = min(3, numel(kept));
if n == 0
  key = '';
  return;
end
key = kept{1};
for i = 2:n
  key = [key ' ' kept{i}]; %#ok<AGROW>
end
end

function parts = splitWords(s)
parts = {};
s = strtrim(s);
while ~isempty(s)
  sp = strfind(s, ' ');
  if isempty(sp)
    parts{end + 1} = s; %#ok<AGROW>
    break;
  end
  parts{end + 1} = s(1:sp(1) - 1); %#ok<AGROW>
  s = strtrim(s(sp(1) + 1:end));
end
end
