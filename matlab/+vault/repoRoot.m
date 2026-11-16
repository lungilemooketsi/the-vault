function root = repoRoot()
%repoRoot  Repository root (parent of matlab/).
here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..', '..');
end
