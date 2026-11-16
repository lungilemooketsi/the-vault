function plotBudget(report, verdict, outPath, subtitle) %#ok<INUSD>
vault.useHeadless();
fig = figure('visible', 'off');
set(fig, 'position', [0 0 720 900]);
subplot(2, 1, 1);
cats = fieldnames(report.categories);
limits = zeros(1, numel(cats));
p50 = zeros(1, numel(cats));
for i = 1:numel(cats)
  limits(i) = report.categories.(cats{i}).limit;
  p50(i) = report.categories.(cats{i}).p50;
end
barh([limits(:) p50(:)]);
set(gca, 'ytick', 1:numel(cats), 'yticklabel', cats);
xlabel('ZAR');
title(['Budget ' verdict.code ' ' vault.formatRand(verdict.amount)]);
legend('limit', 'P50');
subplot(2, 1, 2);
plot([report.p10 report.p50 report.p90], 'o');
set(gca, 'xtick', 1:3, 'xticklabel', {'P10', 'P50', 'P90'});
ylabel('Month spend ZAR');
vault.printFig(fig, outPath);
end
