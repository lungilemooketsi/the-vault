function dn = parseDate(value)
if isnumeric(value)
  dn = value(1);
  return;
end
parts = sscanf(char(value), '%d-%d-%d');
if numel(parts) < 3
  error('vault:date', 'Expected a YYYY-MM-DD date.');
end
dn = datenum(parts(1), parts(2), parts(3));
end
