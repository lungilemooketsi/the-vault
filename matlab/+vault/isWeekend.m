function tf = isWeekend(dn)
% Sunday = 1, Saturday = 7. Matches MATLAB and Octave weekday().
w = weekday(dn);
tf = (w == 1) || (w == 7);
end
