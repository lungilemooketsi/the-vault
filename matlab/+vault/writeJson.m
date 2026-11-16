function writeJson(path, data)
folder = fileparts(path);
if ~isempty(folder) && exist(folder, 'dir') ~= 7
  mkdir(folder);
end
raw = jsonencode(data);
fid = fopen(path, 'w');
if fid < 0
  error('vault:io', 'Could not write file.');
end
fwrite(fid, raw);
fclose(fid);
end
