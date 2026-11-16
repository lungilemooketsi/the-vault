function c = isoCmp(a, b)
% Scalar comparison for YYYY-MM and YYYY-MM-DD text. Char < is elementwise.
a = char(a);
b = char(b);
n = min(numel(a), numel(b));
for i = 1:n
  if a(i) < b(i)
    c = -1;
    return;
  elseif a(i) > b(i)
    c = 1;
    return;
  end
end
if numel(a) < numel(b)
  c = -1;
elseif numel(a) > numel(b)
  c = 1;
else
  c = 0;
end
end
