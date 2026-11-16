function report = vault_demo(varargin)
%vault_demo  Entry point for the scripted floor.
%   vault_demo()                  sandbox if credentials exist, else the snapshot
%   vault_demo('mode','mock')     offline fixture, no network
%   vault_demo('backfill', false) learn from the real Aug-Nov months only
%   vault_demo('stress', true)    replay random card spend against the budget
here = fileparts(mfilename('fullpath'));
addpath(here);
report = vault.runDemo(varargin{:});
end
