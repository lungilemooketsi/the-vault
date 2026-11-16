function data = readJson(path)
raw = fileread(path);
data = jsondecode(raw);
end
