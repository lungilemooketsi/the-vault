function value = percentile(samples, pct)
% Linear percentile, NIST / PERCENTILE.INC style.
samples = sort(samples(:));
n = numel(samples);
if n == 0
  value = NaN;
  return;
end
if n == 1
  value = samples(1);
  return;
end
rank = 1 + (pct / 100) * (n - 1);
lo = floor(rank);
hi = ceil(rank);
if lo < 1
  lo = 1;
end
if hi > n
  hi = n;
end
frac = rank - lo;
value = samples(lo) * (1 - frac) + samples(hi) * frac;
end
