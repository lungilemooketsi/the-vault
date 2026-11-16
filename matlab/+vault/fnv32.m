function hex = fnv32(text)
hash = 2166136261;
prime = 16777619;
bytes = uint8(text);
for i = 1:numel(bytes)
  hash = double(bitxor(uint32(hash), uint32(bytes(i))));
  hash = mod(hash * prime, 4294967296);
end
hex = sprintf('%08x', hash);
end
