function scene = buildScene(path)
raw = vault.readJson(path);
scene.rows = raw.rows;
scene.cols = raw.cols;
scene.cellSize = raw.cellSize;
occ = false(raw.rows, raw.cols);
for i = 1:numel(raw.obstacles)
  obstacle = raw.obstacles(i);
  r2 = min(raw.rows, obstacle.r + obstacle.h - 1);
  c2 = min(raw.cols, obstacle.c + obstacle.w - 1);
  occ(obstacle.r:r2, obstacle.c:c2) = true;
end
scene.occupancy = occ;
scene.landmarks.current = [raw.vaultCurrent.r, raw.vaultCurrent.c];
scene.landmarks.savings = [raw.vaultSavings.r, raw.vaultSavings.c];
scene.landmarks.counter = [raw.counter.r, raw.counter.c];
scene.landmarks.exit = [raw.exit.r, raw.exit.c];
scene.landmarks.stage = [raw.stage.r, raw.stage.c];
scene.robotStart = [raw.robotStart.r, raw.robotStart.c];
scene.barValue = raw.barValueRand;
end
