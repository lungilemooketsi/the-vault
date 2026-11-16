function plotForecast(forecast, outPath, subtitle) %#ok<INUSD>
vault.useHeadless();
fig = figure('visible', 'off');
x = 1:numel(forecast.p50);
fill([x fliplr(x)], [forecast.p10 fliplr(forecast.p90)], [0.80 0.86 0.93], 'linestyle', 'none');
hold on;
plot(x, forecast.p50, 'linewidth', 2);
plot(x, forecast.p10, '--');
plot(x, forecast.p90, '--');
xlabel('Day');
ylabel('Balance ZAR');
title('30-day balance');
legend('P10-P90', 'P50');
vault.printFig(fig, outPath);
end
