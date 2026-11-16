function dn2 = addMonths(dn, delta)
dv = datevec(dn);
year = dv(1);
month = dv(2) + delta;
while month < 1
  month = month + 12;
  year = year - 1;
end
while month > 12
  month = month - 12;
  year = year + 1;
end
dim = datenum(year, month + 1, 1) - datenum(year, month, 1);
day = min(dv(3), dim);
dn2 = datenum(year, month, day);
end
