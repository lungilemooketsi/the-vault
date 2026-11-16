function text = scrubSecrets(text)
if ~ischar(text)
  text = char(text);
end
text = regexprep(text, 'Bearer [A-Za-z0-9\-\._]+', 'Bearer ****');
text = regexprep(text, 'Basic [A-Za-z0-9\+/=]+', 'Basic ****');
text = regexprep(text, '[0-9]{8,}', '****');
end
