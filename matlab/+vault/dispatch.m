function [client, response] = dispatch(client, request)
logged.method = request.method;
logged.url = request.url;
logged.bodyKind = request.bodyKind;
client.calls{end + 1} = logged;
response = client.transport(request, client);
end
