function text = formatRand(amount)
negative = amount < 0;
cents = round(abs(amount) * 100);
rands = floor(cents / 100);
rem = mod(cents, 100);
raw = sprintf('%d', rands);
out = '';
while numel(raw) > 3
  out = [' ' raw(end-2:end) out]; %#ok<AGROW>
  raw = raw(1:end-3);
end
out = [raw out];
text = sprintf('R%s.%02d', out, rem);
if negative
  text = ['-' text];
end
end
