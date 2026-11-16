function test_motion()
occ = false(7, 9);
occ(4, 5) = true;
planned = vault.planPath(occ, [4 1], [4 9]);
check(planned.ok, 'path exists around a pillar');
check(all(planned.path(1, :) == [4 1]) && all(planned.path(end, :) == [4 9]), 'path meets the ends');
for i = 1:size(planned.path, 1)
  check(~occ(planned.path(i, 1), planned.path(i, 2)), 'path stays on free cells');
  if i > 1
    step = abs(planned.path(i, :) - planned.path(i - 1, :));
    check(max(step) == 1 && ~(step(1) == 0 && step(2) == 0), 'path is contiguous');
  end
end
blocked = vault.planPath(true(3, 3), [2 1], [2 3]);
check(~blocked.ok, 'a solid wall has no path');
same = vault.planPath(occ, [4 1], [4 1]);
check(same.ok && size(same.path, 1) == 1, 'start is the goal');
fleetOcc = true(4, 6);
fleetOcc(2, :) = false;
fleetOcc(3, :) = false;
jobs(1).id = 'high';
jobs(1).start = [2 1];
jobs(1).goal = [2 6];
jobs(1).priority = 2;
jobs(2).id = 'low';
jobs(2).start = [2 6];
jobs(2).goal = [2 1];
jobs(2).priority = 1;
plans = vault.planFleet(fleetOcc, jobs);
check(plans(1).ok && plans(2).ok, 'both robots arrive');
horizon = max([plans(1).times plans(2).times]);
for t = 1:horizon
  cells = zeros(0, 2);
  for r = 1:2
    idx = find(plans(r).times == t, 1);
    if ~isempty(idx)
      cells = [cells; plans(r).path(idx, :)]; %#ok<AGROW>
    end
  end
  if size(cells, 1) == 2
    check(~(cells(1, 1) == cells(2, 1) && cells(1, 2) == cells(2, 2)), 'robots do not share a cell');
  end
end
tip = [0.25 0.04 0.15];
q = vault.armIk(tip);
[back, ~] = vault.armFk(q);
check(norm(back - tip) < 1e-6, 'arm IK matches FK');
locked = vault.armPose('lock');
check(locked.locked, 'declined pose locks the arm');
place = vault.armPose('place');
check(~place.locked && numel(place.q) == 4, 'place pose is a 4-joint configuration');
end
