function payload = payloadOf(response)
if isfield(response, 'raw') && ~isempty(response.raw)
  payload = vault.decodeApiJson(response.raw);
elseif isfield(response, 'body') && ~isempty(response.body)
  payload = response.body;
else
  payload = struct();
end
end
