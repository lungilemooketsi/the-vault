function run_all()
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
addpath(here);
tests = { ...
  'test_mask_and_json', ...
  'test_dates_and_client', ...
  'test_habits_and_budget', ...
  'test_motion'};
failed = 0;
for i = 1:numel(tests)
  name = tests{i};
  try
    feval(name);
    fprintf('PASS %s\n', name);
  catch err
    failed = failed + 1;
    fprintf('FAIL %s: %s\n', name, err.message);
  end
end
if failed > 0
  error('vault:tests', '%d test group(s) failed', failed);
end
fprintf('All MATLAB logic tests passed.\n');
end
