function text = joinWith(parts, sep)
if isempty(parts)
  text = '';
  return;
end
text = parts{1};
for i = 2:numel(parts)
  text = [text sep parts{i}]; %#ok<AGROW>
end
end
