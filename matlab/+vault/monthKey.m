function key = monthKey(dn)
dv = datevec(dn);
key = sprintf('%04d-%02d', dv(1), dv(2));
end
