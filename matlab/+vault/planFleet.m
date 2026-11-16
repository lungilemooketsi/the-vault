function plans = planFleet(occ, jobs)
% Priority space-time planner. Higher priority moves first and reserves
% the cells it occupies, including the goal after arrival. The next robot
% may wait or take another corridor. Two robots never share a cell at the
% same time, and they cannot swap through each other.
[~, order] = sort([jobs.priority], 'descend');
horizon = 40;
rows = size(occ, 1);
cols = size(occ, 2);
reserved = false(rows, cols, horizon);
cameFrom = zeros(rows, cols, horizon);
plans = jobs;
for n = 1:numel(order)
  index = order(n);
  planned = planOne(occ, reserved, cameFrom, jobs(index).start, jobs(index).goal, horizon);
  plans(index).ok = planned.ok;
  plans(index).path = planned.cells;
  plans(index).times = planned.times;
  if ~planned.ok
    continue;
  end
  for s = 1:numel(planned.times)
    t = planned.times(s);
    cell = planned.cells(s, :);
    reserved(cell(1), cell(2), t) = true;
    if s == 1
      cameFrom(cell(1), cell(2), t) = 0;
    else
      cameFrom(cell(1), cell(2), t) = sub2ind([rows cols], planned.cells(s - 1, 1), planned.cells(s - 1, 2));
    end
  end
  last = planned.cells(end, :);
  lastT = planned.times(end);
  for t = lastT:horizon
    reserved(last(1), last(2), t) = true;
  end
end
end

function planned = planOne(occ, reserved, cameFrom, startRc, goalRc, horizon)
rows = size(occ, 1);
cols = size(occ, 2);
planned.ok = false;
planned.cells = zeros(0, 2);
planned.times = [];
startLin = sub2ind([rows cols], startRc(1), startRc(2));
goalLin = sub2ind([rows cols], goalRc(1), goalRc(2));
g = inf(rows, cols, horizon);
parent = zeros(rows, cols, horizon);
parentTime = zeros(rows, cols, horizon);
g(startRc(1), startRc(2), 1) = 0;
open = [startLin 1];
nbr = [0 0; -1 0; 1 0; 0 -1; 0 1; -1 -1; -1 1; 1 -1; 1 1];
while ~isempty(open)
  best = 1;
  bestF = inf;
  for i = 1:size(open, 1)
    [r, c] = ind2sub([rows cols], open(i, 1));
    t = open(i, 2);
    h = abs(r - goalRc(1)) + abs(c - goalRc(2));
    f = g(r, c, t) + h;
    if f < bestF
      bestF = f;
      best = i;
    end
  end
  current = open(best, :);
  open(best, :) = [];
  [r, c] = ind2sub([rows cols], current(1));
  t = current(2);
  if current(1) == goalLin
    planned.ok = true;
    cells = zeros(0, 2);
    times = [];
    lin = current(1);
    tt = t;
    while tt ~= 0
      [rr, cc] = ind2sub([rows cols], lin);
      cells = [rr cc; cells]; %#ok<AGROW>
      times = [tt times]; %#ok<AGROW>
      nextLin = parent(rr, cc, tt);
      nextT = parentTime(rr, cc, tt);
      lin = nextLin;
      tt = nextT;
      if nextT == 0
        break;
      end
    end
    planned.cells = cells;
    planned.times = times;
    return;
  end
  if t == horizon
    continue;
  end
  for k = 1:size(nbr, 1)
    rr = r + nbr(k, 1);
    cc = c + nbr(k, 2);
    if rr < 1 || cc < 1 || rr > rows || cc > cols || occ(rr, cc)
      continue;
    end
    if reserved(rr, cc, t + 1)
      continue;
    end
    if nbr(k, 1) ~= 0 || nbr(k, 2) ~= 0
      if reserved(rr, cc, t) && reserved(r, c, t + 1)
        if cameFrom(r, c, t + 1) == sub2ind([rows cols], rr, cc)
          continue;
        end
      end
    end
    tentative = g(r, c, t) + 1;
    if tentative < g(rr, cc, t + 1)
      g(rr, cc, t + 1) = tentative;
      parent(rr, cc, t + 1) = current(1);
      parentTime(rr, cc, t + 1) = t;
      open(end + 1, :) = [sub2ind([rows cols], rr, cc) t + 1]; %#ok<AGROW>
    end
  end
end
end
