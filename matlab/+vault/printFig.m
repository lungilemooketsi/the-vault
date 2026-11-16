function printFig(fig, outPath)
folder = fileparts(outPath);
if ~isempty(folder) && exist(folder, 'dir') ~= 7
  mkdir(folder);
end
print(fig, outPath, '-dpng');
close(fig);
end
