function renderScene(scene, state, outPath)
vault.useHeadless();
fig = figure('visible', 'off');
imagesc(~scene.occupancy);
colormap(gray);
hold on;
if isfield(state, 'path') && ~isempty(state.path)
  plot(state.path(:, 2), state.path(:, 1), 'linewidth', 2);
end
plot(state.robot(2), state.robot(1), 'o', 'markersize', 10);
plot(scene.landmarks.counter(2), scene.landmarks.counter(1), 's');
plot(scene.landmarks.exit(2), scene.landmarks.exit(1), 'd');
plot(scene.landmarks.current(2), scene.landmarks.current(1), '^');
plot(scene.landmarks.savings(2), scene.landmarks.savings(1), 'v');
title(sprintf('floor %s | counter %s | arm %s', state.floor, state.counter, state.arm));
vault.printFig(fig, outPath);
end
