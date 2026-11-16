function report = vault_demo(varargin)
%vault_demo  Entry point. See matlab/vault_demo.m and the README.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'matlab'));
report = vault.runDemo(varargin{:});
end
