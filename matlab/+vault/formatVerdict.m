function line = formatVerdict(verdict)
switch verdict.code
  case 'OVER'
    line = sprintf('BUDGET OVER by %s.', vault.formatRand(verdict.amount));
    if ~isempty(verdict.drivers)
      bits = cell(1, numel(verdict.drivers));
      for i = 1:numel(verdict.drivers)
        bits{i} = sprintf('%s (+%s)', verdict.drivers(i).category, vault.formatRand(verdict.drivers(i).overshoot));
      end
      line = sprintf('%s Driven by %s.', line, vault.joinWith(bits, ', '));
    end
    if ~isempty(verdict.crossoverLabel)
      line = sprintf('%s Projected to cross the limit on %s.', line, verdict.crossoverLabel);
    end
  case 'UNDER'
    line = sprintf('BUDGET UNDER by %s.', vault.formatRand(verdict.amount));
    if verdict.sweep > 0
      line = sprintf(['%s Suggested savings sweep %s. This keeps the P90 path inside the budget ' ...
        'and still needs approval before any transfer.'], line, vault.formatRand(verdict.sweep));
    else
      line = sprintf(['%s No savings sweep suggested because the P90 path still crosses the budget. ' ...
        'Any transfer still needs approval.'], line);
    end
  otherwise
    line = sprintf('BUDGET ON. Projected P50 spend %s vs budget %s (P10 %s / P50 %s / P90 %s).', ...
      vault.formatRand(verdict.p50), vault.formatRand(verdict.budgetTotal), ...
      vault.formatRand(verdict.p10), vault.formatRand(verdict.p50), vault.formatRand(verdict.p90));
end
end
