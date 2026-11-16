function data = decodeApiJson(raw)
%decodeApiJson  Parse an Investec body, quoting 16+ digit integers first.
% Account ids are 25 digits. jsondecode would round them through double.
if ~ischar(raw)
  raw = char(raw);
end
quoted = regexprep(raw, '(^|[^0-9"])([0-9]{16,})([^0-9"]|$)', '$1"$2"$3');
data = jsondecode(quoted);
end
