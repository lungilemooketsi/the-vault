function out = base64Encode(text)
chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
bytes = uint8(text);
n = numel(bytes);
out = '';
i = 1;
while i <= n
  b1 = double(bytes(i));
  if i + 1 <= n
    b2 = double(bytes(i + 1));
  else
    b2 = 0;
  end
  if i + 2 <= n
    b3 = double(bytes(i + 2));
  else
    b3 = 0;
  end
  triple = b1 * 65536 + b2 * 256 + b3;
  idx = [floor(triple / 262144), mod(floor(triple / 4096), 64), mod(floor(triple / 64), 64), mod(triple, 64)] + 1;
  chunk = chars(idx);
  if i + 1 > n
    chunk(3:4) = '==';
  elseif i + 2 > n
    chunk(4) = '=';
  end
  out = [out chunk]; %#ok<AGROW>
  i = i + 3;
end
end
