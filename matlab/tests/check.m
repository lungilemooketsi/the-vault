function check(cond, message)
if ~cond
  error('vault:test', '%s', message);
end
end
