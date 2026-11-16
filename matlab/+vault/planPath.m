function result = planPath(occ, startRc, goalRc)
result.ok = false;
result.path = zeros(0, 2);
result.cost = inf;
rows = size(occ, 1);
cols = size(occ, 2);
if any(startRc < 1) || any(goalRc < 1) || startRc(1) > rows || goalRc(1) > rows || startRc(2) > cols || goalRc(2) > cols
  return;
end
if occ(startRc(1), startRc(2)) || occ(goalRc(1), goalRc(2))
  return;
end
if all(startRc == goalRc)
  result.ok = true;
  result.path = startRc;
  result.cost = 0;
  return;
end
start = sub2ind([rows cols], startRc(1), startRc(2));
goal = sub2ind([rows cols], goalRc(1), goalRc(2));
g = inf(rows, cols);
g(startRc(1), startRc(2)) = 0;
parent = zeros(rows, cols);
open = start;
inOpen = false(rows, cols);
inOpen(startRc(1), startRc(2)) = true;
closed = false(rows, cols);
nbr = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
stepCost = [14; 10; 14; 10; 10; 14; 10; 14];
while ~isempty(open)
  bestI = 1;
  bestF = inf;
  for i = 1:numel(open)
    [r, c] = ind2sub([rows cols], open(i));
    h = 10 * (abs(r - goalRc(1)) + abs(c - goalRc(2)));
    f = g(r, c) + h;
    if f < bestF
      bestF = f;
      bestI = i;
    end
  end
  current = open(bestI);
  open(bestI) = [];
  [r, c] = ind2sub([rows cols], current);
  inOpen(r, c) = false;
  if current == goal
    result.ok = true;
    result.cost = g(r, c);
    path = zeros(0, 2);
    while current ~= 0
      [rr, cc] = ind2sub([rows cols], current);
      path = [rr cc; path]; %#ok<AGROW>
      if current == start
        break;
      end
      current = parent(rr, cc);
    end
    result.path = path;
    return;
  end
  closed(r, c) = true;
  for k = 1:8
    rr = r + nbr(k, 1);
    cc = c + nbr(k, 2);
    if rr < 1 || cc < 1 || rr > rows || cc > cols || occ(rr, cc) || closed(rr, cc)
      continue;
    end
    if nbr(k, 1) ~= 0 && nbr(k, 2) ~= 0
      if occ(r, cc) || occ(rr, c)
        continue;
      end
    end
    tentative = g(r, c) + stepCost(k);
    if tentative < g(rr, cc)
      g(rr, cc) = tentative;
      parent(rr, cc) = current;
      if ~inOpen(rr, cc)
        open(end + 1) = sub2ind([rows cols], rr, cc); %#ok<AGROW>
        inOpen(rr, cc) = true;
      end
    end
  end
end
end
