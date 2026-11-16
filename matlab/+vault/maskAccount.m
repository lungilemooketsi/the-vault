function masked = maskAccount(value)
digits = regexprep(char(value), '\s+', '');
if numel(digits) <= 4
  masked = '****';
  return;
end
masked = ['****' digits(end-3:end)];
end
