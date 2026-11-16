function [fromDate, toDate] = sandboxWindow(asOf)
% Always pass both dates. Omitting fromDate makes the sandbox apply its
% default lookback, which dropped the 2026-08-11 card purchase.
if nargin < 1 || isempty(asOf)
  asOf = '2026-11-16';
end
fromDate = '2020-01-01';
toDate = vault.formatDate(vault.parseDate(asOf));
end
